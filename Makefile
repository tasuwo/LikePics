.PHONY: install
install: ## ライブラリ群をインストールする
	bundle exec pod install

.PHONY: generate
generate: license_generate swiftgen_generate sourcery_generate mockolo_generate format ## 各種コード自動生成を実行する

.PHONY: license_generate
license_generate: ## ライセンスを自動生成する
	 ./Pods/LicensePlist/license-plist \
		 --output-path ./LikePics/Resources/Settings.bundle \
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
		--sources ./LikePicsKit/Sources/Domain \
		--templates ./templates \
		--output ./LikePicsKit/Sources/TestHelper/Mocks/Struct/Domain.AutoDefaultValue.generated.swift \
		--args testable_import=Domain
	./Pods/Sourcery/bin/sourcery \
		--sources ./LikePicsKit/Sources/Persistence \
		--templates ./templates \
		--output ./LikePicsKit/Sources/TestHelper/Mocks/Struct/Persistence.AutoDefaultValue.generated.swift \
		--args testable_import=Persistence
	./Pods/Sourcery/bin/sourcery \
		--sources ./LikePicsKit/Sources/LikePicsUIKit \
		--templates ./templates \
		--output ./LikePicsKit/Sources/TestHelper/Mocks/Struct/LikePicsUIKit.AutoDefaultValue.generated.swift \
		--args testable_import=LikePicsUIKit

.PHONY: mockolo_generate
mockolo_generate: ## mockoloによるモック自動生成を行う
	cd BuildTools; \
	./mockolo \
		--sourcedirs ../LikePicsKit/Sources/Persistence \
		--destination ../LikePicsKit/Sources/TestHelper/Mocks/Protocol/Persistence.ProtocolMocks.swift \
		--testable-imports Persistence; \
	./mockolo \
		--sourcedirs ../LikePicsKit/Sources/Domain \
		--destination ../LikePicsKit/Sources/TestHelper/Mocks/Protocol/Domain.ProtocolMocks.swift \
		--testable-imports Domain; \
	./mockolo \
		--sourcedirs ../LikePicsKit/Sources/LikePicsUIKit \
		--destination ../LikePicsKit/Sources/TestHelper/Mocks/Protocol/LikePicsUIKit.ProtocolMocks.swift \
		--testable-imports LikePicsUIKit; \
	./mockolo \
		--sourcedirs ../LikePicsKit/Sources/Common \
		--destination ../LikePicsKit/Sources/TestHelper/Mocks/Protocol/Common.ProtocolMocks.swift \
		--testable-imports Common;

.PHONY: lint
lint: swiftlint_lint ## 各種Linterを実行する

.PHONY: swiftlint_lint
swiftlint_lint: ## SwiftLintによるリントを実行する
	Pods/SwiftLint/swiftlint

.PHONY: format
format: swiftformat_format ## 各種フォーマッターを実行する

.PHONY: swiftformat_format
swiftformat_format: ## SwiftFormatによるフォーマットを実行する
	Pods/SwiftFormat/CommandLineTool/swiftformat --config ./.swiftformat ./

.PHONY: extract_app_data_as_ja
extract_app_data_as_ja: ## 起動中のSimulatorからAppDataをDLする
	./scripts/app_container.sh net.tasuwo.TBox.dev ja-JP export

.PHONY: help
help: ## ヘルプを表示する
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
