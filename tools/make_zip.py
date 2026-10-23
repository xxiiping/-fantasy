"""打包提交目录，修正中文文件名的编码标志。

背景：macOS 自带的 `zip` 不设置 ZIP 的 UTF-8 标志位（bit 11）。
中文文件名虽然按 UTF-8 存储，但缺少标记，Windows 上解压会变成乱码目录名。
Python 的 zipfile 在遇到非 ASCII 文件名时会自动置位，所以用它来打。

同时保留 Unix 权限位（macOS 的 .app 内部可执行文件需要执行权限）。

用法：
    python3 tools/make_zip.py <源目录> <输出.zip>
"""

from __future__ import annotations

import os
import shutil
import sys
import zipfile
from pathlib import Path

SKIP_NAMES = {".DS_Store"}


def main() -> None:
    if len(sys.argv) != 3:
        print(__doc__)
        sys.exit(1)

    source = Path(sys.argv[1]).resolve()
    target = Path(sys.argv[2]).resolve()

    if not source.is_dir():
        print(f"源目录不存在：{source}", file=sys.stderr)
        sys.exit(1)

    if target.exists():
        target.unlink()

    entries = 0
    with zipfile.ZipFile(target, "w", zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
        for current, dirs, files in os.walk(source):
            dirs[:] = sorted(d for d in dirs if d not in SKIP_NAMES)
            files = sorted(f for f in files if f not in SKIP_NAMES)
            current_path = Path(current)

            for directory in dirs:
                full = current_path / directory
                arcname = full.relative_to(source.parent).as_posix() + "/"
                info = zipfile.ZipInfo.from_file(full, arcname, strict_timestamps=False)
                info.compress_type = zipfile.ZIP_STORED
                archive.writestr(info, b"")
                entries += 1

            for filename in files:
                full = current_path / filename
                arcname = full.relative_to(source.parent).as_posix()
                info = zipfile.ZipInfo.from_file(full, arcname, strict_timestamps=False)
                info.compress_type = zipfile.ZIP_DEFLATED
                with archive.open(info, "w") as dest, open(full, "rb") as src:
                    shutil.copyfileobj(src, dest, 1 << 20)
                entries += 1

    print(f"写入 {entries} 个条目 → {target}")
    print(f"体积：{target.stat().st_size / 1048576:.1f} MB")

    # 自检：确认 UTF-8 标志位已设，且中文名能正确读回
    with zipfile.ZipFile(target) as check:
        infos = check.infolist()
        flagged = sum(1 for i in infos if i.flag_bits & 0x800)
        print(f"UTF-8 标志：{flagged} / {len(infos)}")
        chinese = [i.filename for i in infos if any(ord(c) > 127 for c in i.filename)]
        print(f"含非 ASCII 的条目：{len(chinese)}")
        for name in chinese[:3]:
            print(f"  {name}")

        executable = [
            i.filename
            for i in infos
            if (i.external_attr >> 16) & 0o111 and not i.filename.endswith("/")
        ]
        print(f"带执行权限的文件：{len(executable)}")
        for name in executable[:3]:
            print(f"  {name}")

        if flagged != len(infos):
            print("警告：仍有条目未置 UTF-8 标志", file=sys.stderr)
            sys.exit(1)


if __name__ == "__main__":
    main()
