import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/locality.dart';
import '../utils/utils.dart';

@singleton
class CitiesRepository {
  Database? _db;

  Future<Database> _database() async {
    if (_db != null) {
      return _db!;
    }

    final appDocumentsDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(appDocumentsDir.path, 'cities.db');

    _db = await openDatabase(
      dbPath,
      readOnly: true,
      singleInstance: true,
    );

    return _db!;
  }

  Future<Locality?> findLocalityByName(String rawQuery) async {
    final query = rawQuery.trim();
    if (query.isEmpty) {
      return null;
    }

    final db = await _database();
    final normalizedQuery = normalizeCityNameForSearch(query);

    if (normalizedQuery.isNotEmpty) {
      final normalizedRows = await db.rawQuery(
        '''
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
        WHERE pn.normalized_name = ?
        ORDER BY
          CASE p.city_type
            WHEN 'city' THEN 0
            WHEN 'town' THEN 1
            WHEN 'village' THEN 2
            WHEN 'hamlet' THEN 3
            ELSE 4
          END,
          COALESCE(p.population, 0) DESC
        LIMIT 1
        ''',
        [normalizedQuery],
      );

      if (normalizedRows.isNotEmpty) {
        return _mapRowToLocality(normalizedRows.first, query);
      }
    }

    final compatibilityNormalizedQuery = compatibilityKey(query);
    if (compatibilityNormalizedQuery.isNotEmpty &&
        compatibilityNormalizedQuery != normalizedQuery) {
      final compatibilityRows = await db.rawQuery(
        '''
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
        WHERE pn.normalized_name = ?
        ORDER BY
          CASE p.city_type
            WHEN 'city' THEN 0
            WHEN 'town' THEN 1
            WHEN 'village' THEN 2
            WHEN 'hamlet' THEN 3
            ELSE 4
          END,
          COALESCE(p.population, 0) DESC
        LIMIT 1
        ''',
        [compatibilityNormalizedQuery],
      );

      if (compatibilityRows.isNotEmpty) {
        return _mapRowToLocality(compatibilityRows.first, query);
      }
    }

    final variants = buildCityQueryVariants(query);
    Map<String, Object?>? row;

    for (final variant in variants) {
      final rows = await db.rawQuery(
        '''
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
        WHERE pn.name = ? COLLATE NOCASE
        ORDER BY
          CASE p.city_type
            WHEN 'city' THEN 0
            WHEN 'town' THEN 1
            WHEN 'village' THEN 2
            WHEN 'hamlet' THEN 3
            ELSE 4
          END,
          COALESCE(p.population, 0) DESC
        LIMIT 1
        ''',
        [variant],
      );
      if (rows.isNotEmpty) {
        row = rows.first;
        break;
      }
    }

    if (row == null) {
      return null;
    }

    return _mapRowToLocality(row, query);
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
    final db = await _database();
    final rows = await db.rawQuery(
      '''
      SELECT country_code, country
      FROM places
      WHERE country_code IS NOT NULL
        AND TRIM(country_code) <> ''
      GROUP BY country_code, country
      ORDER BY country ASC
      ''',
    );

    return rows
        .map(
          (row) => (
            (row['country_code'] as String? ?? '').toLowerCase(),
            row['country'] as String? ?? '',
          ),
        )
        .where((it) => it.$1.isNotEmpty)
        .toList(growable: false);
  }

  Future<List<Locality>> findCandidatesByStartLetter({
    required String startLetter,
    required Set<String> allowedTypes,
    required bool allowHistoricalNames,
    required int minPopulation,
    required Set<String> usedPlaceIds,
    String? preferredLang,
    int limit = 200,
  }) async {
    final db = await _database();
    final letters = equivalentLettersForSearch(startLetter);
    if (letters.isEmpty) {
      return const [];
    }
    final allowedTypesList = allowedTypes.map((e) => e.toLowerCase()).toList()
      ..sort();

    final where = <String>[
      'substr(pn.normalized_name, 1, 1) IN (${List.filled(letters.length, '?').join(', ')})',
      if (!allowHistoricalNames) 'pn.lang != ?',
      if (allowedTypes.isNotEmpty)
        'p.city_type IN (${List.filled(allowedTypesList.length, '?').join(', ')})',
      'COALESCE(p.population, 0) >= ?',
      if (usedPlaceIds.isNotEmpty)
        'p.id NOT IN (${List.filled(usedPlaceIds.length, '?').join(', ')})',
    ].join(' AND ');

    final args = <Object?>[
      ...letters,
      if (!allowHistoricalNames) 'old_name',
      if (allowedTypes.isNotEmpty) ...allowedTypesList,
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
    orderBy.addAll([
      '''
      CASE p.city_type
        WHEN 'city' THEN 0
        WHEN 'town' THEN 1
        WHEN 'village' THEN 2
        WHEN 'hamlet' THEN 3
        ELSE 4
      END
      ''',
      'COALESCE(p.population, 0) DESC',
    ]);

    final rows = await db.rawQuery(
      '''
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
      WHERE $where
      ORDER BY
        ${orderBy.join(',\n        ')}
      LIMIT ?
      ''',
      [...args, limit],
    );

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

  @disposeMethod
  Future<void> dispose() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
      debugPrint('CitiesRepository database closed');
    }
  }
}
