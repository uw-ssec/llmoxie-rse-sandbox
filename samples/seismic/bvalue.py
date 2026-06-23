"""Estimate Gutenberg-Richter b-values for earthquake magnitude catalogs."""

from __future__ import annotations

from collections import Counter
import csv
import math
import random
from pathlib import Path
from typing import Iterable


def estimate_mc_max_curvature(magnitudes: Iterable[float], delta_m: float = 0.1) -> float:
    """Estimate completeness magnitude by the maximum-curvature method.

    The maximum-curvature estimate is the modal bin of the non-cumulative
    magnitude histogram. Ties are resolved toward the lower magnitude bin.
    """
    values = list(magnitudes)
    if not values:
        raise ValueError("magnitudes must be non-empty")
    if delta_m <= 0:
        raise ValueError("delta_m must be positive")

    rounded = [round(m / delta_m) * delta_m for m in values]
    counts = Counter(rounded)
    mc, _ = max(counts.items(), key=lambda item: (item[1], -item[0]))
    return round(mc, 1)


def estimate_b_value(magnitudes: Iterable[float], mc: float, delta_m: float = 0.1) -> float:
    """Estimate b-value with the binned Aki/Utsu maximum-likelihood formula."""
    if delta_m <= 0:
        raise ValueError("delta_m must be positive")

    selected = [m for m in magnitudes if m >= mc]
    if not selected:
        raise ValueError("no magnitudes at or above mc")

    mean_mag = sum(selected) / len(selected)
    denominator = mean_mag - (mc - delta_m / 2.0)
    if denominator <= 0:
        raise ValueError("invalid denominator for b-value estimate")

    return math.log10(math.e) / denominator


def estimate_catalog_b_value(
    path: str | Path,
    mc: float | None = None,
    delta_m: float = 0.1,
    bootstrap_samples: int = 1000,
    seed: int = 0,
) -> dict[str, float | int]:
    """Estimate catalog b-value, sample size, and a seeded bootstrap CI."""
    if bootstrap_samples <= 0:
        raise ValueError("bootstrap_samples must be positive")

    catalog_path = Path(path)
    with catalog_path.open("r", encoding="utf-8", newline="") as catalog_file:
        rows = list(csv.DictReader(catalog_file))

    if not rows or "magnitude" not in rows[0]:
        raise ValueError("catalog must contain a 'magnitude' column")

    magnitudes = [float(row["magnitude"]) for row in rows]
    selected_mc = estimate_mc_max_curvature(magnitudes, delta_m) if mc is None else float(mc)
    selected = [m for m in magnitudes if m >= selected_mc]
    if len(selected) < 2:
        raise ValueError("need at least 2 events at or above mc")

    b_hat = estimate_b_value(selected, mc=selected_mc, delta_m=delta_m)

    rng = random.Random(seed)
    bootstrapped = []
    for _ in range(int(bootstrap_samples)):
        sample = [selected[rng.randrange(len(selected))] for _ in range(len(selected))]
        bootstrapped.append(estimate_b_value(sample, mc=selected_mc, delta_m=delta_m))

    bootstrapped.sort()
    low_index = int(0.025 * len(bootstrapped))
    high_index = int(0.975 * len(bootstrapped))

    return {
        "mc": selected_mc,
        "n": len(selected),
        "b_value": b_hat,
        "ci_low": bootstrapped[low_index],
        "ci_high": bootstrapped[high_index],
    }
