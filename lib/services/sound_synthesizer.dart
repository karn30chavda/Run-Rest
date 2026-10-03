import 'dart:math';
import 'dart:typed_data';

class SoundSynthesizer {
  static const int sampleRate = 22050; // Crisp and fast to synthesize

  /// Build a standard 44-byte RIFF/WAVE header for 16-bit Mono PCM
  static Uint8List _buildWavHeader(int numSamples) {
    final int subChunk2Size = numSamples * 2; // 16-bit = 2 bytes per sample
    final int chunkSize = 36 + subChunk2Size;
    final ByteData header = ByteData(44);

    // "RIFF"
    header.setUint8(0, 0x52);
    header.setUint8(1, 0x49);
    header.setUint8(2, 0x46);
    header.setUint8(3, 0x46);
    header.setUint32(4, chunkSize, Endian.little);

    // "WAVE"
    header.setUint8(8, 0x57);
    header.setUint8(9, 0x41);
    header.setUint8(10, 0x56);
    header.setUint8(11, 0x45);

    // "fmt "
    header.setUint8(12, 0x66);
    header.setUint8(13, 0x6D);
    header.setUint8(14, 0x74);
    header.setUint8(15, 0x20);
    header.setUint32(16, 16, Endian.little); // Subchunk1Size (16 for PCM)
    header.setUint16(20, 1, Endian.little); // AudioFormat (1 = PCM)
    header.setUint16(22, 1, Endian.little); // NumChannels (1 = Mono)
    header.setUint32(24, sampleRate, Endian.little); // SampleRate
    header.setUint32(28, sampleRate * 2, Endian.little); // ByteRate (SampleRate * 1 * 2)
    header.setUint16(32, 2, Endian.little); // BlockAlign (1 * 2)
    header.setUint16(34, 16, Endian.little); // BitsPerSample (16)

    // "data"
    header.setUint8(36, 0x64);
    header.setUint8(37, 0x61);
    header.setUint8(38, 0x74);
    header.setUint8(39, 0x61);
    header.setUint32(40, subChunk2Size, Endian.little);

    return header.buffer.asUint8List();
  }

  /// Synthesize a single-tone WAV buffer with attack/decay envelope
  static Uint8List createTone({
    required double freq,
    required double durationSec,
    double volume = 0.8,
    bool isClick = false,
    bool isTriangle = true,
  }) {
    final int numSamples = (sampleRate * durationSec).ceil();
    final ByteData pcm = ByteData(44 + numSamples * 2);
    final Uint8List header = _buildWavHeader(numSamples);

    for (int i = 0; i < 44; i++) {
      pcm.setUint8(i, header[i]);
    }

    final double twoPiF = 2.0 * pi * freq;
    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;
      double env;
      if (isClick) {
        env = exp(-55.0 * t);
      } else {
        final double attack = 0.015;
        final double decay = 0.04;
        env = min(1.0, min(t / attack, (durationSec - t) / decay));
      }

      double wave;
      if (isTriangle) {
        // Triangle wave
        wave = (2.0 / pi) * asin(sin(twoPiF * t));
      } else {
        wave = sin(twoPiF * t);
      }

      final double sample = wave * env * volume * (isClick ? 0.9 : 0.8);
      final int intSample = (sample.clamp(-1.0, 1.0) * 32767).round();
      pcm.setInt16(44 + i * 2, intSample, Endian.little);
    }

