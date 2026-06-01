#!/bin/bash

# Скрипт для рекурсивной загрузки всех данных из публичного каталога Geoapify
# URL: https://www.geoapify.com/data-share/

BASE_URL="https://www.geoapify.com/data-share/"
OUTPUT_DIR="./geoapify_data"

# Цвета для вывода
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Geoapify Data Downloader для macOS${NC}"
echo -e "${GREEN}========================================${NC}"

# Проверка наличия wget (рекомендуемый инструмент)
if command -v wget &> /dev/null; then
    echo -e "${GREEN}✅ Найден wget. Буду использовать его.${NC}"
    USE_WGET=1
elif command -v curl &> /dev/null; then
    echo -e "${YELLOW}⚠️ wget не установлен. Использую curl (но загрузка будет медленнее и без автоматической рекурсии).${NC}"
    echo -e "${YELLOW}   Рекомендую установить wget через Homebrew: brew install wget${NC}"
    USE_WGET=0
else
    echo -e "${RED}❌ Ошибка: ни wget, ни curl не найдены. Установите хотя бы один.${NC}"
    exit 1
fi

# Создаём папку для данных
mkdir -p "$OUTPUT_DIR"
cd "$OUTPUT_DIR" || exit 1

if [ $USE_WGET -eq 1 ]; then
    echo -e "${GREEN}Начинаю рекурсивную загрузку с $BASE_URL ...${NC}"
    # Опции:
    # -r : рекурсивно
    # -np : не подниматься выше родительской директории
    # -nH : не создавать папку с именем хоста
    # --cut-dirs=1 : убрать первый уровень пути (/data-share/)
    # -R "index.html*" : исключить файлы с названием index.html
    # -e robots=off : игнорировать robots.txt
    # --no-check-certificate : если проблемы с сертификатом (опционально)
    wget -r -np -nH --cut-dirs=1 \
         -R "index.html*" \
         -e robots=off \
         --no-check-certificate \
         "$BASE_URL"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Загрузка завершена. Данные в папке: $OUTPUT_DIR${NC}"
    else
        echo -e "${RED}❌ Произошла ошибка при загрузке.${NC}"
        exit 1
    fi
else
    # fallback через curl – скачиваем список файлов, парсим ссылки и качаем по одной
    echo -e "${YELLOW}Использую curl для парсинга и загрузки...${NC}"
    # Сначала скачиваем корневой листинг
    ROOT_LISTING=$(curl -s "$BASE_URL")
    # Извлекаем все ссылки на поддиректории
    SUBDIRS=$(echo "$ROOT_LISTING" | grep -oE 'href="([^"]+/)"' | sed 's/href="//;s/"$//' | grep -v '\.\./' | grep '/$')
    
    for subdir in $SUBDIRS; do
        echo -e "${GREEN}Обработка директории: $subdir${NC}"
        mkdir -p "$subdir"
        # Скачиваем листинг поддиректории
        SUB_LISTING=$(curl -s "${BASE_URL}${subdir}")
        # Извлекаем ссылки на файлы (не на папки)
        FILES=$(echo "$SUB_LISTING" | grep -oE 'href="([^"]+)"' | sed 's/href="//;s/"$//' | grep -v '/$' | grep -v '^\.\./$' | grep -v '^\./$')
        for file in $FILES; do
            echo "  Загрузка: $subdir$file"
            curl -# -o "${subdir}${file}" "${BASE_URL}${subdir}${file}"
        done
    done
    echo -e "${GREEN}✅ Загрузка через curl завершена. Данные в папке: $OUTPUT_DIR${NC}"
fi

# Показываем структуру скачанного
echo -e "${GREEN}Содержимое папки $OUTPUT_DIR:${NC}"
ls -la