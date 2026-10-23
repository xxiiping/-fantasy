"""可续传的大文件下载器。

为什么不用 `curl -C -`：当 GitHub 的签名重定向偶尔丢掉 Range 头、返回 200 而不是 206 时，
curl 会**静默截断文件并从头写**。1.2GB 下到一半被重置过，代价太大。

这里显式处理：
  - 发 Range 请求
  - 只有拿到 206 才追加写
  - 拿到 200（服务端不支持续传）就明确报错退出，而不是悄悄重来
  - 断线按指数退避重试，每次重试前重新探测文件大小

用法：
    python3 tools/fetch_templates.py <url> <输出路径> [--proxy http://127.0.0.1:7897]
"""

from __future__ import annotations

import argparse
import os
import sys
import time
import urllib.error
import urllib.request

CHUNK = 1 << 20


def remote_size(url: str, proxies: dict[str, str] | None) -> int:
    request = urllib.request.Request(url, method="HEAD")
    opener = urllib.request.build_opener(
        urllib.request.ProxyHandler(proxies) if proxies else urllib.request.ProxyHandler({})
    )
    with opener.open(request, timeout=30) as response:
        return int(response.headers.get("Content-Length", "0"))


def build_opener(proxies: dict[str, str] | None):
    handler = urllib.request.ProxyHandler(proxies or {})
    return urllib.request.build_opener(handler)


def download(url: str, target: str, proxies: dict[str, str] | None, total_hint: int) -> None:
    attempt = 0
    while True:
        have = os.path.getsize(target) if os.path.exists(target) else 0

        if total_hint and have >= total_hint:
            print(f"已完成：{have} 字节")
            return

        request = urllib.request.Request(url)
        if have:
            request.add_header("Range", f"bytes={have}-")

        opener = build_opener(proxies)
        try:
            started = time.time()
            with opener.open(request, timeout=60) as response:
                status = response.status
                if have and status != 206:
                    print(
                        f"服务端未按续传响应（HTTP {status}，期望 206）。"
                        f"为避免静默重下，停止。已保留 {have} 字节的本地文件。",
                        file=sys.stderr,
                    )
                    sys.exit(2)

                total = total_hint
                if status == 206:
                    content_range = response.headers.get("Content-Range", "")
                    if "/" in content_range:
                        total = int(content_range.rsplit("/", 1)[1])
                elif not total:
                    total = int(response.headers.get("Content-Length", "0"))

                mode = "ab" if have else "wb"
                written = have
                last_report = started
                with open(target, mode) as handle:
                    while True:
                        block = response.read(CHUNK)
                        if not block:
                            break
                        handle.write(block)
                        written += len(block)
                        now = time.time()
                        if now - last_report >= 5.0:
                            elapsed = now - started
                            speed = (written - have) / elapsed if elapsed > 0 else 0.0
                            percent = (written / total * 100.0) if total else 0.0
                            print(
                                f"{written / 1048576:7.1f} MB / {total / 1048576:7.1f} MB "
                                f"({percent:5.1f}%)  {speed / 1024:6.0f} KB/s",
                                flush=True,
                            )
                            last_report = now

        except (urllib.error.URLError, TimeoutError, ConnectionError, OSError) as error:
            attempt += 1
            backoff = min(60, 5 * attempt)
            print(f"连接中断：{error}。{backoff} 秒后第 {attempt} 次重试…", flush=True)
            time.sleep(backoff)
            if attempt > 40:
                print("重试次数过多，放弃。", file=sys.stderr)
                sys.exit(1)
            continue

        have_now = os.path.getsize(target) if os.path.exists(target) else 0
        if total_hint and have_now >= total_hint:
            print(f"完成：{have_now / 1048576:.1f} MB")
            return
        if total_hint == 0:
            print(f"完成（未知总长）：{have_now / 1048576:.1f} MB")
            return


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("url")
    parser.add_argument("target")
    parser.add_argument("--proxy", default="")
    args = parser.parse_args()

    proxies = {"http": args.proxy, "https": args.proxy} if args.proxy else None

    total = 0
    try:
        total = remote_size(args.url, proxies)
        print(f"远端大小：{total / 1048576:.1f} MB")
    except Exception as error:  # noqa: BLE001
        print(f"HEAD 探测失败（{error}），将继续但不校验总长。")

    download(args.url, args.target, proxies, total)


if __name__ == "__main__":
    main()
