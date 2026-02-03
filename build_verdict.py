#!/usr/bin/env python3
"""Backward-compat wrapper — real script moved to .deadf/bin/build-verdict.py"""
import os, sys
real = os.path.join(os.path.dirname(__file__), '.deadf', 'bin', 'build-verdict.py')
exec(open(real).read())
