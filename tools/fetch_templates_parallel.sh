#!/usr/bin/env bash
#
# 分段并行下载 export templates。
#
# 背景：单连接持续速度被压到 ~130 KB/s，而 4 路并行实测 370 KB/s ——
# 限制是按连接算的。所以把文件切成 N 段，每段一个 curl，最后按序拼接。
#
# 每段独立可续传（段文件固定范围，`-C -` 只追加不会串位），
# 因此某一段断了不会影响其它段，也不会像整文件续传那样被截断。
#
# 用法： tools/fetch_templates_parallel.sh [段数]

set -uo pipefail

URL="https://github.com/godotengine/godot/releases/download/4.7.1-stable/Godot_v4.7.1-stable_export_templates.tpz"
SIZE=1280486955
PARTS="${1:-8}"
WORKDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/.downloads"
OUTPUT="$WORKDIR/templates.tpz"
PARTDIR="$WORKDIR/parts"

mkdir -p "$PARTDIR"

CHUNK=$(( (SIZE + PARTS - 1) / PARTS ))

echo "总大小 ${SIZE} 字节，切 ${PARTS} 段，每段约 $((CHUNK / 1048576)) MB"

fetch_part() {
	local index="$1"
	local start=$(( index * CHUNK ))
	local end=$(( start + CHUNK - 1 ))
	if (( end >= SIZE )); then
		end=$(( SIZE - 1 ))
	fi
	local expect=$(( end - start + 1 ))
	local file="$PARTDIR/part_$(printf '%02d' "$index")"

	local have=0
	if [[ -f "$file" ]]; then
		have=$(stat -f %z "$file")
	fi

	if (( have == expect )); then
		echo "  段 $index 已完成（跳过）"
		return 0
	fi

	# 段文件已就绪但长度不对，说明之前的写入不完整，直接重来这一段
	if (( have > expect )); then
		rm -f "$file"
		have=0
	fi

	curl -sL --fail -C - --retry 12 --retry-delay 4 --retry-all-errors \
		-r "$(( start + have ))-${end}" \
		-o "$file" "$URL" || return 1

	local got
	got=$(stat -f %z "$file" 2>/dev/null || echo 0)
	if (( got != expect )); then
		echo "  段 $index 长度不符：期望 $expect，实际 $got" >&2
		return 1
	fi
	echo "  段 $index 完成（$((expect / 1048576)) MB）"
}

pids=()
for (( i = 0; i < PARTS; i++ )); do
	fetch_part "$i" &
	pids+=($!)
	# 错峰建连：同时发起 N 个连接容易被对端限流直接拒绝
	sleep 1.5
done

fail=0
for pid in "${pids[@]}"; do
	wait "$pid" || fail=1
done

if (( fail != 0 )); then
	echo "有分段失败，保留已完成的段，重跑本脚本即可续传。" >&2
	exit 1
fi

echo "全部段完成，开始拼接…"
: > "$OUTPUT"
for (( i = 0; i < PARTS; i++ )); do
	cat "$PARTDIR/part_$(printf '%02d' "$i")" >> "$OUTPUT"
done

final=$(stat -f %z "$OUTPUT")
echo "拼接完成：$final 字节"
if (( final != SIZE )); then
	echo "长度不符，期望 $SIZE" >&2
	exit 1
fi

rm -rf "$PARTDIR"
echo "OK：$OUTPUT"
