#!/usr/bin/env bash
set -euo pipefail
CAIRN_REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$CAIRN_REPO_ROOT"
if [[ ! -x .venv/bin/python ]]; then
    cairn_python=""
    for candidate in python3.13 python3.12 python3.11 python3.10 python3; do
        if command -v "$candidate" >/dev/null 2>&1 && "$candidate" -c 'import sys, venv; raise SystemExit(sys.version_info < (3, 10))'; then
            cairn_python="$candidate"
            break
        fi
    done
    if [[ -z "$cairn_python" ]]; then
        echo 'Нужен Python >= 3.10 с модулем venv.' >&2
        exit 1
    fi
    "$cairn_python" -m venv .venv
fi
.venv/bin/python -m pip install --upgrade pip
.venv/bin/python -m pip install -e . pytest
export CAIRN_DATA_DIR="$CAIRN_REPO_ROOT/data"
.venv/bin/cairn-cards all
printf '\nГотово. Проверки: ./scripts/test.sh. Запуск: ./scripts/dev-run.sh\n'
