"""Repeatable source-level checks for the preserved E5/E6 kernel order."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> None:
    expected = json.loads((ROOT / "UNCHANGED_CORE_SHA256.json").read_text())
    hashes = {}
    for name, wanted in expected.items():
        actual = sha256(ROOT / "core" / name)
        assert actual == wanted, f"unchanged core mismatch: {name}"
        hashes[name] = actual

    driver = (ROOT / "Main_rjmcmc_EE.m").read_text(encoding="utf-8")
    markers = [
        "EE.energy_before_local(s,:) = like(:).';",
        "RJ_C_mian(",
        "EE.energy_after_local(s,:) = like(:).';",
        "= ee_jump(",
        "EE.energy_after_ee(s,:) = like(:).';",
        "EE = ee_ring_update(",
    ]
    positions = [driver.index(marker) for marker in markers]
    assert positions == sorted(positions), "E5/E6 kernel/archive order changed"
    assert "if use_local_rj" not in driver
    assert "any(EE.local_updates ~= nsample)" in driver

    jump = (ROOT / "core" / "ee_jump.m").read_text(encoding="utf-8")
    assert "ee_selected" in jump
    assert "use_local_rj" not in jump
    init = (ROOT / "core" / "ee_initialize.m").read_text(encoding="utf-8")
    assert "local_rj_then_optional_ee" in init

    result = {
        "kind": "source-level audit; not MATLAB execution or convergence evidence",
        "unchanged_core_sha256": hashes,
        "driver_order": markers,
        "update_mode": "local_rj_then_optional_ee",
    }
    out = ROOT / "docs" / "E5_STATIC_AUDIT.json"
    out.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
