set -euo pipefail

SCRIPT_DIR=$(cd $(dirname $0);pwd)
CARTHAGE_DIR=${SCRIPT_DIR}/Carthage
if [ ! -d ${CARTHAGE_DIR} ]; then
  mkdir ${CARTHAGE_DIR}
fi

export XCODE_XCCONFIG_FILE=${CARTHAGE_DIR}/workaround.xcconfig
echo 'APPLICATION_EXTENSION_API_ONLY=YES' > ${XCODE_XCCONFIG_FILE}

carthage $@

