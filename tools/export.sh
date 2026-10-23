#!/usr/bin/env bash
#
# 一键导出 macOS 可执行包。
#
# 关键点：导出包里不包含 addons/，所以必须先把 _mcp_game_helper 这个
# autoload 从 project.godot 摘掉，否则导出的游戏一启动就报
# "autoload 脚本不存在"。脚本用 trap 保证无论成功失败都会还原。
#
# 用法：  tools/export.sh [输出路径]
# 前置：  Godot export templates 已安装到
#         ~/Library/Application Support/Godot/export_templates/4.7.1.stable/

set -uo pipefail

GODOT="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT="${1:-$PROJECT_ROOT/build/macos/ZhengHeFantasy.zip}"

cd "$PROJECT_ROOT" || exit 1

if [[ ! -x "$GODOT" ]]; then
	echo "找不到 Godot 可执行文件：$GODOT" >&2
	echo "可以用环境变量 GODOT_BIN 指定。" >&2
	exit 1
fi

BACKUP="$(mktemp)"
restore() {
	cp "$BACKUP" "$PROJECT_ROOT/project.godot"
	rm -f "$BACKUP"
}
trap restore EXIT INT TERM

cp project.godot "$BACKUP"

# 摘掉 MCP 的 autoload（它指向被排除的 addons/）
grep -v '^_mcp_game_helper=' "$BACKUP" > project.godot
if grep -q '^_mcp_game_helper=' project.godot; then
	echo "警告：autoload 未成功移除，导出包可能启动失败" >&2
fi

mkdir -p "$(dirname "$OUTPUT")"

echo "== 开始导出 =="
echo "   引擎：$GODOT"
echo "   输出：$OUTPUT"
echo

"$GODOT" --headless --path "$PROJECT_ROOT" \
	--export-release "macOS" "$OUTPUT" 2>&1 |
	grep -v "editor_settings" |
	tail -25

EXPORT_STATUS=${PIPESTATUS[0]}

echo
if [[ -f "$OUTPUT" ]]; then
	echo "== 导出成功 =="
	ls -lh "$OUTPUT"
	# autoload 已由 trap 还原
	exit 0
else
	echo "== 导出失败（退出码 ${EXPORT_STATUS}）==" >&2
	exit 1
fi
