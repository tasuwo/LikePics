//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
@testable import Domain
@testable import Persistence
@testable import TestHelper
import XCTest

class ClipReferencesIntegrityValidationServiceTest: XCTestCase {
    var service: ClipReferencesIntegrityValidationService!
    var clipStorage: ClipStorageProtocolMock!
    var referenceClipStorage: ReferenceClipStorageProtocolMock!
    var queue: StorageCommandQueueMock!

    override func setUp() {
        clipStorage = ClipStorageProtocolMock()
        referenceClipStorage = ReferenceClipStorageProtocolMock()
        queue = StorageCommandQueueMock()
        service = ClipReferencesIntegrityValidationService(clipStorage: clipStorage,
                                                           referenceClipStorage: referenceClipStorage,
                                                           commandQueue: queue,
                                                           lock: NSRecursiveLock(),
                                                           logger: RootLogger(loggers: []))

        queue.syncHandler = { $0() }
        queue.syncBlockHandler = { try $0() }
        clipStorage.readAllClipsHandler = { .success([]) }
        clipStorage.readAllTagsHandler = { .success([]) }
        referenceClipStorage.readAllTagsHandler = { .success([]) }
        referenceClipStorage.updateTagHandler = { _, _ in .success(()) }
        referenceClipStorage.createHandler = { _ in .success(()) }
        referenceClipStorage.deleteTagsHandler = { _ in .success(()) }
    }

