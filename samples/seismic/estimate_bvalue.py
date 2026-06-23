"""Command-line interface for Gutenberg-Richter b-value estimation."""

from __future__ import annotations

import argparse
from pathlib import Path
import sys

if __package__ is None or __package__ == "":
    sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from samples.seismic.bvalue import estimate_catalog_b_value


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Estimate Gutenberg-Richter b-value for an earthquake catalog."
    )
    parser.add_argument("--catalog", type=Path, required=True)
    parser.add_argument("--mc", type=float, default=None)
    parser.add_argument("--delta-m", type=float, default=0.1)
    parser.add_argument("--bootstrap-samples", type=int, default=1000)
    parser.add_argument("--seed", type=int, default=0)
    args = parser.parse_args()

    result = estimate_catalog_b_value(
        args.catalog,
        mc=args.mc,
        delta_m=args.delta_m,
        bootstrap_samples=args.bootstrap_samples,
        seed=args.seed,
    )
    print(
        f"mc={result['mc']:.1f} n={result['n']} "
        f"b_value={result['b_value']:.4f} "
        f"ci95=({result['ci_low']:.4f}, {result['ci_high']:.4f})"
    )


if __name__ == "__main__":
    main()
