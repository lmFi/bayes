"""Source-level E6 contract audit; this is not MATLAB execution."""
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
        "cfg.ee_reset_iteration=18000;",
        "cfg.ee_postreset_refill=2000;",
        "cfg.ee_postreset_update_interval=5000;",
        "cfg.ee_update_until_end=true;",
        "cfg.ee_postreset_calibration='all_history';",
        "cfg.ee_archive_mode='growing_postreset';",
    )
    require(
        update,
        "start=EE.reset_iteration+1;",
        "reset_now=(s==EE.reset_iteration && EE.reset_archive_once);",
        "EE=ee_adaptive_archive_reset(EE,s);",
        "EE=ee_adaptive_reindex(EE);",
        "phase='growing_post_reset';",
    )
    require(
        configure,
        "EE.archive_window=max(EE.adapt_window,nsample-EE.reset_iteration);",
        "EE.storage_mode='growing_complete_history_after_one_reset';",
        "'archive_window',{},'phase',{}",
    )
    require(
        append,
        "error('EE:PostresetEviction'",
    )
    require(
        main_src,
        "expected_clean=nsample-EE.reset_iteration;",
        "any(EE.archive_count~=expected_clean)",
        "any(EE.archive_dropped~=0)",
    )
    assert "adapt_freeze" not in update

    result = {
        "kind": "source-level E6 audit; not MATLAB execution or convergence evidence",
        "pre_reset_pilot": "rolling window",
        "reset": "one-time candidate deletion; current edges retained",
        "post_reset_archive": "all completed states, no eviction",
        "post_reset_pilot": "all energies from reset+1 through current sweep",
        "edge_updates": "continue through final sweep",
        "local_kernel": "one mandatory RJ followed by optional supplemental EE",
    }
    out = ROOT / "docs" / "E6_STATIC_AUDIT.json"
    out.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
