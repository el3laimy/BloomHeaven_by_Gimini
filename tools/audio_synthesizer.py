#!/usr/bin/env python3
"""
Audio Synthesizer for Finest Garden (BloomHaven)
Generates high-clarity 16-bit 44.1kHz procedural audio sound effects and cozy BGM loop.
Requires only standard Python library.
"""

import math
import os
import random
import struct
import wave

SAMPLE_RATE = 44100


def save_wav(filename: str, samples: list[float], sample_rate: int = SAMPLE_RATE) -> None:
    os.makedirs(os.path.dirname(filename), exist_ok=True)
    with wave.open(filename, "wb") as wav_file:
        wav_file.setnchannels(1)  # Mono
        wav_file.setsampwidth(2)  # 16-bit
        wav_file.setframerate(sample_rate)
        
        packed_frames = bytearray()
        for s in samples:
            # Soft clamp between -1.0 and 1.0
            clamped = max(-1.0, min(1.0, s))
            val = int(clamped * 32767.0)
            packed_frames.extend(struct.pack("<h", val))
            
        wav_file.writeframes(packed_frames)
    print(f"Generated WAV: {filename} ({len(samples)} samples, {len(samples)/sample_rate:.2f}s)")


def generate_click() -> list[float]:
    duration = 0.05
    n_samples = int(duration * SAMPLE_RATE)
    samples = []
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        # Frequency sweep from 1400 down to 400
        freq = 1400.0 * math.exp(-t * 40.0) + 300.0
        env = math.exp(-t * 90.0)
        sample = math.sin(2.0 * math.pi * freq * t) * env * 0.75
        samples.append(sample)
    return samples


def generate_plant() -> list[float]:
    duration = 0.24
    n_samples = int(duration * SAMPLE_RATE)
    samples = []
    random.seed(42)
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        # Low soft dirt thud
        thud = math.sin(2.0 * math.pi * 130.0 * t) * math.exp(-t * 22.0) * 0.65
        # Soft granular rustle
        noise = (random.random() * 2.0 - 1.0) * math.exp(-t * 30.0) * 0.25
        samples.append(thud + noise)
    return samples


def generate_water() -> list[float]:
    duration = 0.42
    n_samples = int(duration * SAMPLE_RATE)
    samples = []
    random.seed(101)
    
    # Generate 3 overlapping water drops at staggered times
    drop_times = [0.0, 0.08, 0.18, 0.28]
    drop_freqs = [850.0, 1150.0, 950.0, 1400.0]
    
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        val = 0.0
        for dt, f in zip(drop_times, drop_freqs):
            if t >= dt:
                local_t = t - dt
                # Rising pitch chirp (classic droplet acoustic model)
                inst_freq = f * (1.0 + local_t * 5.0)
                env = math.exp(-local_t * 32.0)
                val += math.sin(2.0 * math.pi * inst_freq * local_t) * env * 0.35
        # Add subtle water spray hiss
        hiss = (random.random() * 2.0 - 1.0) * math.exp(-t * 12.0) * 0.08
        samples.append(val + hiss)
    return samples


def generate_prune() -> list[float]:
    duration = 0.16
    n_samples = int(duration * SAMPLE_RATE)
    samples = []
    random.seed(77)
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        # High metallic shear ring
        ring = (
            math.sin(2.0 * math.pi * 2800.0 * t) * 0.4 +
            math.sin(2.0 * math.pi * 4200.0 * t) * 0.3
        ) * math.exp(-t * 45.0)
        # Sharp snip transient
        click = (random.random() * 2.0 - 1.0) * math.exp(-t * 110.0) * 0.45
        samples.append((ring + click) * 0.8)
    return samples


def generate_harvest() -> list[float]:
    duration = 0.60
    n_samples = int(duration * SAMPLE_RATE)
    samples = []
    
    # Harp arpeggio: C5 (523Hz), E5 (659Hz), G5 (784Hz), C6 (1046Hz)
    notes = [
        (0.00, 523.25),
        (0.07, 659.25),
        (0.14, 783.99),
        (0.21, 1046.50),
        (0.30, 1318.51)  # E6 sparkle
    ]
    
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        val = 0.0
        for start_t, freq in notes:
            if t >= start_t:
                lt = t - start_t
                env = math.exp(-lt * 7.5)
                # Fundamental + harmonic overtone
                harm = (
                    math.sin(2.0 * math.pi * freq * lt) * 0.6 +
                    math.sin(2.0 * math.pi * freq * 2.0 * lt) * 0.25 +
                    math.sin(2.0 * math.pi * freq * 3.0 * lt) * 0.10
                )
                val += harm * env * 0.35
        samples.append(val)
    return samples


def generate_coin() -> list[float]:
    duration = 0.38
    n_samples = int(duration * SAMPLE_RATE)
    samples = []
    
    # Dual high ringing frequencies
    f1 = 2093.0  # C7
    f2 = 2793.8  # F7
    f3 = 3135.9  # G7
    
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 11.0)
        ring = (
            math.sin(2.0 * math.pi * f1 * t) * 0.45 +
            math.sin(2.0 * math.pi * f2 * t) * 0.35 +
            math.sin(2.0 * math.pi * f3 * t) * 0.20
        ) * env
        samples.append(ring * 0.75)
    return samples


