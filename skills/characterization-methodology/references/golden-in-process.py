# Characterization pattern: in-process call
# Covers: TensorFlow → JAX, or any Python → Python refactor/migration
#
# The test harness and the legacy code are both Python, so the legacy function
# is imported directly from its source file. No wrapper needed.
# Use allclose for numerical output rather than exact equality.

import json
import sys
import numpy as np
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parents[3] / "legacy" / "src"))
from compute import compute  # the actual legacy Python function

GOLDEN = Path(__file__).parent / "golden" / "compute_output.json"


def test_characterizes_compute_output():
    result = compute(x=1.0, n_steps=10)
    actual = {"output": float(result)}  # convert to JSON-serialisable type

    if not GOLDEN.exists():  # first run: save the reference
        GOLDEN.parent.mkdir(parents=True, exist_ok=True)
        GOLDEN.write_text(json.dumps(actual, indent=2))
        return

    expected = json.loads(GOLDEN.read_text())
    np.testing.assert_allclose(actual["output"], expected["output"], rtol=1e-6)
