#!/bin/sh

if [[ -f "${PODS_ROOT}/SwiftLint/swiftlint" ]]; then
  "${PODS_ROOT}/SwiftLint/swiftlint"
else
  echo "warning: SwiftLint is not installed. Run 'bundle exec pod install --repo-update' to install it."
fi
