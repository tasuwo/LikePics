#!/bin/sh

if [[ ${CONFIGURATION} == "DebugDev" ]] && [[ ! -z ${FASTLANE_SNAPSHOT} ]]; then
    bundlePath="${CONFIGURATION_BUILD_DIR}/${CONTENTS_FOLDER_PATH}"
    cp -R "${SRCROOT}/ScreenshotData/AppData" $bundlePath
fi
