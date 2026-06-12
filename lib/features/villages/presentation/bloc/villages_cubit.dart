import 'dart:io';

import 'package:cities_offline_app/di/di.dart';
import 'package:cities_offline_app/features/mediator/domain/repos/cities_repository.dart';
import 'package:flutter_archive/flutter_archive.dart';
import 'package:http/http.dart' as http;
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

enum VillagesStatus { idle, downloading, failed }

class VillagesState {
  final VillagesStatus status;
  final double progress;
  final bool isAvailable;
  final String? error;

  const VillagesState({
    this.status = VillagesStatus.idle,
    this.progress = 0,
    this.isAvailable = false,
    this.error,
  });

  VillagesState copyWith({
    VillagesStatus? status,
    double? progress,
    bool? isAvailable,
    String? error,
  }) {
    return VillagesState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      isAvailable: isAvailable ?? this.isAvailable,
      error: error,
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status.name,
    'progress': progress,
    'isAvailable': isAvailable,
    'error': error,
  };

  factory VillagesState.fromJson(Map<String, dynamic> json) => VillagesState(
    status: VillagesStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => VillagesStatus.idle,
    ),
    progress: (json['progress'] as num?)?.toDouble() ?? 0,
    isAvailable: json['isAvailable'] as bool? ?? false,
    error: json['error'] as String?,
  );
}

@singleton
class VillagesCubit extends HydratedCubit<VillagesState> {
  http.Client? _client;
  bool _isCancelled = false;

  VillagesCubit() : super(const VillagesState());

  static const _downloadUrl =
      'https://github.com/Churikov0112/cities_offline_app/releases/download/v1.0.0-villages/villages.db.zip';

  static const _tempZipName = 'temp_villages_download.zip';
  static const _dbFileName = 'villages.db';

  String? _appDocDirPath;

  Future<String> _getAppDocDir() async {
    if (_appDocDirPath != null) {
      return _appDocDirPath!;
    }
    final dir = await getApplicationDocumentsDirectory();
    _appDocDirPath = dir.path;
    return _appDocDirPath!;
  }

  void init() {
    _cleanupTempOnStart();
    refreshAvailability();
  }

  void _cleanupTempOnStart() {
    getApplicationDocumentsDirectory().then((dir) {
      final tempFile = File(p.join(dir.path, _tempZipName));
      if (tempFile.existsSync()) {
        tempFile.deleteSync();
      }
    });
  }

  void refreshAvailability() {
    getApplicationDocumentsDirectory().then((dir) {
      final dbFile = File(p.join(dir.path, _dbFileName));
      final available = dbFile.existsSync();
      if (available != state.isAvailable) {
        emit(state.copyWith(isAvailable: available));
      }
    });
  }

  Future<void> startDownload() async {
    _isCancelled = false;
    final appDir = await _getAppDocDir();

    final tempFile = File(p.join(appDir, _tempZipName));
    if (tempFile.existsSync()) {
      await tempFile.delete();
    }

    emit(const VillagesState(status: VillagesStatus.downloading));

    try {
      final request = http.Request('GET', Uri.parse(_downloadUrl));
      _client = http.Client();
      final response = await _client!.send(request);

      if (_isCancelled) {
        return;
      }

      if (response.statusCode != 200) {
        emit(
          VillagesState(
            status: VillagesStatus.failed,
            error: 'HTTP ${response.statusCode}',
          ),
        );
        return;
      }

      final contentLength = response.contentLength ?? -1;
      var bytesReceived = 0;
      final sink = tempFile.openWrite();

      await for (final chunk in response.stream) {
        if (_isCancelled) {
          await sink.close();
          return;
        }
        sink.add(chunk);
        bytesReceived += chunk.length;
        if (contentLength > 0) {
          emit(
            VillagesState(
              status: VillagesStatus.downloading,
              progress: bytesReceived / contentLength,
            ),
          );
        }
      }
      await sink.close();
      _client = null;

      if (_isCancelled) {
        return;
      }

      emit(
        const VillagesState(
          status: VillagesStatus.downloading,
          progress: 1,
        ),
      );

      await ZipFile.extractToDirectory(
        zipFile: tempFile,
        destinationDir: Directory(appDir),
      );

      if (_isCancelled) {
        return;
      }

      if (tempFile.existsSync()) {
        await tempFile.delete();
      }

      final dbFile = File(p.join(appDir, _dbFileName));
      if (!dbFile.existsSync()) {
        emit(
          const VillagesState(
            status: VillagesStatus.failed,
            error: 'Extraction failed',
          ),
        );
        return;
      }

      emit(const VillagesState(isAvailable: true));
    } catch (e) {
      _client = null;
      if (_isCancelled) {
        return;
      }
      if (tempFile.existsSync()) {
        await tempFile.delete();
      }
      emit(
        VillagesState(
          status: VillagesStatus.failed,
          error: e.toString(),
        ),
      );
    }
  }

  void cancelDownload() {
    _isCancelled = true;
    _client?.close();
    _client = null;
    getApplicationDocumentsDirectory().then((dir) {
      final tempFile = File(p.join(dir.path, _tempZipName));
      if (tempFile.existsSync()) {
        tempFile.deleteSync();
      }
    });
    emit(VillagesState(isAvailable: state.isAvailable));
  }

  Future<void> deleteVillages() async {
    await getIt<CitiesRepository>().closeVillagesDatabase();
    final appDir = await _getAppDocDir();
    final dbPath = p.join(appDir, _dbFileName);
    final dbFile = File(dbPath);
    if (dbFile.existsSync()) {
      await dbFile.delete();
    }
    final walFile = File('${dbPath}-wal');
    if (walFile.existsSync()) {
      await walFile.delete();
    }
    final shmFile = File('${dbPath}-shm');
    if (shmFile.existsSync()) {
      await shmFile.delete();
    }
    emit(const VillagesState());
  }

  @override
  VillagesState? fromJson(Map<String, dynamic> json) {
    final restored = VillagesState.fromJson(json);
    if (restored.status == VillagesStatus.downloading) {
      return const VillagesState();
    }
    if (restored.status == VillagesStatus.failed) {
      return const VillagesState();
    }
    if (restored.isAvailable) {
      getApplicationDocumentsDirectory().then((dir) {
        final dbFile = File(p.join(dir.path, _dbFileName));
        if (!dbFile.existsSync()) {
          emit(const VillagesState());
        }
      });
    }
    return restored;
  }

  @override
  Map<String, dynamic>? toJson(VillagesState state) => state.toJson();
}
