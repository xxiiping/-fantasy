#!/usr/bin/env bash
#
# 反复调用分段下载脚本，直到拼出完整文件。
#
# 为什么要这个：GitHub 对**新建连接**限流，8 路里常有 5 路被直接拒掉。
# 每次重跑只会补上没完成的段（已完成段按大小跳过），所以多跑几轮就能凑齐。

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1

for attempt in $(seq 1 40); do
	if [[ -f .downloads/templates.tpz ]]; then
		echo "完成（第 ${attempt} 轮）"
		exit 0
	fi
	echo "[$(date +%H:%M:%S)] 第 ${attempt} 轮"
	./tools/fetch_templates_parallel.sh 8
	status=$?
	if (( status == 0 )); then
		echo "完成（第 ${attempt} 轮）"
		exit 0
	fi
	echo "  本轮有段未完成，8 秒后重试…"
	sleep 8
done

echo "多轮重试仍未完成，请检查网络。" >&2
exit 1
