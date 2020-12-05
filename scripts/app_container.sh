#!/bin/sh

if [ $# -ne 3 ]; then
  exit 1
fi

BUNDLE_ID=$1;
TARGET_LANG=$2;
IS_EXPORT=$3;
DATA_CONTAINER=`xcrun simctl get_app_container booted ${BUNDLE_ID} data`
TARGET_DIR="./ScreenshotData/AppData/${TARGET_LANG}"

declare -a paths=(
    "${DATA_CONTAINER}/Library/Application Support/.Model_SUPPORT/_EXTERNAL_DATA"
    "${DATA_CONTAINER}/Library/Application Support/Model.sqlite"
    "${DATA_CONTAINER}/Library/Application Support/Model.sqlite-shm"
    "${DATA_CONTAINER}/Library/Application Support/Model.sqlite-wal"
    "${DATA_CONTAINER}/Library/Caches/${BUNDLE_ID}/thumbnails"
    "${DATA_CONTAINER}/Library/Preferences/${BUNDLE_ID}.plist"
)

declare -a targets=(
    "${TARGET_DIR}/Library/Application Support/.Model_SUPPORT/_EXTERNAL_DATA"
    "${TARGET_DIR}/Library/Application Support/Model.sqlite"
    "${TARGET_DIR}/Library/Application Support/Model.sqlite-shm"
    "${TARGET_DIR}/Library/Application Support/Model.sqlite-wal"
    "${TARGET_DIR}/Library/Caches/${BUNDLE_ID}/thumbnails"
    "${TARGET_DIR}/Library/Preferences/${BUNDLE_ID}.plist"
)

case $IS_EXPORT in
"import")
    mkdir -p ${DATA_CONTAINER}/Library/Application\ Support/.Model_SUPPORT;
    mkdir -p ${DATA_CONTAINER}/Library/Caches/${BUNDLE_ID};
    mkdir -p ${DATA_CONTAINER}/Library/Preferences;
    for index in "${!paths[@]}"
    do
        rm -Rf ${paths[index]}
        cp -R "${targets[index]}" "${paths[index]}"
    done
    break
    ;;
"export")
    mkdir -p ${TARGET_DIR}/Library/Application\ Support/.Model_SUPPORT;
    mkdir -p ${TARGET_DIR}/Library/Caches/${BUNDLE_ID};
    mkdir -p ${TARGET_DIR}/Library/Preferences;
    for index in "${!paths[@]}"
    do
        rm -Rf ${targets[index]}
        cp -R "${paths[index]}" "${targets[index]}"
    done
    break
    ;;
esac