def generate_upgrade() -> list[float]:
    duration = 0.85
    n_samples = int(duration * SAMPLE_RATE)
    samples = []
    
    # Triumphant chord fanfare: G4 -> C5 -> E5 -> G5 -> C6
    fanfare = [
        (0.00, 392.00, 0.15),
        (0.10, 523.25, 0.15),
        (0.20, 659.25, 0.15),
        (0.30, 783.99, 0.50),
        (0.30, 1046.50, 0.50),
        (0.30, 1318.51, 0.50)
    ]
    
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        val = 0.0
        for start_t, freq, length in fanfare:
            if t >= start_t:
                lt = t - start_t
                env = math.exp(-lt * (6.0 if length < 0.2 else 3.5))
                tone = math.sin(2.0 * math.pi * freq * lt) + 0.3 * math.sin(2.0 * math.pi * freq * 2.0 * lt)
                val += tone * env * 0.25
        samples.append(val)
    return samples


def generate_error() -> list[float]:
    duration = 0.20
    n_samples = int(duration * SAMPLE_RATE)
    samples = []
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        # Double low muted buzz
        t_cycle = t % 0.09
        env = math.exp(-t_cycle * 35.0)
        tone = math.sin(2.0 * math.pi * 180.0 * t) * env * 0.5
        samples.append(tone)
    return samples


def generate_cozy_bgm() -> list[float]:
    """Generates an 8-second seamless looping soothing kalimba chord progression (C - G - Am - F)."""
    duration = 8.0
    n_samples = int(duration * SAMPLE_RATE)
    samples = [0.0] * n_samples
    
    # 4 bars, 2.0s per bar
    # Bar 1: C major (C4, E4, G4, B4)
    # Bar 2: G major (G3, B3, D4, G4)
    # Bar 3: A minor (A3, C4, E4, A4)
    # Bar 4: F major (F3, A3, C4, F4)
    patterns = [
        # (beat_time, note_freq, amplitude)
        (0.0, 261.63, 0.35), (0.4, 329.63, 0.25), (0.8, 392.00, 0.30), (1.3, 493.88, 0.20),
        (2.0, 196.00, 0.35), (2.4, 246.94, 0.25), (2.8, 293.66, 0.30), (3.3, 392.00, 0.20),
        (4.0, 220.00, 0.35), (4.4, 261.63, 0.25), (4.8, 329.63, 0.30), (5.3, 440.00, 0.20),
        (6.0, 174.61, 0.35), (6.4, 220.00, 0.25), (6.8, 261.63, 0.30), (7.3, 349.23, 0.20),
    ]
    
    for start_t, freq, amp in patterns:
        start_idx = int(start_t * SAMPLE_RATE)
        # Note duration ~ 1.6s decay
        note_len = int(1.6 * SAMPLE_RATE)
        for i in range(note_len):
            idx = (start_idx + i) % n_samples  # Seamless loop wrapping
            lt = i / SAMPLE_RATE
            env = math.exp(-lt * 3.2)
            # Kalimba timbre: sine with pleasant chime harmonic
            sound = (
                math.sin(2.0 * math.pi * freq * lt) * 0.75 +
                math.sin(2.0 * math.pi * freq * 2.76 * lt) * 0.20 +
                math.sin(2.0 * math.pi * freq * 5.4 * lt) * 0.08
            ) * env * amp
            samples[idx] += sound
            
    # Soft warm bass pad drone
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        # Sub-bass root note for each 2s chord
        bass_freq = 65.41 if t < 2.0 else (49.00 if t < 4.0 else (55.00 if t < 6.0 else 43.65))
        drone = math.sin(2.0 * math.pi * bass_freq * t) * 0.12
        samples[i] += drone
        
    return samples


def main() -> None:
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    sfx_dir = os.path.join(base_dir, "assets", "audio", "sfx")
    music_dir = os.path.join(base_dir, "assets", "audio", "music")
    
    print("=== Generating Finest Garden Audio Assets ===")
    save_wav(os.path.join(sfx_dir, "sfx_click.wav"), generate_click())
    save_wav(os.path.join(sfx_dir, "sfx_plant.wav"), generate_plant())
    save_wav(os.path.join(sfx_dir, "sfx_water.wav"), generate_water())
    save_wav(os.path.join(sfx_dir, "sfx_prune.wav"), generate_prune())
    save_wav(os.path.join(sfx_dir, "sfx_harvest.wav"), generate_harvest())
    save_wav(os.path.join(sfx_dir, "sfx_coin.wav"), generate_coin())
    save_wav(os.path.join(sfx_dir, "sfx_upgrade.wav"), generate_upgrade())
    save_wav(os.path.join(sfx_dir, "sfx_error.wav"), generate_error())
    save_wav(os.path.join(music_dir, "bgm_garden_loop.wav"), generate_cozy_bgm())
    print("=== All Audio Assets Synthesized Successfully ===")


if __name__ == "__main__":
    main()
