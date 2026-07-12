import wave, struct, math
def gen_wav(filename, freq, duration, mod=False):
    f = wave.open(filename, 'w')
    f.setnchannels(1)
    f.setsampwidth(2)
    f.setframerate(44100)
    for i in range(int(44100 * duration)):
        v = int(32767.0 * math.sin(2.0 * math.pi * freq * (i / 44100.0)) * (math.exp(-i/10000.0) if mod else 1))
        f.writeframes(struct.pack('<h', v))
    f.close()

gen_wav('assets/sounds/goal.wav', 440.0, 1.0, True)
gen_wav('assets/sounds/whistle.wav', 880.0, 0.5, False)
