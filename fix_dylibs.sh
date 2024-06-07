#!/bin/bash

PROJECT_NAME=$1
CONFIG=$2
OUTPUT_DIR=$3
LIBS_DIR="$OUTPUT_DIR/libs"

mkdir -p "$LIBS_DIR"

TMP_BINARY="$OUTPUT_DIR/tmp_$PROJECT_NAME"
BINARY="$OUTPUT_DIR/$PROJECT_NAME"

cp "$BINARY" "$TMP_BINARY"

echo "Starting dependency copy and relinking process for $TMP_BINARY"

change_install_names() {
    local binary=$1

    otool -L "$binary" | grep -o '/.*dylib' | while read -r dylib; do
        if [[ "$dylib" == /usr/lib/* || "$dylib" == /System/Library/* ]]; then
            continue
        fi

        local dylib_basename=$(basename "$dylib")
        echo "Changing install name from $dylib to @executable_path/libs/$dylib_basename in $binary"
        install_name_tool -change "$dylib" "@executable_path/libs/$dylib_basename" "$binary"

        # Проверка успешности изменения
        if ! otool -L "$binary" | grep -q "@executable_path/libs/$dylib_basename"; then
            echo "Error: Failed to change install name for $dylib in $binary"
        fi
    done
}

copy_and_change_dependencies() {
    local binary=$1

    otool -L "$binary" | grep -o '/.*dylib' | while read -r dylib; do
        if [[ "$dylib" == /usr/lib/* || "$dylib" == /System/Library/* ]]; then
            continue
        fi

        local dylib_basename=$(basename "$dylib")

        # Если библиотека уже скопирована, пропускаем её
        if [[ -f "$LIBS_DIR/$dylib_basename" ]]; then
            continue
        fi

        echo "Copying $dylib to $LIBS_DIR"
        cp "$dylib" "$LIBS_DIR"

        local copied_dylib="$LIBS_DIR/$dylib_basename"

        # Проверка успешности копирования
        if [[ ! -f "$copied_dylib" ]]; then
            echo "Error: Failed to copy $dylib to $LIBS_DIR"
            continue
        fi

        # Рекурсивно копируем зависимости этой библиотеки
        copy_and_change_dependencies "$copied_dylib"

        # Изменяем ссылки на библиотеки
        change_install_names "$copied_dylib"
    done
}

# Копируем зависимости для бинарного файла
copy_and_change_dependencies "$TMP_BINARY"

# Изменяем ссылки для основного бинарного файла
change_install_names "$TMP_BINARY"

mv "$TMP_BINARY" "$BINARY"

echo "Dependency copy and relinking process completed for $BINARY"

# Проверка окончательных ссылок для бинарного файла
echo "Final linked libraries for $BINARY:"
otool -L "$BINARY"

# Проверка окончательных ссылок для каждой библиотеки в LIBS_DIR
for lib in "$LIBS_DIR"/*.dylib; do
    echo "Final linked libraries for $lib:"
    otool -L "$lib"
done