#!/usr/bin/env bash
set -euo pipefail
CAIRN_REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$CAIRN_REPO_ROOT"
if [[ ! -x .venv/bin/python ]]; then
    echo 'Сначала выполните ./scripts/dev-setup.sh' >&2
    exit 1
fi
for locale in frFR enUS zhCN ruRU; do
    if [[ ! -f "data/cards/cards.$locale.json" || ! -f "data/cards/cards.text.$locale.json" ]]; then
        echo "Нет базы $locale. Выполните ./scripts/dev-setup.sh" >&2
        exit 1
    fi
done
mkdir -p .dev/test-results
cairn_test_tmp="$(mktemp -d "$CAIRN_REPO_ROOT/.dev/test-XXXXXX")"
trap 'rm -rf -- "$cairn_test_tmp"' EXIT
export XDG_CONFIG_HOME="$cairn_test_tmp/config"
export XDG_DATA_HOME="$cairn_test_tmp/data"
export XDG_CACHE_HOME="$cairn_test_tmp/cache"
export CAIRN_DATA_DIR="$CAIRN_REPO_ROOT/data"
export QT_QPA_PLATFORM=offscreen
mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_CACHE_HOME"
.venv/bin/python -m pytest -q -rs --junitxml=.dev/test-results/pytest.xml "$@"
.venv/bin/python tools/ci_check_skips.py .dev/test-results/pytest.xml --max-skips 10
