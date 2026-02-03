#!/usr/bin/env python3
"""extract_plan.py — Backward-compat wrapper for parse-blocks.py plan.

Reads raw LLM output from stdin and delegates parsing to
`.deadf/bin/parse-blocks.py plan`.
"""
from __future__ import annotations

import argparse
import os
import subprocess
import sys


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Extract sentinel-delimited plan from LLM output"
    )
    parser.add_argument(
        "--nonce", required=True,
        help="Expected 6-char uppercase hex nonce (e.g. 4F2C9A)"
    )
    args = parser.parse_args()

    script_path = os.path.join(
        os.path.dirname(__file__), ".deadf", "bin", "parse-blocks.py"
    )
    cmd = [sys.executable, script_path, "plan", "--nonce", args.nonce]

    raw_text = sys.stdin.read()
    proc = subprocess.run(
        cmd,
        input=raw_text,
        text=True,
        capture_output=True,
    )

    if proc.stdout:
        sys.stdout.write(proc.stdout)
    if proc.stderr:
        sys.stderr.write(proc.stderr)
    sys.exit(proc.returncode)


if __name__ == "__main__":
    main()
