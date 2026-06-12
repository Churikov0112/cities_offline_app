import 'dart:io';

import 'package:cities_offline_app/di/di.dart';
import 'package:cities_offline_app/features/countries/presentation/bloc/countries_bloc.dart';
import 'package:cities_offline_app/features/languages/presentation/bloc/languages_bloc.dart';
import 'package:cities_offline_app/features/villages/presentation/bloc/villages_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_archive/flutter_archive.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';

import 'core/ui_kit/ui_kit.dart';
import 'services/navigation/navigation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppRouter _router;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    HydratedBloc.storage = await HydratedStorage.build(
      storageDirectory: HydratedStorageDirectory((await getApplicationSupportDirectory()).path),
      // encryptionCipher: hydratedAesCipher,
    );
    await configureDependencies();
    await getIt.allReady();
    setState(() {});
    _router = AppRouter();
    await _unpackDatabase();

    await getIt<LanguagesBloc>().loadIfNeeded();
    await getIt<CountriesBloc>().loadIfNeeded();

    final villagesCubit = getIt<VillagesCubit>();
    villagesCubit.init();

    _isInitialized = true;
    setState(() {});
  }

  Future<void> _unpackDatabase() async {
    // 1. Получаем директорию для хранения файлов приложения
    final appDocumentsDir = await getApplicationDocumentsDirectory();
    final unpackedDbFile = File('${appDocumentsDir.path}/cities.db');

    // 2. Если БД уже распакована, выходим
    if (unpackedDbFile.existsSync()) {
      return;
    }

    // 3. Загружаем архив из assets во временный файл
    final byteData = await rootBundle.load('assets/database/cities.db.zip');
    final tempFile = File('${appDocumentsDir.path}/temp_cities.zip');
    await tempFile.writeAsBytes(byteData.buffer.asUint8List());

    // 4. Распаковываем архив
    try {
      // Показываем пользователю прогресс, если это возможно
      await ZipFile.extractToDirectory(
        zipFile: tempFile,
        destinationDir: appDocumentsDir,
        onExtracting: (zipEntry, progress) {
          return ZipFileOperation.includeItem;
        },
      );
    } finally {
      // 5. Удаляем временный файл архива, чтобы освободить место
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    }

    print('База данных успешно распакована по пути: $unpackedDbFile');
  }

  @override
  Widget build(BuildContext context) {
    return !_isInitialized
        ? const Center(child: CircularProgressIndicator())
        : BlocProvider<VillagesCubit>(
            create: (_) => getIt<VillagesCubit>(),
            child: MaterialApp.router(
              routerConfig: _router.router,
              title: 'Cities Offline',
              color: Colors.black,
              builder: (context, child) {
                return child == null ? const SizedBox.shrink() : _MainBuilder(child: child);
              },
            ),
          );
  }
}

class _MainBuilder extends StatelessWidget {
  final Widget child;

  const _MainBuilder({required this.child});

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: DisableBlueGlowBehavior(),
      child: child,
    );
  }
}
