import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

@singleton
class VillagesDbService {
  String? _appDocDirPath;

  Future<String> _ensurePath() async {
    if (_appDocDirPath != null) return _appDocDirPath!;
    final dir = await getApplicationDocumentsDirectory();
    _appDocDirPath = dir.path;
    return _appDocDirPath!;
  }

  Future<bool> isAvailableAsync() async {
    final dir = await _ensurePath();
    return File(p.join(dir, 'villages.db')).existsSync();
  }

  Future<String?> get villagesDbPath async {
    final dir = await _ensurePath();
    final path = p.join(dir, 'villages.db');
    if (File(path).existsSync()) return path;
    return null;
  }
}
