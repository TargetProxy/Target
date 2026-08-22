import 'dart:convert';
import 'dart:io';

class JsonFileStore {
  const JsonFileStore(this.file);

  final File file;

  Future<Map<String, dynamic>?> readObject() async {
    if (!await file.exists()) {
      return null;
    }

    try {
      final text = await file.readAsString();
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      throw const FormatException('Expected a JSON object.');
    } on FormatException {
      await _preserveCorruptFile();
      rethrow;
    }
  }

  Future<void> writeObject(Map<String, dynamic> value) async {
    await file.parent.create(recursive: true);
    final temp = File('${file.path}.tmp');
    final json = const JsonEncoder.withIndent('  ').convert(value);
    await temp.writeAsString('$json\n', flush: true);

    if (await file.exists()) {
      await file.delete();
    }
    await temp.rename(file.path);
  }

  Future<void> _preserveCorruptFile() async {
    if (!await file.exists()) {
      return;
    }
    final timestamp = DateTime.now()
        .toUtc()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final corrupt = File('${file.path}.corrupt.$timestamp');
    await file.rename(corrupt.path);
  }
}
