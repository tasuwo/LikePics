#!/bin/sh

if [[ -f "${PROJECT_DIR}/Pods//SwiftLint/swiftlint" ]]; then
  "${PROJECT_DIR}/Pods/SwiftLint/swiftlint"
else
  echo "warning: SwiftLint is not installed. Run 'bundle exec pod install --repo-update' to install it."
fi
