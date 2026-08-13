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

List<double> _crackle({required bool descending}) {
  final random = Random(descending ? 731 : 417);
  final length = (sampleRate * 0.14).round();
  var phase = 0.0;
  return List.generate(length, (index) {
    final position = index / max(1, length - 1);
    final hz = descending ? 980 - 570 * position : 1160 + 720 * position;
    phase += 2 * pi * hz / sampleRate;
    final sparse =
        random.nextDouble() > 0.82 ? (random.nextDouble() * 2 - 1) * 0.6 : 0.0;
    final electric = sin(phase) * 0.22 + sin(phase * 2.73) * 0.1;
    return (electric + sparse) * _envelope(index, length, attack: 0.025);
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
  _writeWav('$directory/move.wav', _tone(0.055, 760, 1020, strength: 0.34));
  _writeWav('$directory/remove.wav', _tone(0.07, 520, 280, strength: 0.32));
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
