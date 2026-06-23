import math
from pathlib import Path
import subprocess
import sys
import unittest

from samples.seismic.bvalue import (
    estimate_b_value,
    estimate_catalog_b_value,
    estimate_mc_max_curvature,
)


class TestBValueCore(unittest.TestCase):
    def test_mc_max_curvature_picks_modal_bin(self):
        mags = [2.0, 2.0, 2.1, 2.1, 2.1, 2.2, 3.0]

        self.assertEqual(estimate_mc_max_curvature(mags, delta_m=0.1), 2.1)

    def test_b_value_uses_binned_aki_utsu(self):
        mags = [2.1, 2.2, 2.3, 2.4]

        b_value = estimate_b_value(mags, mc=2.1, delta_m=0.1)

        expected = math.log10(math.e) / (((2.1 + 2.2 + 2.3 + 2.4) / 4) - (2.1 - 0.05))
        self.assertAlmostEqual(b_value, expected, places=12)

    def test_b_value_raises_if_no_events_above_mc(self):
        with self.assertRaises(ValueError):
            estimate_b_value([1.9, 1.8], mc=2.0, delta_m=0.1)


class TestBValueCatalog(unittest.TestCase):
    def test_catalog_estimation_returns_expected_fields(self):
        result = estimate_catalog_b_value(
            Path("samples/seismic/earthquake_catalog.csv"),
            mc=None,
            delta_m=0.1,
            bootstrap_samples=200,
            seed=7,
        )

        self.assertLessEqual({"mc", "n", "b_value", "ci_low", "ci_high"}, result.keys())
        self.assertGreater(result["n"], 0)
        self.assertLessEqual(result["ci_low"], result["b_value"])
        self.assertLessEqual(result["b_value"], result["ci_high"])

    def test_manual_mc_override_is_respected(self):
        auto = estimate_catalog_b_value(Path("samples/seismic/earthquake_catalog.csv"), mc=None, seed=7)
        manual = estimate_catalog_b_value(Path("samples/seismic/earthquake_catalog.csv"), mc=3.0, seed=7)

        self.assertEqual(manual["mc"], 3.0)
        self.assertLessEqual(manual["n"], auto["n"])


class TestBValueCli(unittest.TestCase):
    def test_cli_prints_required_metrics(self):
        proc = subprocess.run(
            [
                sys.executable,
                "samples/seismic/estimate_bvalue.py",
                "--catalog",
                "samples/seismic/earthquake_catalog.csv",
                "--seed",
                "7",
                "--bootstrap-samples",
                "200",
            ],
            check=True,
            capture_output=True,
            text=True,
        )
        output = proc.stdout

        self.assertIn("mc=", output)
        self.assertIn("n=", output)
        self.assertIn("b_value=", output)
        self.assertIn("ci95=", output)


if __name__ == "__main__":
    unittest.main()
