#!/bin/bash
set -euo pipefail

# --- Runner の登録 ---
if [ ! -f /home/runner/.credentials ]; then
  echo "Runner を登録します..."
  ./config.sh \
    --url "https://github.com/${GITHUB_REPO}" \
    --token "${RUNNER_TOKEN}" \
    --name "${RUNNER_NAME:-claude-runner}" \
    --labels "${RUNNER_LABELS:-self-hosted}" \
    --unattended \
    --replace
fi

# --- クリーンアップ用のトラップ ---
cleanup() {
  echo "Runner を登録解除します..."
  ./config.sh remove --token "${RUNNER_TOKEN}" || true
}
trap cleanup EXIT

# --- Runner を起動 ---
echo "Runner を起動します..."
exec ./run.sh
