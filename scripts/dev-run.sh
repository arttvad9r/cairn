#!/usr/bin/env bash
set -euo pipefail
CAIRN_REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$CAIRN_REPO_ROOT"
if [[ ! -x .venv/bin/python ]]; then
    echo 'Сначала выполните ./scripts/dev-setup.sh' >&2
    exit 1
fi
export XDG_CONFIG_HOME="$CAIRN_REPO_ROOT/.dev/config"
export XDG_DATA_HOME="$CAIRN_REPO_ROOT/.dev/data"
export XDG_CACHE_HOME="$CAIRN_REPO_ROOT/.dev/cache"
export CAIRN_DATA_DIR="$CAIRN_REPO_ROOT/data"
mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_CACHE_HOME"
.venv/bin/python - <<'PY'
import json
import os
from pathlib import Path
path = Path(os.environ['XDG_CONFIG_HOME']) / 'cairn/config.json'
if not path.exists():
    path.parent.mkdir(parents=True, exist_ok=True)
    config = {
        'language': 'ru', 'share_games': 'no', 'archive_sessions': False,
        'hs_prefix': os.environ.get('CAIRN_DEV_HS_PREFIX', ''),
    }
    path.write_text(json.dumps(config, ensure_ascii=False, indent=2) + '\n')
PY
exec .venv/bin/cairn "$@"
