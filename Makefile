.PHONY: generate
generate: swiftgen_generate sourcery_generate mockolo_generate ## 各種コード自動生成を実行する

.PHONY: sourcery_generate
sourcery_generate: ## Sourceryによるモック自動生成を行う
	sh ./scripts/run_sourcery.sh

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
		--testable-imports Common; \
	./mockolo \
		--sourcedirs ../LikePicsKit/Sources/Environment \
		--destination ../LikePicsKit/Sources/TestHelper/Mocks/Protocol/Environment.ProtocolMocks.swift \
		--testable-imports Environment; \
	./mockolo \
		--sourcedirs ../LikePicsKit/Sources/Smoothie \
		--destination ../LikePicsKit/Sources/TestHelper/Mocks/Protocol/Smoothie.ProtocolMocks.swift \
		--testable-imports Smoothie; \
	./mockolo \
		--sourcedirs ../LikePicsKit/Sources/ClipCreationFeature \
		--destination ../LikePicsKit/Sources/TestHelper/Mocks/Protocol/ClipCreationFeature.ProtocolMocks.swift \
		--testable-imports ClipCreationFeature;

.PHONY: help
help: ## ヘルプを表示する
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
