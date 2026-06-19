import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/locality.dart';
import '../services/villages_db_service.dart';
import '../utils/utils.dart';

@singleton
class CitiesRepository {
  Database? _citiesDb;
  Database? _villagesDb;
  final VillagesDbService _villagesDbService;

  CitiesRepository({required VillagesDbService villagesDbService}) : _villagesDbService = villagesDbService;

  Future<Database> _database() async {
    if (_citiesDb != null) {
      return _citiesDb!;
    }

    final appDocumentsDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(appDocumentsDir.path, 'cities.db');

    _citiesDb = await openDatabase(dbPath, readOnly: true, singleInstance: true);
    return _citiesDb!;
  }

  Future<Database?> _villagesDatabase() async {
    if (_villagesDb != null) {
      return _villagesDb;
    }
    final path = await _villagesDbService.villagesDbPath;
    if (path == null) {
      return null;
    }
    _villagesDb = await openDatabase(path, readOnly: true, singleInstance: true);

    if (_villagesDb == null) {
      return null;
    }

    return _villagesDb;
  }

  String _localityQuerySql({String? whereClause, String? orderByExtra}) {
    final orderBy = orderByExtra != null ? '$orderByExtra,' : '';
    return '''
      SELECT
        p.id AS id,
        p.name AS name,
        pn.name AS matched_name,
        pn.lang AS matched_lang,
        p.display_name AS display_name,
        p.city_type AS city_type,
        p.country_code AS country_code,
        p.country AS country,
        p.state AS state,
        p.lat AS lat,
        p.lon AS lon,
        p.population AS population
      FROM place_names pn
      INNER JOIN places p ON p.id = pn.place_id
      ${whereClause != null ? 'WHERE $whereClause' : ''}
      ORDER BY
        $orderBy
        CASE p.city_type
          WHEN 'city' THEN 0
          WHEN 'town' THEN 1
          WHEN 'village' THEN 2
          WHEN 'hamlet' THEN 3
          ELSE 4
        END,
        COALESCE(p.population, 0) DESC
    ''';
  }

