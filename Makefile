.PHONY: install
install: ## ライブラリ群をインストールする
	bundle exec pod install && carthage update --use-xcframeworks --cache-builds --no-use-binaries --platform iOS

.PHONY: update_buildtools
update_buildtools: ## ビルド用ツール群を更新する
	cd BuildTools; swift package update

.PHONY: generate
generate: license_generate swiftgen_generate sourcery_generate mockolo_generate format ## 各種コード自動生成を実行する

.PHONY: license_generate
license_generate: ## ライセンスを自動生成する
	 ./Pods/LicensePlist/license-plist \
		 --output-path ./TBox/Resources/Settings.bundle \
		 --config-path ./license_plist.yml

.PHONY: swiftgen_generate
swiftgen_generate: ## SwiftGenによるコード自動生成を実行する
	./Pods/SwiftGen/bin/swiftgen

.PHONY: sourcery_generate
sourcery_generate: ## Sourceryによるモック自動生成を行う
	if [[ ! -f "./templates/AutoDefaultValue.swifttemplate" ]] || [[ ! -f "./templates/AutoDefaultValue.extension.swifttemplate" ]]; then \
	curl -o "./templates/AutoDefaultValue.swifttemplate" \
		"https://raw.githubusercontent.com/tasuwo/SwiftTemplates/master/Templates/AutoDefaultValue.swifttemplate"; \
	curl -o "./templates/AutoDefaultValue.extension.swifttemplate" \
		"https://raw.githubusercontent.com/tasuwo/SwiftTemplates/master/Templates/AutoDefaultValue.extension.swifttemplate"; \
	fi
	./Pods/Sourcery/bin/sourcery \
		--sources ./Domain \
		--templates ./templates \
		--output ./TestHelper/Mocks/Struct/Domain.AutoDefaultValue.generated.swift \
		--args testable_import=Domain
	./Pods/Sourcery/bin/sourcery \
		--sources ./Persistence \
		--templates ./templates \
		--output ./TestHelper/Mocks/Struct/Persistence.AutoDefaultValue.generated.swift \
		--args testable_import=Persistence
	./Pods/Sourcery/bin/sourcery \
		--sources ./TBoxUIKit \
		--templates ./templates \
		--output ./TestHelper/Mocks/Struct/TBoxUIKit.AutoDefaultValue.generated.swift \
		--args testable_import=TBoxUIKit

.PHONY: mockolo_generate
mockolo_generate: ## mockoloによるモック自動生成を行う
	cd BuildTools; \
	./mockolo \
		--sourcedirs ../Persistence \
		--destination ../TestHelper/Mocks/Protocol/Persistence.ProtocolMocks.swift \
		--testable-imports Persistence; \
	./mockolo \
		--sourcedirs ../Domain \
		--destination ../TestHelper/Mocks/Protocol/Domain.ProtocolMocks.swift \
		--testable-imports Domain; \
	./mockolo \
		--sourcedirs ../TBoxUIKit \
		--destination ../TestHelper/Mocks/Protocol/TBoxUIKit.ProtocolMocks.swift \
		--testable-imports TBoxUIKit; \
	./mockolo \
		--sourcedirs ../Common \
		--destination ../TestHelper/Mocks/Protocol/Common.ProtocolMocks.swift \
		--testable-imports Common;

.PHONY: lint
lint: swiftlint_lint ## 各種Linterを実行する

.PHONY: swiftlint_lint
swiftlint_lint: ## SwiftLintによるリントを実行する
	cd BuildTools; cp ../.swiftlint.yml ./; swift run -c release swiftlint; rm .swiftlint.yml

.PHONY: format
format: swiftformat_format ## 各種フォーマッターを実行する

.PHONY: swiftformat_format
swiftformat_format: ## SwiftFormatによるフォーマットを実行する
	cd BuildTools; swift run -c release swiftformat --config ../.swiftformat ../

.PHONY: extract_app_data_as_ja
extract_app_data_as_ja: ## 起動中のSimulatorからAppDataをDLする
	./scripts/app_container.sh net.tasuwo.TBox.dev ja-JP export

.PHONY: overwrite_app_data_ja
overwrite_app_data_ja: ## 起動中のSimulatorにAppDataを受け渡す
	xcrun simctl terminate booted net.tasuwo.TBox.dev
	./scripts/app_container.sh net.tasuwo.TBox.dev ja-JP import
	xcrun simctl launch booted net.tasuwo.TBox.dev

.PHONY: extract_app_data_as_en
extract_app_data_as_en: ## 起動中のSimulatorからAppDataをDLする
	./scripts/app_container.sh net.tasuwo.TBox.dev en-US export

.PHONY: overwirte_app_data_en
overwirte_app_data_en: ## 起動中のSimulatorにAppDataを受け渡す
	xcrun simctl terminate booted net.tasuwo.TBox.dev
	./scripts/app_container.sh net.tasuwo.TBox.dev en-US import
	xcrun simctl launch booted net.tasuwo.TBox.dev

.PHONY: help
help: ## ヘルプを表示する
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
