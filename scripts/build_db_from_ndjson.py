#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sqlite3
import json
import os
import sys
import unicodedata
from pathlib import Path
from tqdm import tqdm  # опционально: для прогресс-бара (pip install tqdm)

# Конфигурация
DATA_ROOT = Path("./localities")   # папка с распакованными данными
DB_PATH = "cities.db"
TYPES_TO_KEEP = {"city", "town", "village", "hamlet"}  # какие типы населённых пунктов включать


def normalize_name(name: str) -> str:
    """Нормализация для поиска: только буквы, lower, без диакритик (для всех алфавитов)."""
    if not name:
        return ""
    normalized = name.strip().lower()
    # Универсально убираем диакритику: é->e, ö->o, ё->е, ğ->g, ñ->n и т.д.
    decomposed = unicodedata.normalize("NFKD", normalized)
    without_marks = "".join(
        ch for ch in decomposed
        if unicodedata.category(ch) != "Mn"
    )
    # Оставляем только буквенные символы Unicode.
    letters_only = "".join(ch for ch in without_marks if ch.isalpha())
    return letters_only

def process_ndjson(file_path, conn, cur, stats):
    """Обрабатывает один NDJSON файл, заполняя таблицы"""
    print(f"  → {file_path}")
    with open(file_path, 'r', encoding='utf-8') as f:
        for line_num, line in enumerate(f, 1):
            line = line.strip()
            if not line:
                continue
            try:
                obj = json.loads(line)
            except json.JSONDecodeError as e:
                print(f"    JSON error at line {line_num}: {e}")
                stats['errors'] += 1
                continue

            # Проверяем тип объекта
            obj_type = obj.get('type')
            if obj_type not in TYPES_TO_KEEP:
                continue

            # Уникальный идентификатор
            osm_type = obj.get('osm_type', 'node')
            osm_id = obj.get('osm_id')
            if not osm_id:
                continue
            place_id = f"{osm_type}/{osm_id}"

            # Основное название
            name = obj.get('name', '').strip()
            if not name:
                # пробуем взять из other_names:name
                other = obj.get('other_names', {})
                if isinstance(other, dict):
                    name = other.get('name', '').strip()
                if not name:
                    continue  # безымянный объект пропускаем

            # Координаты
            loc = obj.get('location')
            if isinstance(loc, list) and len(loc) >= 2:
                lon, lat = loc[0], loc[1]
            else:
                lon = lat = None

            # Адресные поля
            addr = obj.get('address', {})
            country_code = addr.get('country_code', '')
            country = addr.get('country', '')
            state = addr.get('state', '')
            population = obj.get('population')
            display_name = obj.get('display_name', '')

            # Вставка в places
            try:
                cur.execute("""
                    INSERT OR REPLACE INTO places
                    (id, name, display_name, lat, lon, population, country_code, country, state, city_type)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, (
                    place_id, name, display_name, lat, lon, population,
                    country_code, country, state, obj_type
                ))
                stats['places_inserted'] += 1
            except Exception as e:
                print(f"    DB insert error (places): {e}")
                stats['errors'] += 1
                continue

            # --- Сбор всех вариантов названий ---
            all_names = set()
            # Основное название
            if name:
                all_names.add(('default', name))

            # other_names
            other = obj.get('other_names', {})
            if isinstance(other, dict):
                for key, val in other.items():
                    if val and isinstance(val, str):
                        val = val.strip()
                        # ключи бывают: name:en, name:ru, int_name, alt_name, old_name и т.д.
                        if key.startswith('name:'):
                            lang = key[5:]
                        elif key in ('int_name', 'alt_name', 'old_name'):
                            lang = key
                        else:
                            lang = 'other'
                        all_names.add((lang, val))
            # alt_name на верхнем уровне (вне other_names)
            if 'alt_name' in obj and obj['alt_name']:
                alt = obj['alt_name'].strip()
                if alt:
                    all_names.add(('alt_name', alt))
            # old_name (редко)
            if 'old_name' in obj and obj['old_name']:
                old = obj['old_name'].strip()
                if old:
                    all_names.add(('old_name', old))

            # Вставка в place_names (игнорируем дубликаты)
            for lang, n in all_names:
                if len(n) > 0:
                    try:
                        normalized_n = normalize_name(n)
                        cur.execute(
                            """
                            INSERT OR IGNORE INTO place_names (place_id, name, normalized_name, lang)
                            VALUES (?, ?, ?, ?)
                            """,
                            (place_id, n, normalized_n, lang),
                        )
                        stats['names_inserted'] += 1
                    except Exception as e:
                        print(f"    DB insert error (place_names): {e}")
                        stats['errors'] += 1

            # Коммитим каждые 5000 записей, чтобы не раздувать транзакцию
            if stats['places_inserted'] % 5000 == 0:
                conn.commit()

        # Конец файла
        conn.commit()
        stats['files_processed'] += 1

def main():
    if not DATA_ROOT.exists():
        print(f"Ошибка: папка {DATA_ROOT} не найдена.")
        print("Убедитесь, что вы распаковали архивы в ./geoapify_data/localities")
        sys.exit(1)

    # Удаляем старую БД, если есть
    if os.path.exists(DB_PATH):
        os.remove(DB_PATH)

    conn = sqlite3.connect(DB_PATH)
    conn.execute("PRAGMA journal_mode=WAL")
    conn.execute("PRAGMA synchronous=NORMAL")
    cur = conn.cursor()

    # Создаём таблицы
    cur.execute("""
        CREATE TABLE places (
            id TEXT PRIMARY KEY,
            name TEXT,
            display_name TEXT,
            lat REAL,
            lon REAL,
            population INTEGER,
            country_code TEXT,
            country TEXT,
            state TEXT,
            city_type TEXT
        )
    """)
    cur.execute("""
        CREATE TABLE place_names (
            place_id TEXT,
            name TEXT COLLATE NOCASE,
            normalized_name TEXT,
            lang TEXT,
            PRIMARY KEY (place_id, name, lang)
        )
    """)
    conn.commit()

    # Статистика
    stats = {
        'files_processed': 0,
        'places_inserted': 0,
        'names_inserted': 0,
        'errors': 0,
    }

    # Обходим все NDJSON файлы
    ndjson_files = list(DATA_ROOT.rglob("*.ndjson"))
    print(f"Найдено NDJSON-файлов: {len(ndjson_files)}")
    for file_path in ndjson_files:
        process_ndjson(file_path, conn, cur, stats)
        # Небольшой отчёт после каждого файла
        print(f"    Всего мест: {stats['places_inserted']}, вариантов названий: {stats['names_inserted']}, ошибок: {stats['errors']}")

    # Создаём индекс для быстрого поиска по названиям
    print("\nСоздаём индекс (может занять несколько минут)...")
    cur.execute("CREATE INDEX idx_place_names_name ON place_names(name COLLATE NOCASE);")
    cur.execute("CREATE INDEX idx_place_names_normalized_name ON place_names(normalized_name);")
    conn.commit()

    # Оптимизируем базу
    print("Оптимизация базы (VACUUM)...")
    conn.execute("VACUUM")
    conn.close()

    print("\n✅ Готово!")
    print(f"   База данных: {DB_PATH}")
    print(f"   Обработано файлов: {stats['files_processed']}")
    print(f"   Уникальных мест: {stats['places_inserted']}")
    print(f"   Всего вариантов названий: {stats['names_inserted']}")
    print(f"   Ошибок: {stats['errors']}")

if __name__ == "__main__":
    main()
