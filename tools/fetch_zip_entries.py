"""从远端 .tpz 里只取需要的条目，不下载整个包。

场景：只需要 Windows 导出模板，但 .tpz 有 1.2GB，而且网络不稳定。
ZIP 的中央目录在文件末尾，条目数据是各自独立的一段 ——
所以用 HTTP Range 就能只读目录 + 只取目标条目。

用法：
    python3 tools/fetch_zip_entries.py <url> <输出目录> <条目名>...

例：
    python3 tools/fetch_zip_entries.py "$URL" .downloads/win \
        templates/windows_release_x86_64.exe templates/windows_debug_x86_64.exe
"""

from __future__ import annotations

import io
import os
import sys
import urllib.request
import zipfile


class HttpRangeFile(io.RawIOBase):
    """把远端文件包装成只读、可 seek 的文件对象，供 zipfile 使用。

    只缓存已经读过的块，不做全量下载。
    """

    BLOCK = 1 << 16

    def __init__(self, url: str) -> None:
        super().__init__()
        self._url = url
        self._pos = 0
        self._cache: dict[int, bytes] = {}
        self._size: int | None = None

    # -------- 基本属性 --------

    def readable(self) -> bool:
        return True

    def seekable(self) -> bool:
        return True

    def tell(self) -> int:
        return self._pos

    def seek(self, offset: int, whence: int = os.SEEK_SET) -> int:
        if whence == os.SEEK_SET:
            self._pos = offset
        elif whence == os.SEEK_CUR:
            self._pos += offset
        elif whence == os.SEEK_END:
            self._pos = self._total_size() + offset
        return self._pos

    def _total_size(self) -> int:
        if self._size is None:
            request = urllib.request.Request(self._url, method="HEAD")
            with urllib.request.urlopen(request, timeout=60) as response:
                self._size = int(response.headers["Content-Length"])
        return self._size

    # -------- 读 --------

    def read(self, size: int = -1) -> bytes:
        if size < 0:
            size = self._total_size() - self._pos
        if size == 0:
            return b""

        chunks: list[bytes] = []
        remaining = size
        while remaining > 0:
            block_index = self._pos // self.BLOCK
            block_start = block_index * self.BLOCK
            block = self._load_block(block_index)
            offset = self._pos - block_start
            take = min(remaining, len(block) - offset)
            if take <= 0:
                break
            chunks.append(block[offset:offset + take])
            self._pos += take
            remaining -= take
        return b"".join(chunks)

    def _load_block(self, index: int) -> bytes:
        cached = self._cache.get(index)
        if cached is not None:
            return cached

        start = index * self.BLOCK
        end = start + self.BLOCK - 1
        request = urllib.request.Request(self._url)
        request.add_header("Range", f"bytes={start}-{end}")

        import time

        for attempt in range(8):
            try:
                with urllib.request.urlopen(request, timeout=60) as response:
                    data = response.read()
                self._cache[index] = data
                return data
            except Exception as error:  # noqa: BLE001
                print(f"  块 {index} 读取失败（{error}），重试…", file=sys.stderr)
                time.sleep(2 * (attempt + 1))

        raise RuntimeError(f"块 {index} 多次读取失败")


def main() -> None:
    if len(sys.argv) < 4:
        print(__doc__)
        sys.exit(1)

    url = sys.argv[1]
    out_dir = sys.argv[2]
    wanted = sys.argv[3:]

    os.makedirs(out_dir, exist_ok=True)
    remote = HttpRangeFile(url)
    archive = zipfile.ZipFile(remote)

    print(f"归档共 {len(archive.namelist())} 个条目，目标 {len(wanted)} 个")

    for name in wanted:
        try:
            info = archive.getinfo(name)
        except KeyError:
            print(f"  缺少条目：{name}", file=sys.stderr)
            continue

        target = os.path.join(out_dir, os.path.basename(name))
        print(f"  提取 {name}（{info.file_size / 1048576:.1f} MB）…", flush=True)
        with archive.open(info) as source, open(target, "wb") as sink:
            while True:
                block = source.read(1 << 20)
                if not block:
                    break
                sink.write(block)
        written = os.path.getsize(target)
        if written != info.file_size:
            print(f"    长度不符：期望 {info.file_size}，实际 {written}", file=sys.stderr)
            sys.exit(1)
        print(f"    OK：{target}")


if __name__ == "__main__":
    main()