    return pcm.buffer.asUint8List();
  }

  /// Synthesize an authentic Boxing Gym Bell strike
  static Uint8List createBoxingBell({double durationSec = 1.3, double volume = 0.85}) {
    final int numSamples = (sampleRate * durationSec).ceil();
    final ByteData pcm = ByteData(44 + numSamples * 2);
    final Uint8List header = _buildWavHeader(numSamples);

    for (int i = 0; i < 44; i++) {
      pcm.setUint8(i, header[i]);
    }

    // Authentic bell harmonics (non-integer ratios)
    const List<double> freqs = [587.33, 880.0, 1200.0, 2400.0, 3100.0];
    const List<double> weights = [0.45, 0.30, 0.20, 0.12, 0.08];
    const List<double> decays = [2.2, 3.5, 4.8, 6.5, 8.0];

    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;
      double sample = 0.0;

      for (int k = 0; k < freqs.length; k++) {
        final double env = exp(-decays[k] * t);
        sample += sin(2.0 * pi * freqs[k] * t) * weights[k] * env;
      }

      // Initial metallic strike transient
      if (t < 0.008) {
        sample += (Random(i).nextDouble() * 2 - 1) * 0.25 * (1 - t / 0.008);
      }

      sample *= volume;
      final int intSample = (sample.clamp(-1.0, 1.0) * 32767).round();
      pcm.setInt16(44 + i * 2, intSample, Endian.little);
    }

    return pcm.buffer.asUint8List();
  }

  /// Synthesize a Sports Referee Whistle with frequency modulation
  static Uint8List createWhistle({double durationSec = 0.45, double volume = 0.8}) {
    final int numSamples = (sampleRate * durationSec).ceil();
    final ByteData pcm = ByteData(44 + numSamples * 2);
    final Uint8List header = _buildWavHeader(numSamples);

    for (int i = 0; i < 44; i++) {
      pcm.setUint8(i, header[i]);
    }

    double phase1 = 0.0;
    double phase2 = 0.0;

    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;
      final double env = min(1.0, min(t / 0.03, (durationSec - t) / 0.05));
      // Whistle vibrato/tremolo (~28 Hz)
      final double tremolo = 1.0 + 0.08 * sin(2.0 * pi * 28.0 * t);
      final double freq1 = (2600.0 + 120.0 * sin(2.0 * pi * 32.0 * t));
      final double freq2 = (2850.0 + 100.0 * cos(2.0 * pi * 28.0 * t));

      phase1 += 2.0 * pi * freq1 / sampleRate;
      phase2 += 2.0 * pi * freq2 / sampleRate;

      final double sample = (sin(phase1) * 0.55 + sin(phase2) * 0.45) * tremolo * env * volume;
      final int intSample = (sample.clamp(-1.0, 1.0) * 32767).round();
      pcm.setInt16(44 + i * 2, intSample, Endian.little);
    }

    return pcm.buffer.asUint8List();
  }

  /// Synthesize a Zen Singing Bowl / Gong
  static Uint8List createZenChime({double durationSec = 1.5, double volume = 0.8}) {
    final int numSamples = (sampleRate * durationSec).ceil();
    final ByteData pcm = ByteData(44 + numSamples * 2);
    final Uint8List header = _buildWavHeader(numSamples);

    for (int i = 0; i < 44; i++) {
      pcm.setUint8(i, header[i]);
    }

    // Peaceful 432 Hz Pythagorean harmonic scale
    const List<double> freqs = [216.0, 432.0, 864.0, 1296.0];
    const List<double> weights = [0.45, 0.35, 0.15, 0.08];

    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;
      final double attack = min(1.0, t / 0.03);
      final double decay = exp(-1.8 * t);
      double sample = 0.0;

      for (int k = 0; k < freqs.length; k++) {
        sample += sin(2.0 * pi * freqs[k] * t) * weights[k];
      }

      sample = sample * attack * decay * volume;
      final int intSample = (sample.clamp(-1.0, 1.0) * 32767).round();
      pcm.setInt16(44 + i * 2, intSample, Endian.little);
    }

    return pcm.buffer.asUint8List();
  }

  /// Synthesize an 8-bit Arcade Chirp (pitch sweep)
  static Uint8List createArcadeChirp({double durationSec = 0.28, double volume = 0.75}) {
    final int numSamples = (sampleRate * durationSec).ceil();
    final ByteData pcm = ByteData(44 + numSamples * 2);
    final Uint8List header = _buildWavHeader(numSamples);

    for (int i = 0; i < 44; i++) {
      pcm.setUint8(i, header[i]);
    }

    double phase = 0.0;
    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;
      final double progress = t / durationSec;
      final double freq = 450.0 + (1300.0 - 450.0) * pow(progress, 0.7);
      phase += 2.0 * pi * freq / sampleRate;

      // Pulse wave
      final double wave = (sin(phase) > 0.0) ? 0.7 : -0.7;
      final double env = 1.0 - progress;
      final double sample = wave * env * volume;

      final int intSample = (sample.clamp(-1.0, 1.0) * 32767).round();
      pcm.setInt16(44 + i * 2, intSample, Endian.little);
    }

    return pcm.buffer.asUint8List();
  }

  /// Synthesize a Victory Fanfare Arpeggio
  static Uint8List createVictoryFanfare() {
    const double noteDuration = 0.18;
    const List<double> notes = [523.25, 659.25, 783.99, 1046.50]; // C5, E5, G5, C6
    final int totalSamples = (sampleRate * (noteDuration * 3 + 0.6)).ceil();

    final ByteData pcm = ByteData(44 + totalSamples * 2);
    final Uint8List header = _buildWavHeader(totalSamples);
    for (int i = 0; i < 44; i++) {
      pcm.setUint8(i, header[i]);
    }

    for (int i = 0; i < totalSamples; i++) {
      final double t = i / sampleRate;
      int noteIdx = (t / noteDuration).floor();
      if (noteIdx >= notes.length) noteIdx = notes.length - 1;

      final double noteStart = noteIdx < 3 ? noteIdx * noteDuration : 3 * noteDuration;
      final double tInNote = t - noteStart;
      final double dur = noteIdx == 3 ? 0.6 : noteDuration;

      final double env = exp(-2.2 * tInNote / dur);
      final double freq = notes[noteIdx];
      final double wave = sin(2.0 * pi * freq * t) * 0.7 + sin(4.0 * pi * freq * t) * 0.3;
      final double sample = wave * env * 0.8;

      final int intSample = (sample.clamp(-1.0, 1.0) * 32767).round();
      pcm.setInt16(44 + i * 2, intSample, Endian.little);
    }

    return pcm.buffer.asUint8List();
  }

  /// Synthesize a seamless looping workout ambient music track
  static Uint8List createAmbientLoop(String style) {
    // 4 bars at 120 bpm = 8 seconds loop
    const double durationSec = 8.0;
    final int totalSamples = (sampleRate * durationSec).ceil();
    final ByteData pcm = ByteData(44 + totalSamples * 2);
    final Uint8List header = _buildWavHeader(totalSamples);
    for (int i = 0; i < 44; i++) {
      pcm.setUint8(i, header[i]);
    }

    final double beatLen = 60.0 / 120.0; // 0.5s per beat, 16 beats total

    for (int i = 0; i < totalSamples; i++) {
      final double t = i / sampleRate;
      final double beatPos = (t % beatLen) / beatLen;
      final int currentBeat = (t / beatLen).floor();

      double sample = 0.0;

      if (style == 'ambientPulse') {
        // Kick on 1 and 3 (every 2 beats)
        if (currentBeat % 2 == 0) {
          final double kickT = beatPos * beatLen;
          final double kickFreq = 120.0 * exp(-28.0 * kickT) + 45.0;
          final double kickEnv = exp(-12.0 * kickT);
          sample += sin(2.0 * pi * kickFreq * kickT) * kickEnv * 0.55;
        }

        // Soft sub-bass chord progression (A minor -> F -> C -> G)
        final int bar = (currentBeat ~/ 4) % 4;
        final double bassFreq = [110.0, 87.31, 130.81, 98.0][bar];
        final double bassEnv = 0.28 + 0.08 * sin(2.0 * pi * 2.0 * t);
        sample += sin(2.0 * pi * bassFreq * t) * bassEnv;

        // Gentle synth pad harmonic
        sample += sin(2.0 * pi * bassFreq * 2.0 * t) * 0.08;
      } else if (style == 'loFiFlow') {
        // Mellow 80 BPM feel on 8s
        final double lofiBeatLen = 60.0 / 80.0; // 0.75s
        final double lofiPos = (t % lofiBeatLen) / lofiBeatLen;
        final int lofiBeat = (t / lofiBeatLen).floor();

        // Warm electric piano chord notes
        final int bar = (lofiBeat ~/ 4) % 4;
        final List<double> chord = [
          [220.0, 261.63, 329.63], // Am
          [174.61, 220.0, 261.63], // F
          [261.63, 329.63, 392.0], // C
          [196.0, 246.94, 293.66], // G
        ][bar];

        for (final f in chord) {
          sample += sin(2.0 * pi * f * t) * 0.10;
        }

        // Soft vinyl warmth & mellow bass
        final double kickT = lofiPos * lofiBeatLen;
        if (lofiBeat % 2 == 0) {
          sample += sin(2.0 * pi * 65.0 * kickT) * exp(-10.0 * kickT) * 0.35;
        }
      } else {
        // technoDrive (High energy workout groove)
        // 4-on-the-floor kick
        final double kickT = beatPos * beatLen;
        final double kickFreq = 160.0 * exp(-32.0 * kickT) + 50.0;
        sample += sin(2.0 * pi * kickFreq * kickT) * exp(-14.0 * kickT) * 0.65;

        // Offbeat hi-hat on every half beat
        if (beatPos > 0.45 && beatPos < 0.75) {
          final double hatT = (beatPos - 0.5) * beatLen;
          if (hatT >= 0) {
            sample += (Random(i).nextDouble() * 2 - 1) * exp(-45.0 * hatT) * 0.22;
          }
        }

        // Driving bassline (16th note arp)
        final int sub16th = (beatPos * 4).floor();
        final double arpFreq = [130.81, 146.83, 164.81, 196.0][sub16th % 4];
        final double subT = (beatPos * 4 - sub16th) * (beatLen / 4);
        sample += sin(2.0 * pi * arpFreq * t) * exp(-15.0 * subT) * 0.25;
      }

      // Smooth loop crossfade at edges to eliminate any click
      double loopFade = 1.0;
      if (t < 0.05) {
        loopFade = t / 0.05;
      } else if (t > durationSec - 0.05) {
        loopFade = (durationSec - t) / 0.05;
      }

      sample = sample * loopFade * 0.75;
      final int intSample = (sample.clamp(-1.0, 1.0) * 32767).round();
      pcm.setInt16(44 + i * 2, intSample, Endian.little);
    }

    return pcm.buffer.asUint8List();
  }
}
