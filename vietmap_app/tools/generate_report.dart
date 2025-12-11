import 'dart:convert';
import 'dart:io';

dynamic readJson(String path) {
  return jsonDecode(File(path).readAsStringSync());
}

void main() {
  final base = Directory('data_sources/final');

  final files = {
    'cameras': 'cameras.json',
    'railway': 'railway.json',
    'danger_zone': 'danger_zone.json',
    'speed_limit': 'speed_limit.json',
  };

  final result = <String, int>{};

  files.forEach((key, fileName) {
    final file = File('${base.path}/$fileName');
    if (!file.existsSync()) {
      result[key] = -1;
      return;
    }
    final data = readJson(file.path);
    if (data is List) {
      result[key] = data.length;
    } else if (data is Map && data.containsKey('features')) {
      result[key] = (data['features'] as List).length;
    } else {
      result[key] = -2; // invalid format indicator
    }
  });

  File('${base.path}/report.json')
      .writeAsStringSync(JsonEncoder.withIndent('  ').convert(result));

  print('Report generated: ${result}');
}

