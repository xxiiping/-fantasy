"""程序化合成 Demo 所需音效。

不下载任何素材，全部用正弦/噪声包络算出来，因此没有版权问题，
也保证任何人 clone 下来都能一键重建。

用法：
    python3 tools/make_audio.py
输出：
    assets/audio/click.wav      符文点击
    assets/audio/correct.wav    判定成功
    assets/audio/wrong.wav      判定失败
    assets/audio/ambience.wav   环境底噪（无缝循环）
"""

from __future__ import annotations

import os
import wave

import numpy as np

SAMPLE_RATE = 44100
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(ROOT, "assets", "audio")


def write_wav(name: str, data: np.ndarray) -> None:
    os.makedirs(OUT_DIR, exist_ok=True)
    clipped = np.clip(data, -1.0, 1.0)
    pcm = (clipped * 32767.0).astype("<i2")
    path = os.path.join(OUT_DIR, name)
    with wave.open(path, "wb") as handle:
        handle.setnchannels(1)
        handle.setsampwidth(2)
        handle.setframerate(SAMPLE_RATE)
        handle.writeframes(pcm.tobytes())
    print(f"{name:14s} {len(data) / SAMPLE_RATE:5.2f}s  {len(pcm.tobytes()) // 1024:5d} KB")


def make_click() -> np.ndarray:
    """短促的木质感点击：高频正弦 + 极短噪声瞬态。"""
    rng = np.random.default_rng(1)
    count = int(SAMPLE_RATE * 0.09)
    t = np.arange(count) / SAMPLE_RATE
    envelope = np.exp(-t / 0.012)
    tone = np.sin(2 * np.pi * 2400.0 * t) * 0.5 + np.sin(2 * np.pi * 3600.0 * t) * 0.2
    transient = rng.normal(0.0, 1.0, count) * np.exp(-t / 0.004) * 0.25
    return (tone * envelope + transient) * 0.35


def make_correct() -> np.ndarray:
    """上行三音（C5-E5-G5）+ 一层弱泛音，像机关认出了路。"""
    total = int(SAMPLE_RATE * 0.95)
    out = np.zeros(total)
    for index, freq in enumerate((523.25, 659.25, 783.99)):
        start = int(SAMPLE_RATE * 0.10 * index)
        t = np.arange(total - start) / SAMPLE_RATE
        attack = 1.0 - np.exp(-t / 0.010)
        envelope = np.exp(-t / 0.35) * attack
        tone = np.sin(2 * np.pi * freq * t) + 0.35 * np.sin(2 * np.pi * freq * 2.0 * t)
        out[start:] += tone * envelope * 0.28

    t_all = np.arange(total) / SAMPLE_RATE
    out += np.sin(2 * np.pi * 1567.98 * t_all) * np.exp(-t_all / 0.5) * 0.06
    return out


def make_wrong() -> np.ndarray:
    """下沉的低频闷响：音高下滑 + 低频噪声，失败但不刺耳。"""
    rng = np.random.default_rng(3)
    count = int(SAMPLE_RATE * 0.48)
    t = np.arange(count) / SAMPLE_RATE
    freq = 150.0 * np.exp(-t * 1.6) + 70.0
    phase = 2 * np.pi * np.cumsum(freq) / SAMPLE_RATE
    envelope = np.exp(-t / 0.16)
    body = (np.sin(phase) * 0.7 + np.sin(phase * 0.5) * 0.3) * envelope
    thud = rng.normal(0.0, 1.0, count) * np.exp(-t / 0.03) * 0.12
    return (body + thud) * 0.38


def make_ambience() -> np.ndarray:
    """8 秒无缝循环的海面底噪。

    所有分音频率都吸附到 1/duration 的整数倍上，保证首尾相接时相位连续，
    循环点不会出现"咔"的一声。
    """
    rng = np.random.default_rng(7)
    duration = 8.0
    count = int(SAMPLE_RATE * duration)
    t = np.arange(count) / SAMPLE_RATE
    grid = 1.0 / duration

    def snapped(freq: float) -> float:
        return max(grid, round(freq / grid) * grid)

    out = np.zeros(count)
    for freq, amp in ((55.0, 0.50), (82.5, 0.28), (110.0, 0.20), (164.81, 0.10)):
        out += np.sin(2 * np.pi * snapped(freq) * t) * amp

    # 缓慢起伏，同样用整数倍频率
    out *= 0.62 + 0.38 * np.sin(2 * np.pi * snapped(0.125) * t)

    # 一阶低通滤过的噪声当作浪声
    noise = rng.normal(0.0, 1.0, count)
    alpha = 0.0025
    low = np.zeros(count)
    acc = 0.0
    for i in range(count):
        acc += alpha * (noise[i] - acc)
        low[i] = acc
    out += low * 9.0

    return out * 0.10


def main() -> None:
    write_wav("click.wav", make_click())
    write_wav("correct.wav", make_correct())
    write_wav("wrong.wav", make_wrong())
    write_wav("ambience.wav", make_ambience())


if __name__ == "__main__":
    main()
