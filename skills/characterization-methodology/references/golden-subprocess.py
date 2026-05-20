# Characterization pattern: compiled binary via subprocess
# Covers: Fortran → Python/JAX, C → Python migrations
#
# Run the legacy binary with controlled input and compare its output
# to a saved golden file. First run saves the reference; later runs assert no change.

import json
import subprocess
from pathlib import Path

GOLDEN = Path(__file__).parent / "golden" / "compute_output.json"


def run_legacy(x: float) -> dict:
    proc = subprocess.run(
        ["./build/legacy_compute", str(x)],
        capture_output=True,
        text=True,
    )
    return {"stdout": proc.stdout.strip(), "returncode": proc.returncode}


def test_characterizes_compute_at_nominal_input():
    actual = run_legacy(x=1.0)

    if not GOLDEN.exists():  # first run: save the reference
        GOLDEN.parent.mkdir(parents=True, exist_ok=True)
        GOLDEN.write_text(json.dumps(actual, indent=2))
        return

    expected = json.loads(GOLDEN.read_text())
    assert actual == expected
