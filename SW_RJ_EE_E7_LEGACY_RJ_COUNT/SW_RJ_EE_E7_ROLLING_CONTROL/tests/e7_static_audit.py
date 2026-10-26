"""Source-level E7 contract audit; this is not MATLAB execution."""
from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def require(text: str, *markers: str) -> None:
    for marker in markers:
        assert marker in text, f"missing marker: {marker}"


def main() -> None:
    cfg = (ROOT / "rj_ee_options.m").read_text(encoding="utf-8")
    main_src = (ROOT / "Main_rjmcmc_EE.m").read_text(encoding="utf-8")
    update = (ROOT / "core" / "ee_adaptive_update.m").read_text(encoding="utf-8")
    configure = (ROOT / "core" / "ee_dim_configure.m").read_text(encoding="utf-8")
    append = (ROOT / "core" / "ee_adaptive_archive_append.m").read_text(encoding="utf-8")

    require(
        cfg,
        "cfg.ee_adapt_window=4000;",
        "cfg.ee_adapt_interval=2000;",
        "cfg.ee_archive_window=8000;",
        "cfg.ee_adaptation_policy=lower(char(ee_policy));",
        "cfg.ee_postreset_calibration='rolling_window';",
        "cfg.ee_archive_mode='rolling_fifo';",
    )
    require(
        update,
        "start=max(EE.calibration_start,s-EE.adapt_window+1);",
        "post_ready=EE.reset_iteration+EE.adapt_window;",
        "mod(s-post_ready,EE.adapt_interval)==0;",
        "EE=ee_adaptive_archive_reset(EE,s);",
        "EE=ee_adaptive_reindex(EE);",
        "phase='rolling_post_reset';",
    )
    require(
        configure,
        "EE.archive_slot_ring=zeros(T,EE.archive_window,'uint16');",
        "EE.storage_mode='recent_complete_state_fifo';",
        "'archive_window',{},'phase',{}",
    )
    require(
        append,
        "if count==cap",
        "EE.archive_dropped(t)=EE.archive_dropped(t)+uint64(1);",
        "EE.archive_next_slot(t)=mod(slot,cap)+1;",
    )
    require(
        main_src,
        "expected_active=min(clean_seen,EE.archive_window);",
        "expected_dropped=max(0,clean_seen-EE.archive_window);",
    )
    assert "start=EE.reset_iteration+1" not in update
    assert "EE.archive_window=max" not in configure

    result = {
        "kind": "source-level E7 audit; not MATLAB execution or convergence evidence",
        "energy_pilot": "most recent 4000 completed energies",
        "proposal_archive": "most recent 8000 complete states per chain, strict FIFO",
        "edge_interval": 2000,
        "policies": ["continuous through run", "frozen before posterior"],
        "reset": "one-time deletion of pre-reset proposal states; current edges retained",
        "local_kernel": "one mandatory RJ followed by optional supplemental EE",
    }
    out = ROOT / "docs" / "E7_STATIC_AUDIT.json"
    out.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
