#!/usr/bin/env python3
"""Generate SPIN//ASCEND's original score and sound effects, with Python stdlib.

No downloaded samples, dependencies or runtime synthesizer. Each score has a
16-bar arrangement, stereo space, and sample-exact looping. Generation is
deterministic. Run from any directory: python3 tools/generate_audio.py
"""
from array import array
import math
from pathlib import Path
import random
import struct
import wave

RATE = 32000
TAU = math.tau
OUT = Path(__file__).resolve().parents[1] / "assets" / "audio"


def hz(note):
    return 440.0 * 2 ** ((note - 69) / 12)


class Mix:
    def __init__(self, seconds, seed=19, loop=False):
        self.n = int(round(seconds * RATE))
        self.left = array("f", [0.0]) * self.n
        self.right = array("f", [0.0]) * self.n
        self.random = random.Random(seed)
        self.loop = loop

    def add(self, start, samples, amp=1.0, pan=0.0, echo=0.0):
        offset = round(start * RATE)
        l = math.sqrt((1 - pan) * 0.5) * amp
        r = math.sqrt((1 + pan) * 0.5) * amp
        for i, v in enumerate(samples):
            index = offset + i
            if self.loop:
                index %= self.n
            elif not 0 <= index < self.n:
                continue
            self.left[index] += v * l
            self.right[index] += v * r
        if echo:
            # Two quiet cross-channel taps; wraps preserve the loop boundary.
            for delay, gain in ((0.176, 0.20), (0.353, 0.10)):
                d = round((start + delay) * RATE)
                for i, v in enumerate(samples):
                    index = d + i
                    if self.loop:
                        index %= self.n
                    elif not 0 <= index < self.n:
                        continue
                    self.left[index] += v * r * gain * echo
                    self.right[index] += v * l * gain * echo

    def note(self, start, note, duration, amp, voice="pluck", pan=0.0):
        count = round(duration * RATE)
        f = hz(note)
        data = array("f")
        for i in range(count):
            t = i / RATE
            p = TAU * f * t
            if voice == "pad":
                attack = min(1.0, t / 0.40)
                release = min(1.0, (duration - t) / 0.65)
                env = attack * release
                v = (math.sin(p) * 0.62 + math.sin(p * 1.0023) * 0.25
                     + math.sin(p * 2) * 0.09 + math.sin(p * 3) * 0.04)
            elif voice == "bass":
                env = min(1.0, t / 0.006) * math.exp(-t * 3.3) * min(1.0, (duration - t) / 0.025)
                v = math.sin(p) * 0.70 + math.sin(2 * p) * 0.20 + math.sin(3 * p) * 0.10
            elif voice == "lead":
                env = min(1.0, t / 0.008) * math.exp(-t * 2.6) * min(1.0, (duration - t) / 0.075)
                v = math.sin(p + math.sin(TAU * 5.2 * t) * 0.02) * 0.72 + math.sin(2 * p) * 0.19 + math.sin(3 * p) * 0.09
            elif voice == "bell":
                env = min(1.0, t / 0.003) * math.exp(-t * 4.5) * min(1.0, (duration - t) / 0.04)
                v = math.sin(p) * 0.70 + math.sin(p * 2.008) * 0.20 + math.sin(p * 3.97) * 0.10
            else:
                env = min(1.0, t / 0.002) * math.exp(-t * 7.0) * min(1.0, (duration - t) / 0.025)
                v = math.sin(p) * 0.80 + math.sin(2 * p) * 0.14 + math.sin(3 * p) * 0.06
            data.append(v * env)
        self.add(start, data, amp, pan, echo=0.75 if voice in ("lead", "bell", "pluck") else 0.0)

    def kick(self, start, amp=0.3):
        data = array("f")
        phase = 0.0
        for i in range(round(0.32 * RATE)):
            t = i / RATE
            phase += TAU * (44 + 140 * math.exp(-t * 42)) / RATE
            attack = min(1.0, t / 0.002)
            v = math.sin(phase) * math.exp(-t * 15)
            v += self.random.uniform(-1, 1) * math.exp(-t * 250) * 0.09
            data.append(v * attack)
        self.add(start, data, amp)

    def snare(self, start, amp=0.18, pan=0.1):
        data = array("f")
        low = 0.0
        for i in range(round(0.22 * RATE)):
            t = i / RATE
            noise = self.random.uniform(-1, 1)
            low += 0.17 * (noise - low)
            v = (noise - low) * 0.56 + math.sin(TAU * 176 * t) * 0.35
            data.append(v * math.exp(-t * 24) * min(1, t / 0.0015))
        self.add(start, data, amp, pan, echo=0.25)

    def hat(self, start, amp=0.08, open_hat=False, pan=0.45):
        duration = 0.18 if open_hat else 0.055
        data = array("f")
        low = 0.0
        for i in range(round(duration * RATE)):
            t = i / RATE
            noise = self.random.uniform(-1, 1)
            low += 0.3 * (noise - low)
            data.append((noise - low) * math.exp(-t * (28 if open_hat else 90)) * min(1, t / 0.001))
        self.add(start, data, amp, pan)

    def write(self, name, peak=0.81):
        # Normalize conservatively. A gentle saturation rounds percussion peaks.
        maximum = max(max(map(abs, self.left)), max(map(abs, self.right)), 0.001)
        scale = 1.1 / maximum
        frames = bytearray(self.n * 4)
        for i in range(self.n):
            # Effect tails can end during a quiet delay. Fade the last 8 ms
            # rather than truncating them into a speaker click.
            edge = 1.0 if self.loop else min(1.0, i / (RATE * 0.003), (self.n - 1 - i) / (RATE * 0.008))
            left = math.tanh(self.left[i] * scale) * peak * edge
            right = math.tanh(self.right[i] * scale) * peak * edge
            struct.pack_into("<hh", frames, i * 4, round(left * 32767), round(right * 32767))
        OUT.mkdir(parents=True, exist_ok=True)
        with wave.open(str(OUT / f"{name}.wav"), "wb") as wav:
            wav.setnchannels(2)
            wav.setsampwidth(2)
            wav.setframerate(RATE)
            wav.writeframes(frames)
        print(f"{name}: {self.n / RATE:.2f}s, stereo {RATE}Hz")