  Future<List<Map<String, Object?>>> _queryDatabase(
    Database db,
    String sql,
    List<Object?> args,
  ) async {
    if (!db.isOpen) {
      return [];
    }
    try {
      return await db.rawQuery(sql, args);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, Object?>>> _queryAllDatabases(
    String sql,
    List<Object?> args,
  ) async {
    final db = await _database();
    final results = <Map<String, Object?>>[];
    results.addAll(await _queryDatabase(db, sql, args));

    final villagesDb = await _villagesDatabase();
    if (villagesDb != null) {
      results.addAll(await _queryDatabase(villagesDb, sql, args));
    }
    return results;
  }

  Future<Locality?> findLocalityByName(String rawQuery, {String? preferredLang}) async {
    final query = rawQuery.trim();
    if (query.isEmpty) {
      return null;
    }

    final db = await _database();
    final normalizedQuery = normalizeCityNameForSearch(query);

    Future<Map<String, Object?>?> findInDb(Database targetDb, String sql, List<Object?> args) async {
      if (!targetDb.isOpen) {
        return null;
      }
      try {
        final rows = await targetDb.rawQuery(sql, args);
        return rows.isNotEmpty ? rows.first : null;
      } catch (_) {
        return null;
      }
    }

    Future<Map<String, Object?>?> tryInAll(String sql, List<Object?> args) async {
      final row = await findInDb(db, sql, args);
      if (row != null) {
        return row;
      }
      final villagesDb = await _villagesDatabase();
      if (villagesDb != null) {
        return findInDb(villagesDb, sql, args);
      }
      return null;
    }

    String _sqlWithLang(String whereClause) {
      return _localityQuerySql(
        whereClause: whereClause,
        orderByExtra: preferredLang != null ? 'CASE WHEN pn.lang = ? THEN 0 ELSE 1 END' : null,
      );
    }

    Map<String, Object?>? row;

    if (normalizedQuery.isNotEmpty) {
      final sql = _sqlWithLang('pn.normalized_name = ?');
      final args = <Object?>[normalizedQuery];
      if (preferredLang != null) args.add(preferredLang);
      row = await tryInAll('$sql LIMIT 1', args);
      if (row != null) {
        return _mapRowToLocality(row, query);
      }
    }

    final compatibilityNormalizedQuery = compatibilityKey(query);
    if (compatibilityNormalizedQuery.isNotEmpty && compatibilityNormalizedQuery != normalizedQuery) {
      final sql = _sqlWithLang('pn.normalized_name = ?');
      final args = <Object?>[compatibilityNormalizedQuery];
      if (preferredLang != null) args.add(preferredLang);
      row = await tryInAll('$sql LIMIT 1', args);
      if (row != null) {
        return _mapRowToLocality(row, query);
      }
    }

    final variants = buildCityQueryVariants(query);
    for (final variant in variants) {
      final variantSql = _sqlWithLang('pn.name = ? COLLATE NOCASE');
      final args = <Object?>[variant];
      if (preferredLang != null) args.add(preferredLang);
      row = await tryInAll('$variantSql LIMIT 1', args);
      if (row != null) {
        return _mapRowToLocality(row, query);
      }
    }

    return null;
  }

  Locality _mapRowToLocality(Map<String, Object?> row, String fallbackQuery) {
    return Locality(
      id: row['id'] as String,
      name: row['name'] as String? ?? fallbackQuery,
      matchedName: row['matched_name'] as String? ?? fallbackQuery,
      matchedLang: row['matched_lang'] as String? ?? 'default',
      displayName: row['display_name'] as String? ?? '',
      cityType: row['city_type'] as String? ?? 'unknown',
      countryCode: row['country_code'] as String? ?? '',
      country: row['country'] as String? ?? '',
      state: row['state'] as String? ?? '',
      lat: (row['lat'] as num?)?.toDouble(),
      lon: (row['lon'] as num?)?.toDouble(),
      population: (row['population'] as num?)?.toInt(),
    );
  }

  Future<List<(String code, String name)>> loadAvailableCountries() async {
    const sql = '''
      SELECT country_code, country
      FROM places
      WHERE country_code IS NOT NULL AND TRIM(country_code) <> ''
      GROUP BY country_code, country
      ORDER BY country ASC
    ''';

    final rows = await _queryAllDatabases(sql, []);
    final seen = <String>{};
    final result = <(String, String)>[];
    for (final row in rows) {
      final code = (row['country_code'] as String? ?? '').toLowerCase();
      final name = row['country'] as String? ?? '';
      if (code.isNotEmpty && seen.add(code)) {
        result.add((code, name));
      }
    }
    return result;
  }

  Future<List<Locality>> findCandidatesByStartLetter({
    required String startLetter,
    required Set<String> allowedTypes,
    required bool allowHistoricalNames,
    required int minPopulation,
    required Set<String> usedPlaceIds,
    required Set<String> allowedCountryCodes,
    String? preferredLang,
    int limit = 200,
  }) async {
    final letters = equivalentLettersForSearch(startLetter);
    if (letters.isEmpty) {
      return const [];
    }

    final allowedTypesList = allowedTypes.map((e) => e.toLowerCase()).toList()..sort();
    final allowedCountryCodesList = allowedCountryCodes.map((e) => e.toLowerCase()).toList()..sort();

    final where = <String>[
      'substr(pn.normalized_name, 1, 1) IN (${List.filled(letters.length, '?').join(', ')})',
      if (!allowHistoricalNames) 'pn.lang != ?',
      if (allowedTypes.isNotEmpty) 'p.city_type IN (${List.filled(allowedTypesList.length, '?').join(', ')})',
      if (allowedCountryCodes.isNotEmpty)
        'LOWER(p.country_code) IN (${List.filled(allowedCountryCodesList.length, '?').join(', ')})',
      'COALESCE(p.population, 0) >= ?',
      if (usedPlaceIds.isNotEmpty) 'p.id NOT IN (${List.filled(usedPlaceIds.length, '?').join(', ')})',
    ].join(' AND ');

    final args = <Object?>[
      ...letters,
      if (!allowHistoricalNames) 'old_name',
      if (allowedTypes.isNotEmpty) ...allowedTypesList,
      if (allowedCountryCodes.isNotEmpty) ...allowedCountryCodesList,
      minPopulation,
      if (usedPlaceIds.isNotEmpty) ...usedPlaceIds,
    ];

    final orderBy = <String>[];
    if (preferredLang != null) {
      orderBy.add('''
        CASE
          WHEN pn.lang = ? THEN 0
          WHEN pn.lang IN ('int_name', 'name:en') THEN 1
          ELSE 2
        END
      ''');
      args.add(preferredLang);
    }

    final sql = _localityQuerySql(
      whereClause: where,
      orderByExtra: orderBy.join(',\n        '),
    );

    final rows = await _queryAllDatabases('$sql LIMIT ?', [...args, limit]);

    final seen = <String>{};
    final results = <Locality>[];
    for (final row in rows) {
      final locality = _mapRowToLocality(row, '');
      if (seen.add(locality.id)) {
        results.add(locality);
      }
    }
    return results;
  }

  Future<List<String>> loadAvailableLanguages() async {
    const sql = '''
      SELECT lang
      FROM place_names
      WHERE lang IS NOT NULL
        AND lang NOT IN ('int_name', 'name:en', 'old_name', 'default', '')
      GROUP BY lang
      HAVING COUNT(*) > 50
      ORDER BY lang
    ''';

    final rows = await _queryAllDatabases(sql, []);
    final seen = <String>{};
    for (final row in rows) {
      final lang = row['lang'] as String;
      seen.add(lang);
    }
    return seen.toList(growable: false);
  }

  @disposeMethod
  Future<void> closeVillagesDatabase() async {
    if (_villagesDb != null && _villagesDb!.isOpen) {
      await _villagesDb!.close();
    }
    _villagesDb = null;
  }

  Future<void> dispose() async {
    for (final db in [_citiesDb, _villagesDb]) {
      if (db != null && db.isOpen) {
        await db.close();
      }
    }
    _citiesDb = null;
    _villagesDb = null;
    debugPrint('CitiesRepository databases closed');
  }
}
