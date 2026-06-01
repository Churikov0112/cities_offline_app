#!/bin/bash
# 
# Этот скрипт собирает нужную сборку (apk, appbundle) под Android.

# Установка переменных по умолчанию
default_package_type="apk"
valid_package_types=("apk" "appbundle")

# Функция для вывода справки
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "OPTIONS:"
    echo "  --package_type=<type>            Тип пакета. Default: apk"
    echo "                                   Доступные значения: $(IFS=', '; echo "${valid_package_types[*]}")"
    echo
    echo "  -h, --help                       Показать справку"
    echo
    echo
    echo "Примеры:"
    for package_type in "${valid_package_types[@]}"; do
        echo "  $0 --package_type=$package_type"
    done
}

# Функция для парсинга аргументов командной строки
parse_args() {
    if [[ $# -eq 0 ]]; then
        show_help
        exit 1
    fi

    package_type="$default_package_type"  # Значение по умолчанию

    for arg in "$@"; do
        case $arg in
            --package_type=*)
                package_type="${arg#*=}"
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
        esac
    done

    # Проверка корректности значения package_type
    if [[ ! " ${valid_package_types[*]} " =~ " $package_type " ]]; then
        echo "Error: The value for --package_type is incorrect"
        echo "Available values: $(IFS=', '; echo "${valid_package_types[*]}")"
        exit 1
    fi
}

# Функция для извлечения версии, номера сборки и имени проекта из pubspec.yaml
parse_pubspec() {
    local version=$(grep '^version:' pubspec.yaml | awk '{print $2}')
    app_version=$(echo "$version" | cut -d'+' -f1)
    app_build_number=$(echo "$version" | cut -d'+' -f2)

    app_name=$(grep '^name:' pubspec.yaml | awk '{print $2}')
    if [[ -z "$app_name" ]]; then
        echo "Error: Не удалось определить имя проекта (name:) из pubspec.yaml"
        exit 1
    fi
}

# Функция для переименования релизного файла
rename_release_file() {
    local base_path=""
    local src_file_name=""
    local dest_file_name=""

    if [[ "$package_type" == "apk" ]]; then
        base_path="build/app/outputs/flutter-apk"
        src_file_name="app-release.apk"
        dest_file_name="${app_name}-${app_version}+${app_build_number}.apk"
    elif [[ "$package_type" == "appbundle" ]]; then
        base_path="build/app/outputs/bundle/release"
        src_file_name="app-release.aab"
        dest_file_name="${app_name}-${app_version}+${app_build_number}.aab"
    else
        echo "Error: unsupported package type $package_type"
        exit 1
    fi

    mv "$base_path/$src_file_name" "$base_path/$dest_file_name"
    echo "✅ Файл успешно переименован в: $base_path/$dest_file_name"
}

# Функция для выполнения команды flutter или fvm flutter
run_flutter_command() {
    local flutter_build_command=(
        build "$package_type" \
        --build-number="$app_build_number" \
        --build-name="$app_version+$app_build_number" \
        --no-pub
    )

    local flutter_commands=("fvm flutter" "flutter")
    
    for cmd in "${flutter_commands[@]}"; do
        if $cmd --version &> /dev/null; then
            $cmd "${flutter_build_command[@]}"
            return 
        fi
    done

    echo "None of the commands were found: ${flutter_commands[*]}. Please check if Flutter is installed."
    exit 1
}

# Основная логика
main() {
    parse_args "$@"      # Парсинг аргументов
    parse_pubspec        # Чтение name, version и build number
    run_flutter_command  # Сборка проекта
    rename_release_file  # Переименование итогового файла
}

# Запуск
main "$@"
