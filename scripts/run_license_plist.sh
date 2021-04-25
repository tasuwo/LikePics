#!/bin/sh

if [[ -f "${PODS_ROOT}/LicensePlist/license-plist" ]]; then
  "${PODS_ROOT}/LicensePlist/license-plist" --output-path $PRODUCT_NAME/Resources/Settings.bundle \
                                            --config-path $SRCROOT/license_plist.yml
else
  echo "warning: LicensePlist is not installed. Run 'bundle exec pod install --repo-update' to install it."
fi