CHORDS = [(50, 53, 57, 60), (46, 50, 53, 57), (41, 45, 48, 55), (48, 52, 55, 62),
          (43, 46, 50, 57), (46, 50, 53, 60), (45, 49, 52, 55), (50, 53, 57, 64)]


def score_menu():
    beat = 60 / 100
    mix = Mix(64 * beat, loop=True)
    for bar in range(16):
        start = bar * 4 * beat
        chord = CHORDS[bar // 2]
        for j, note in enumerate(chord):
            mix.note(start, note + 12, 4 * beat + 0.7, 0.050, "pad", (j - 1.5) * 0.32)
        for k in range(8):
            note = chord[(k + bar % 2) % 4] + (24 if k in (3, 7) else 12)
            mix.note(start + k * beat * 0.5, note, beat * 0.9, 0.043 if k % 2 else 0.055, pan=math.sin(k * 0.8) * 0.45)
        for k in (0, 2):
            mix.note(start + k * beat, chord[0] - 12, beat * 1.7, 0.15, "bass")
            mix.kick(start + k * beat, 0.13)
        for k in (1, 3):
            mix.snare(start + k * beat, 0.038)
        for k in range(8):
            mix.hat(start + k * beat / 2, 0.026 if k % 2 else 0.038, pan=-0.28 + k * 0.07)
        if bar in (3, 7, 11, 15):
            phrase = [chord[2] + 24, chord[1] + 24, chord[3] + 12, chord[0] + 24]
            for k, note in enumerate(phrase):
                mix.note(start + k * beat, note, beat * 1.25, 0.081, "bell", (-1) ** k * 0.3)
    mix.write("menu", 0.79)


def score_battle():
    beat = 60 / 128
    mix = Mix(64 * beat, seed=42, loop=True)
    melody = [74, 77, 81, 79, 77, 74, 72, 74, 77, 79, 81, 84, 81, 79, 77, 74]
    for bar in range(16):
        start = bar * 4 * beat
        chord = CHORDS[bar // 2]
        for j, note in enumerate(chord):
            mix.note(start, note + 12, 4 * beat + 0.7, 0.045, "pad", (j - 1.5) * 0.32)
        for k in range(8):
            root = chord[0] - 12 + (12 if k == 6 else 0)
            mix.note(start + k * beat / 2, root, beat * 0.43, 0.22 if k % 2 == 0 else 0.16, "bass")
            mix.hat(start + k * beat / 2, 0.058 if k % 2 == 0 else 0.036, open_hat=k == 7, pan=0.35)
            mix.note(start + k * beat / 2, chord[k % 4] + 24, beat * 0.55, 0.027, pan=-0.4)
        for k in (0, 1.75, 2, 2.75):
            mix.kick(start + k * beat, 0.32)
        for k in (1, 3):
            mix.snare(start + k * beat, 0.20)
        # Call, response and rests keep the theme readable beneath match events.
        if bar % 4 in (0, 1, 3):
            for k in range(4):
                note = melody[((bar % 4) * 4 + k) % 16]
                if bar >= 8:
                    note -= 12 if bar % 4 == 1 else 0
                if bar in (12, 13):
                    note = [73, 76, 79, 81][k]
                mix.note(start + k * beat, note, beat * (1.45 if k == 3 else 0.78), 0.090, "lead", 0.14)
        if bar in (7, 15):
            for k in range(4):
                mix.snare(start + (3 + k / 4) * beat, 0.075 + k * 0.016, pan=-0.1)
    mix.write("battle", 0.81)


def noise_sweep(mix, duration, low, high, decay, noise_amp=0.25, tonal=0.75):
    data = array("f")
    phase = 0.0
    filtered = 0.0
    for i in range(round(duration * RATE)):
        t = i / RATE
        u = t / duration
        freq = low * (high / low) ** u
        phase += TAU * freq / RATE
        white = mix.random.uniform(-1, 1)
        filtered += (0.08 + u * 0.22) * (white - filtered)
        env = min(1, t / 0.005) * min(1, (duration - t) / 0.03) * math.exp(-t * decay)
        data.append((math.sin(phase) * tonal + filtered * noise_amp) * env)
    return data


def effects():
    mix = Mix(0.11)
    mix.note(0, 91, 0.075, 0.5, "bell")
    mix.note(0.018, 103, 0.08, 0.14, "bell", 0.2)
    mix.write("click", 0.60)

    mix = Mix(0.28)
    mix.note(0, 81, 0.20, 0.45, "bell")
    mix.note(0.04, 93, 0.18, 0.19, "bell", 0.3)
    mix.write("countdown", 0.74)

    mix = Mix(1.05)
    mix.add(0, noise_sweep(mix, 0.76, 95, 1500, -0.65, 1.2, 0.36), 0.36, -0.15)
    mix.note(0.12, 62, 0.7, 0.13, "pad")
    mix.add(0.64, noise_sweep(mix, 0.28, 270, 70, 11, 1.5, 0.6), 0.8)
    mix.kick(0.66, 0.72)
    mix.write("launch", 0.87)

    mix = Mix(0.48, seed=37)
    mix.add(0, noise_sweep(mix, 0.22, 750, 180, 20, 1.2, 0.42), 0.75)
    mix.kick(0.0, 0.72)
    for j, note in enumerate((74, 87, 99)):
        mix.note(j * 0.018, note, 0.25, 0.30 / (j + 1), "bell", (j - 1) * 0.42)
    mix.write("clash", 0.89)

    mix = Mix(1.20)
    mix.add(0, noise_sweep(mix, 1.0, 110, 1250, -0.3, 0.7, 0.45), 0.40)
    for j, note in enumerate((62, 69, 74, 77)):
        mix.note(j * 0.17, note, 0.48, 0.15, "bell", (j - 1.5) * 0.3)
    mix.write("charge", 0.72)

    mix = Mix(0.60)
    for j, note in enumerate((74, 81, 86)):
        mix.note(j * 0.075, note, 0.35, 0.22, "bell", (j - 1) * 0.25)
    mix.add(0, noise_sweep(mix, 0.4, 80, 420, 3, 0.5, 0.65), 0.24)
    mix.write("telegraph", 0.72)

    mix = Mix(1.9)
    mix.add(0, noise_sweep(mix, 0.47, 85, 1200, -0.8, 1.2, 0.5), 0.60)
    for j, note in enumerate((62, 69, 74, 77, 81, 86)):
        mix.note(0.12 + j * 0.065, note, 0.55, 0.18, "bell", (j - 2.5) * 0.16)
    mix.kick(0.46, 0.84)
    mix.add(0.46, noise_sweep(mix, 0.68, 510, 35, 6, 1.7, 0.7), 0.75)
    for j, note in enumerate((50, 57, 62, 65)):
        mix.note(0.46, note, 1.15, 0.20, "pad", (j - 1.5) * 0.5)
    mix.write("ability", 0.89)

    mix = Mix(1.30, seed=77)
    mix.kick(0.0, 0.80)
    mix.add(0, noise_sweep(mix, 0.75, 360, 40, 7, 1.8, 0.5), 0.75)
    for j in range(13):
        mix.note(0.025 + j * 0.023, 95 - j * 2, 0.37, 0.18, "bell", math.sin(j * 1.7) * 0.9)
    mix.write("burst", 0.89)

    mix = Mix(2.70)
    for j, note in enumerate((62, 65, 69, 74, 77, 81, 86)):
        mix.note(j * 0.125, note, 0.60, 0.24, "bell", (j - 3) * 0.15)
    for j, note in enumerate((50, 57, 62, 65, 69)):
        mix.note(0.65, note, 1.80, 0.21, "pad", (j - 2) * 0.3)
    mix.kick(0.65, 0.30)
    mix.write("win", 0.82)

    mix = Mix(2.40)
    for j, note in enumerate((69, 65, 64, 62)):
        mix.note(j * 0.22, note, 0.83, 0.30, "bell", (j - 1.5) * 0.2)
    for j, note in enumerate((38, 45, 53)):
        mix.note(0.6, note, 1.55, 0.25, "pad", (j - 1) * 0.4)
    mix.write("lose", 0.72)


if __name__ == "__main__":
    score_menu()
    score_battle()
    effects()