    func test_validateAndFixIntegrityIfNeeded_タグ_タグの整合性がとれている場合_何もしない() {
        clipStorage.readAllTagsHandler = {
            return .success([
                .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!, name: "hoge"),
                .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!, name: "fuga"),
                .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!, name: "piyo"),
            ])
        }
        referenceClipStorage.readAllTagsHandler = {
            return .success([
                .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!, name: "hoge", isDirty: false),
                .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!, name: "fuga", isDirty: false),
                .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!, name: "piyo", isDirty: false),
            ])
        }

        service.validateAndFixIntegrityIfNeeded()

        XCTAssertEqual(referenceClipStorage.beginTransactionCallCount, 1)
        XCTAssertEqual(referenceClipStorage.updateTagCallCount, 0)
        XCTAssertEqual(referenceClipStorage.deleteTagsCallCount, 0)
        XCTAssertEqual(referenceClipStorage.createCallCount, 0)
        XCTAssertEqual(referenceClipStorage.commitTransactionCallCount, 1)
        XCTAssertEqual(referenceClipStorage.cancelTransactionIfNeededCallCount, 0)
    }

    func test_validateAndFixIntegrityIfNeeded_タグ_名前が違うタグが存在し_Dirtyフラグが立っている場合_何もしない() {
        clipStorage.readAllTagsHandler = {
            return .success([
                .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!, name: "hoge"),
                .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!, name: "fuga"),
                .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!, name: "piyo"),
                .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E54")!, name: "pue"),
            ])
        }
        referenceClipStorage.readAllTagsHandler = {
            return .success([
                .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!, name: "hoge", isDirty: false),
                .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!, name: "poe", isDirty: true),
                .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!, name: "piyo", isDirty: false),
                .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E54")!, name: "wwww", isDirty: true),
            ])
        }

        service.validateAndFixIntegrityIfNeeded()

        XCTAssertEqual(referenceClipStorage.beginTransactionCallCount, 1)
        XCTAssertEqual(referenceClipStorage.updateTagCallCount, 0)
        XCTAssertEqual(referenceClipStorage.deleteTagsCallCount, 0)
        XCTAssertEqual(referenceClipStorage.createCallCount, 0)
        XCTAssertEqual(referenceClipStorage.commitTransactionCallCount, 1)
        XCTAssertEqual(referenceClipStorage.cancelTransactionIfNeededCallCount, 0)
    }

    func test_validateAndFixIntegrityIfNeeded_タグ_名前が違うタグが存在し_Dirtyフラグが立っていない場合_整合のためにタグを更新する() {
        clipStorage.readAllTagsHandler = {
            return .success([
                .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!, name: "hoge"),
                .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!, name: "fuga"),
                .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!, name: "piyo"),
                .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E54")!, name: "pue"),
            ])
        }
        referenceClipStorage.readAllTagsHandler = {
            return .success([
                .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!, name: "hoge", isDirty: false),
                .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!, name: "poe", isDirty: false),
                .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!, name: "piyo", isDirty: false),
                .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E54")!, name: "wwww", isDirty: false),
            ])
        }
        referenceClipStorage.updateTagHandler = { tagId, name in
            switch tagId {
            case UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!:
                XCTAssertEqual(name, "fuga")

            case UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E54")!:
                XCTAssertEqual(name, "pue")

            default:
                XCTFail("予期しないタグの更新が発生した")
            }

            return .success(())
        }

        service.validateAndFixIntegrityIfNeeded()

        XCTAssertEqual(referenceClipStorage.beginTransactionCallCount, 1)
        XCTAssertEqual(referenceClipStorage.updateTagCallCount, 2)
        XCTAssertEqual(referenceClipStorage.deleteTagsCallCount, 0)
        XCTAssertEqual(referenceClipStorage.createCallCount, 0)
        XCTAssertEqual(referenceClipStorage.commitTransactionCallCount, 1)
        XCTAssertEqual(referenceClipStorage.cancelTransactionIfNeededCallCount, 0)
    }

    func test_validateAndFixIntegrityIfNeeded_タグ_タグが不足している場合_整合のためにタグを追加する() {
        clipStorage.readAllTagsHandler = {
            return .success([
                .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!, name: "hoge"),
                .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!, name: "fuga"),
                .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!, name: "piyo"),
                .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E54")!, name: "pon"),
            ])
        }
        referenceClipStorage.readAllTagsHandler = {
            return .success([
                .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!, name: "hoge", isDirty: false),
                .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!, name: "piyo", isDirty: false),
            ])
        }
        referenceClipStorage.createHandler = { tag in
            switch tag.id {
            case UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!:
                XCTAssertEqual(tag, .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!, name: "fuga", isDirty: false))

            case UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E54")!:
                XCTAssertEqual(tag, .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E54")!, name: "pon", isDirty: false))

            default:
                XCTFail("予期しないタグの追加が発生した")
            }

            return .success(())
        }

        service.validateAndFixIntegrityIfNeeded()

        XCTAssertEqual(referenceClipStorage.beginTransactionCallCount, 1)
        XCTAssertEqual(referenceClipStorage.updateTagCallCount, 0)
        XCTAssertEqual(referenceClipStorage.deleteTagsCallCount, 0)
        XCTAssertEqual(referenceClipStorage.createCallCount, 2)
        XCTAssertEqual(referenceClipStorage.commitTransactionCallCount, 1)
        XCTAssertEqual(referenceClipStorage.cancelTransactionIfNeededCallCount, 0)
    }

    func test_validateAndFixIntegrityIfNeeded_タグ_タグが余分に存在し_Dirtyフラグが立っている場合_何もしない() {
        clipStorage.readAllTagsHandler = {
            return .success([
                .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!, name: "hoge"),
                .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!, name: "piyo"),
            ])
        }
        referenceClipStorage.readAllTagsHandler = {
            return .success([
                .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E50")!, name: "pue", isDirty: true),
                .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!, name: "hoge", isDirty: false),
                .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!, name: "fuga", isDirty: true),
                .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!, name: "piyo", isDirty: false),
                .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E54")!, name: "pon", isDirty: true),
            ])
        }

        service.validateAndFixIntegrityIfNeeded()

        XCTAssertEqual(referenceClipStorage.beginTransactionCallCount, 1)
        XCTAssertEqual(referenceClipStorage.updateTagCallCount, 0)
        XCTAssertEqual(referenceClipStorage.deleteTagsCallCount, 0)
        XCTAssertEqual(referenceClipStorage.createCallCount, 0)
        XCTAssertEqual(referenceClipStorage.commitTransactionCallCount, 1)
        XCTAssertEqual(referenceClipStorage.cancelTransactionIfNeededCallCount, 0)
    }

    func test_validateAndFixIntegrityIfNeeded_タグ_タグが余分に存在し_Dirtyフラグが立っていない場合_整合のためにタグを削除する() {
        clipStorage.readAllTagsHandler = {
            return .success([
                .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!, name: "hoge"),
                .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!, name: "piyo"),
            ])
        }
        referenceClipStorage.readAllTagsHandler = {
            return .success([
                .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E50")!, name: "pue", isDirty: false),
                .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!, name: "hoge", isDirty: false),
                .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!, name: "fuga", isDirty: false),
                .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!, name: "piyo", isDirty: false),
                .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E54")!, name: "pon", isDirty: false),
            ])
        }
        referenceClipStorage.deleteTagsHandler = { tagIds in
            XCTAssertEqual(Set(tagIds), Set([
                UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E50")!,
                UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!,
                UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E54")!
            ]))
            return .success(())
        }

        service.validateAndFixIntegrityIfNeeded()

        XCTAssertEqual(referenceClipStorage.beginTransactionCallCount, 1)
        XCTAssertEqual(referenceClipStorage.updateTagCallCount, 0)
        XCTAssertEqual(referenceClipStorage.deleteTagsCallCount, 1)
        XCTAssertEqual(referenceClipStorage.createCallCount, 0)
        XCTAssertEqual(referenceClipStorage.commitTransactionCallCount, 1)
        XCTAssertEqual(referenceClipStorage.cancelTransactionIfNeededCallCount, 0)
    }
}
