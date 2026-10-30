"""Generate an original quiet heart-pop sound; no licensed samples required."""
import math
import struct
import wave
from pathlib import Path

target = Path(__file__).resolve().parents[1] / 'assets/audio/heart.wav'
target.parent.mkdir(parents=True, exist_ok=True)
rate, seconds = 22050, 0.32
with wave.open(str(target), 'wb') as output:
    output.setparams((1, 2, rate, 0, 'NONE', 'not compressed'))
    for i in range(int(rate * seconds)):
        t = i / rate
        envelope = min(1, t / 0.015) * math.exp(-t * 14)
        tone = math.sin(2 * math.pi * 523.25 * t) + .3 * math.sin(2 * math.pi * 783.99 * t)
        output.writeframesraw(struct.pack('<h', int(5500 * tone * envelope)))
