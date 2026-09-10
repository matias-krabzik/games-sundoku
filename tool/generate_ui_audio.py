"""Generate original, quiet SunDoku marimba loop and tactile UI pop (no samples)."""
import math
import struct
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / 'assets' / 'audio'
RATE = 22050

def write(name, samples):
    with wave.open(str(ROOT / name), 'wb') as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(RATE)
        out.writeframes(b''.join(struct.pack('<h', round(max(-1, min(1, x)) * 32767)) for x in samples))

# Sixteen seconds, integer bar length; note tails wrap to keep the seam smooth.
length = 16
samples = [0.] * (RATE * length)
melody = [72, 76, 79, 76, 69, 72, 76, 72, 65, 69, 72, 69, 67, 71, 74, 71]
for beat, midi in enumerate(melody):
    f = 440 * 2 ** ((midi - 69) / 12)
    for j in range(int(RATE * 1.8)):
        t = j / RATE
        attack = min(1, t / .014)
        tone = math.sin(2 * math.pi * f * t) * math.exp(-3.8*t)
        tone += .22 * math.sin(2 * math.pi * f * 2 * t) * math.exp(-7*t)
        samples[(beat * RATE + j) % len(samples)] += tone * attack * .19
write('sunny-loop.wav', samples)
write('soft-tap.wav', [math.sin(2*math.pi*(760*t - 2100*t*t)) * math.sin(math.pi*t/.095)**2 * math.exp(-24*t) * .48 for t in (i/RATE for i in range(int(RATE*.095)))])
