#!/bin/sh

VERSION="v2.0.0"

if [[ ! -f "./templates/AutoDefaultValue.swifttemplate" ]]; then
    curl -o "./templates/AutoDefaultValue.swifttemplate" \
        "https://raw.githubusercontent.com/tasuwo/SwiftTemplates/${VERSION}/Templates/AutoDefaultValue/AutoDefaultValue.swifttemplate"
fi

if [[ ! -f "./templates/AutoDefaultValue.swift" ]]; then
    curl -o "./templates/AutoDefaultValue.swift" \
        "https://raw.githubusercontent.com/tasuwo/SwiftTemplates/${VERSION}/Templates/AutoDefaultValue/AutoDefaultValue.swift"
fi

if [[ ! -f "./templates/AutoDefaultValue.extension.swift" ]]; then
    curl -o "./templates/AutoDefaultValue.extension.swift" \
        "https://raw.githubusercontent.com/tasuwo/SwiftTemplates/${VERSION}/Templates/AutoDefaultValue/AutoDefaultValue.extension.swift"
fi

if ! command -v sourcery >/dev/null 2>&1; then
    brew install sourcery
fi
sourcery
