import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

const sampleRate = 44100;

double _envelope(int index, int length, {double attack = 0.08}) {
  final position = index / max(1, length - 1);
  final rise = min(1.0, position / attack);
  return rise * pow(1 - position, 1.7).toDouble();
}

List<double> _tone(double seconds, double startHz, double endHz,
    {double strength = 0.55}) {
  final length = (sampleRate * seconds).round();
  var phase = 0.0;
  return List.generate(length, (index) {
    final position = index / max(1, length - 1);
    final hz = startHz + (endHz - startHz) * position;
    phase += 2 * pi * hz / sampleRate;
    final body = sin(phase) + 0.22 * sin(phase * 2.01);
    return body * _envelope(index, length) * strength;
  });
}

List<double> _sequence(List<(double, double)> notes,
    {double gap = 0.018, double strength = 0.46}) {
  final output = <double>[];
  for (final (hz, seconds) in notes) {
    output.addAll(_tone(seconds, hz, hz * 1.002, strength: strength));
    output.addAll(List.filled((sampleRate * gap).round(), 0));
  }
  return output;
}

List<double> _click({required bool lower}) {
  final random = Random(lower ? 193 : 151);
  final length = (sampleRate * (lower ? 0.045 : 0.026)).round();
  var previousNoise = 0.0;
  return List.generate(length, (index) {
    final position = index / max(1, length - 1);
    final noise = random.nextDouble() * 2 - 1;
    final transient = noise - previousNoise * 0.72;
    previousNoise = noise;
    final decay = exp(-position * (lower ? 7.5 : 12.0));
    final body = lower ? sin(2 * pi * 165 * index / sampleRate) * 0.16 : 0.0;
    return (transient * 0.5 + body) * decay;
  });
}

List<double> _crackle({required bool descending}) {
  final random = Random(descending ? 731 : 417);
  final seconds = descending ? 0.16 : 0.23;
  final length = (sampleRate * seconds).round();
  final burstCenters = descending
      ? [0.015, 0.041, 0.078, 0.125]
      : [0.008, 0.027, 0.052, 0.089, 0.137, 0.194];
  var previousNoise = 0.0;
  return List.generate(length, (index) {
    final time = index / sampleRate;
    final position = index / max(1, length - 1);
    final noise = random.nextDouble() * 2 - 1;
    final sharpNoise = noise - previousNoise * 0.9;
    previousNoise = noise;

    var pops = 0.0;
    for (final center in burstCenters) {
      final distance = (time - center).abs();
      if (distance < 0.006) {
        pops += sharpNoise * exp(-distance * 520) * 0.85;
      }
    }

    final staticGate = random.nextDouble() > 0.58 ? 1.0 : 0.12;
    final hiss = sharpNoise * staticGate * 0.16;
    final buzz = sin(2 * pi * (descending ? 92 : 118) * time) * 0.035;
    final tail = pow(1 - position, descending ? 2.4 : 1.35).toDouble();
    return (pops + hiss + buzz) * tail;
  });
}

void _writeWav(String path, List<double> samples) {
  final dataLength = samples.length * 2;
  final bytes = BytesBuilder();
  void ascii(String value) => bytes.add(value.codeUnits);
  void u16(int value) {
    final data = ByteData(2)..setUint16(0, value, Endian.little);
    bytes.add(data.buffer.asUint8List());
  }

  void u32(int value) {
    final data = ByteData(4)..setUint32(0, value, Endian.little);
    bytes.add(data.buffer.asUint8List());
  }

  ascii('RIFF');
  u32(36 + dataLength);
  ascii('WAVEfmt ');
  u32(16);
  u16(1);
  u16(1);
  u32(sampleRate);
  u32(sampleRate * 2);
  u16(2);
  u16(16);
  ascii('data');
  u32(dataLength);
  for (final sample in samples) {
    final value = (sample.clamp(-1.0, 1.0) * 32767).round();
    final data = ByteData(2)..setInt16(0, value, Endian.little);
    bytes.add(data.buffer.asUint8List());
  }
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes.takeBytes());
}

void main() {
  const directory = 'assets/sounds';
  _writeWav('$directory/move.wav', _click(lower: false));
  _writeWav('$directory/remove.wav', _click(lower: true));
  _writeWav(
    '$directory/hint.wav',
    _sequence([(1046.5, 0.075), (1318.5, 0.105)], strength: 0.36),
  );
  _writeWav(
    '$directory/success.wav',
    _sequence(
      [(523.3, 0.12), (659.3, 0.12), (784.0, 0.14), (1046.5, 0.3)],
      gap: 0.012,
    ),
  );
  _writeWav(
    '$directory/level_up.wav',
    _sequence(
      [
        (523.3, 0.1),
        (659.3, 0.1),
        (784.0, 0.12),
        (987.8, 0.14),
        (1046.5, 0.38),
      ],
      gap: 0.015,
      strength: 0.5,
    ),
  );
  _writeWav('$directory/hashi_connect.wav', _crackle(descending: false));
  _writeWav('$directory/hashi_remove.wav', _crackle(descending: true));
}
