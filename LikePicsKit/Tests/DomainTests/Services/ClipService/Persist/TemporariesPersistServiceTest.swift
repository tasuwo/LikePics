//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
@testable import Domain
@testable import TestHelper
import XCTest

class TemporariesPersistServiceTests: XCTestCase {
    enum TestError: Error { case dummy }

    var service: TemporariesPersistService!
    var temporaryClipStorage: TemporaryClipStorageProtocolMock!
    var temporaryImageStorage: TemporaryImageStorageProtocolMock!
    var clipStorage: ClipStorageProtocolMock!
    var referenceClipStorage: ReferenceClipStorageProtocolMock!
    var imageStorage: ImageStorageProtocolMock!
    var observer: TemporariesPersistServiceObserverMock!
    var queue: StorageCommandQueueMock!

    override func setUp() {
        temporaryClipStorage = TemporaryClipStorageProtocolMock()
        temporaryImageStorage = TemporaryImageStorageProtocolMock()
        clipStorage = ClipStorageProtocolMock()
        referenceClipStorage = ReferenceClipStorageProtocolMock()
        imageStorage = ImageStorageProtocolMock()
        observer = TemporariesPersistServiceObserverMock()
        queue = StorageCommandQueueMock()

        temporaryClipStorage.readAllClipsHandler = { .success([]) }
        temporaryClipStorage.deleteAllHandler = { .success(()) }
        referenceClipStorage.readAllDirtyTagsHandler = { .success([]) }
        queue.syncHandler = { $0() }
        queue.syncBlockHandler = { try $0() }

        service = .init(temporaryClipStorage: temporaryClipStorage,
                        temporaryImageStorage: temporaryImageStorage,
                        clipStorage: clipStorage,
                        referenceClipStorage: referenceClipStorage,
                        imageStorage: imageStorage,
                        commandQueue: queue,
                        lock: .init())
        service.set(observer: observer)
    }

    // MARK: - Preparation

    private func setUp_永続化の進捗を受け取れる() {
        var progressCount = 0

        observer.temporariesPersistServiceHandler = { _, index, count in
            XCTAssertEqual(index, progressCount + 1)
            XCTAssertEqual(count, 3)
            progressCount += 1
        }
    }

    private func setUp_一時保存したタグを読み込める() {
        referenceClipStorage.readAllDirtyTagsHandler = {
            .success([
                .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!,
                             name: "hoge",
                             isHidden: true,
                             isDirty: true),
                .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!,
                             name: "fuga",
                             isHidden: false,
                             isDirty: true),
                .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!,
                             name: "piyo",
                             isHidden: true,
                             isDirty: true),
            ])
        }
    }

    private func setUp_一時保存したクリップを読み込める() {
        temporaryClipStorage.readAllClipsHandler = {
            return .success([
                .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!,
                             items: [
                                 .makeDefault(imageId: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E61")!, imageFileName: "1-1"),
                                 .makeDefault(imageId: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E62")!, imageFileName: "1-2"),
                             ]),
                .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!,
                             items: [
                                 .makeDefault(imageId: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E71")!, imageFileName: "2-1"),
                             ]),
                .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!,
                             items: [
                                 .makeDefault(imageId: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E81")!, imageFileName: "3-1"),
                                 .makeDefault(imageId: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E82")!, imageFileName: "3-2"),
                             ]),
            ])
        }
    }

    private func setUp_一時保存タグを全て永続化できる() {
        var createCounter = 0

        clipStorage.createTagHandler = { tag in
            defer { createCounter += 1 }
            switch createCounter {
            case 0:
                XCTAssertEqual(tag.id, UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!)
                XCTAssertEqual(tag.name, "hoge")
                XCTAssertTrue(tag.isHidden)
                return .success(.makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!,
                                             name: "hoge",
                                             isHidden: true))

            case 1:
                XCTAssertEqual(tag.id, UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!)
                XCTAssertEqual(tag.name, "fuga")
                XCTAssertFalse(tag.isHidden)
                return .success(.makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!,
                                             name: "fuga",
                                             isHidden: false))

            case 2:
                XCTAssertEqual(tag.id, UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!)
                XCTAssertEqual(tag.name, "piyo")
                XCTAssertTrue(tag.isHidden)
                return .success(.makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!,
                                             name: "piyo",
                                             isHidden: true))

            default:
                XCTFail("予期しないタグが永続化された")
                return .failure(.internalError)
            }
        }
    }

    private func setUp_一時保存タグを永続化できるが一部重複している() {
        var createCounter = 0

        clipStorage.createTagHandler = { tag in
            defer { createCounter += 1 }
            switch createCounter {
            case 0:
                XCTAssertEqual(tag.id, UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!)
                XCTAssertEqual(tag.name, "hoge")
                XCTAssertTrue(tag.isHidden)
                return .failure(.duplicated)

            case 1:
                XCTAssertEqual(tag.id, UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!)
                XCTAssertEqual(tag.name, "fuga")
                XCTAssertFalse(tag.isHidden)
                return .success(.makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!,
                                             name: "fuga",
                                             isHidden: false))

            case 2:
                XCTAssertEqual(tag.id, UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!)
                XCTAssertEqual(tag.name, "piyo")
                XCTAssertTrue(tag.isHidden)
                return .failure(.duplicated)

            default:
                XCTFail("予期しないタグが永続化された")
                return .failure(.internalError)
            }
        }
    }

    private func setUp_一時保存クリップを全て永続化できる() {
        var createCount = 0

        clipStorage.createHandler = { recipe in
            defer { createCount += 1 }
            switch createCount {
            case 0:
                XCTAssertEqual(recipe.id, UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!)
                return .success(.makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!))

            case 1:
                XCTAssertEqual(recipe.id, UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!)
                return .success(.makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!))

            case 2:
                XCTAssertEqual(recipe.id, UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!)
                return .success(.makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!))

            default:
                XCTFail("予期しないタグの永続化が実行された")
                return .failure(.internalError)
            }
        }
    }

    private func setUp_一時保存タグを全て更新できる() {
        referenceClipStorage.updateTagsHandler = { ids, toDirty in
            XCTAssertEqual(ids, [
                UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!,
                UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!,
                UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!
            ])
            XCTAssertFalse(toDirty)
            return .success(())
        }
    }

    private func setUp_一時保存タグを重複していない分のみ更新できる() {
        referenceClipStorage.updateTagsHandler = { ids, toDirty in
            XCTAssertEqual(ids, [UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!])
            XCTAssertFalse(toDirty)
            return .success(())
        }
    }

    private func setUp_一時保存タグを重複した分のみ削除できる() {
        referenceClipStorage.deleteTagsHandler = { ids in
            XCTAssertEqual(ids, [
                UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!,
                UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!
            ])
            return .success(())
        }
    }

    private func setUp_一時保存クリップを全て削除できる() {
        var deleteClipCount = 0

        temporaryClipStorage.deleteClipsHandler = { ids in
            defer { deleteClipCount += 1 }
            switch deleteClipCount {
            case 0:
                XCTAssertEqual(ids, [UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!])

            case 1:
                XCTAssertEqual(ids, [UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!])

            case 2:
                XCTAssertEqual(ids, [UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!])

            default:
                XCTFail("予期しない一時保存クリップの削除が実行された")
                return .failure(.internalError)
            }
            return .success([])
        }
    }

    private func setUp_一時保存領域からの画像の移動に成功する() {
        var readImageCount = 0
        var createImageCount = 0
        var deleteImageCount = 0
        var deleteAllCount = 0

        temporaryImageStorage.readImageHandler = { imageFileName, clipId in
            defer { readImageCount += 1 }
            switch readImageCount {
            case 0:
                XCTAssertEqual(clipId, UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!)
                XCTAssertEqual(imageFileName, "1-1")
                return "1-1".data(using: .utf8)

            case 1:
                XCTAssertEqual(clipId, UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!)
                XCTAssertEqual(imageFileName, "1-2")
                return "1-2".data(using: .utf8)

            case 2:
                XCTAssertEqual(clipId, UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!)
                XCTAssertEqual(imageFileName, "2-1")
                return "2-1".data(using: .utf8)

            case 3:
                XCTAssertEqual(clipId, UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!)
                XCTAssertEqual(imageFileName, "3-1")
                return "3-1".data(using: .utf8)

            case 4:
                XCTAssertEqual(clipId, UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!)
                XCTAssertEqual(imageFileName, "3-2")
                return "3-2".data(using: .utf8)

            default:
                XCTFail("予期しない画像の読み込みが行われた")
                throw TestError.dummy
            }
        }

        imageStorage.createHandler = { data, imageId in
            defer { createImageCount += 1 }
            switch createImageCount {
            case 0:
                XCTAssertEqual(data, "1-1".data(using: .utf8))
                XCTAssertEqual(imageId, UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E61")!)

            case 1:
                XCTAssertEqual(data, "1-2".data(using: .utf8))
                XCTAssertEqual(imageId, UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E62")!)

            case 2:
                XCTAssertEqual(data, "2-1".data(using: .utf8))
                XCTAssertEqual(imageId, UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E71")!)

            case 3:
                XCTAssertEqual(data, "3-1".data(using: .utf8))
                XCTAssertEqual(imageId, UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E81")!)
            case 4:
                XCTAssertEqual(data, "3-2".data(using: .utf8))
                XCTAssertEqual(imageId, UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E82")!)

            default:
                XCTFail("予期しない画像の保存が行われた")
                throw TestError.dummy
            }
        }

        temporaryImageStorage.deleteHandler = { imageFileName, clipId in
            defer { deleteImageCount += 1 }
            switch deleteImageCount {
            case 0:
                XCTAssertEqual(clipId, UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!)
                XCTAssertEqual(imageFileName, "1-1")

            case 1:
                XCTAssertEqual(clipId, UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!)
                XCTAssertEqual(imageFileName, "1-2")

            case 2:
                XCTAssertEqual(clipId, UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!)
                XCTAssertEqual(imageFileName, "2-1")

            case 3:
                XCTAssertEqual(clipId, UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!)
                XCTAssertEqual(imageFileName, "3-1")

            case 4:
                XCTAssertEqual(clipId, UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!)
                XCTAssertEqual(imageFileName, "3-2")

            default:
                XCTFail("予期しない画像の削除が行われた")
                throw TestError.dummy
            }
        }

        temporaryImageStorage.deleteAllHandler = { clipId in
            defer { deleteAllCount += 1 }
            switch deleteAllCount {
            case 0:
                XCTAssertEqual(clipId, UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!)

            case 1:
                XCTAssertEqual(clipId, UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!)

            case 2:
                XCTAssertEqual(clipId, UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!)

            default:
                XCTFail("予期しない画像の削除が行われた")
                throw TestError.dummy
            }
        }
    }

    private func setUp_一時保存領域からの画像の移動に失敗する() {
        var readImageCount = 0
        var createImageCount = 0
        var deleteImageCount = 0
        var deleteAllCount = 0

        temporaryImageStorage.readImageHandler = { imageFileName, clipId in
            defer { readImageCount += 1 }
            switch readImageCount {
            case 0:
                XCTAssertEqual(clipId, UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!)
                XCTAssertEqual(imageFileName, "1-1")
                return "1-1".data(using: .utf8)

            case 1:
                XCTAssertEqual(clipId, UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!)
                XCTAssertEqual(imageFileName, "1-2")
                return "1-2".data(using: .utf8)

            case 2:
                return nil

            case 3:
                XCTAssertEqual(clipId, UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!)
                XCTAssertEqual(imageFileName, "3-1")
                return "3-1".data(using: .utf8)

            case 4:
                XCTAssertEqual(clipId, UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!)
                XCTAssertEqual(imageFileName, "3-2")
                return "3-2".data(using: .utf8)

            default:
                XCTFail("予期しない画像の読み込みが行われた")
                throw TestError.dummy
            }
        }

        imageStorage.createHandler = { data, imageId in
            defer { createImageCount += 1 }
            switch createImageCount {
            case 0:
                throw TestError.dummy

            case 1:
                throw TestError.dummy

            case 2:
                XCTAssertEqual(data, "3-1".data(using: .utf8))
                XCTAssertEqual(imageId, UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E81")!)

            case 3:
                XCTAssertEqual(data, "3-2".data(using: .utf8))
                XCTAssertEqual(imageId, UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E82")!)

            default:
                XCTFail("予期しない画像の保存が行われた")
                throw TestError.dummy
            }
        }

        temporaryImageStorage.deleteHandler = { imageFileName, clipId in
            defer { deleteImageCount += 1 }
            switch deleteImageCount {
            case 0:
                XCTAssertEqual(clipId, UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!)
                XCTAssertEqual(imageFileName, "1-1")

            case 1:
                XCTAssertEqual(clipId, UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!)
                XCTAssertEqual(imageFileName, "1-2")

            case 2:
                throw TestError.dummy

            case 3:
                throw TestError.dummy

            default:
                XCTFail("予期しない画像の削除が行われた")
                throw TestError.dummy
            }
        }

        temporaryImageStorage.deleteAllHandler = { clipId in
            defer { deleteAllCount += 1 }
            switch deleteAllCount {
            case 0:
                XCTAssertEqual(clipId, UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!)

            case 1:
                XCTAssertEqual(clipId, UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!)

            case 2:
                XCTAssertEqual(clipId, UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!)

            default:
                XCTFail("予期しない画像の削除が行われた")
                throw TestError.dummy
            }
        }
    }

    // MARK: - Test persistTemporaryDirtyTags

    func test_persistTemporaryDirtyTags_一時保存領域の読み込みに成功し_永続化に成功し_一時保存領域更新できる場合_trueを返す() {
        setUp_一時保存したタグを読み込める()
        setUp_一時保存タグを全て永続化できる()
        setUp_一時保存タグを全て更新できる()

        XCTAssertTrue(service.persistTemporaryDirtyTags(), "trueが返らなかった")

        XCTAssertEqual(referenceClipStorage.readAllDirtyTagsCallCount, 1, "一時保存領域のタグ群が読み込めなかった")
        XCTAssertEqual(clipStorage.createTagCallCount, 3, "対象の一時保存領域のタグが永続化されなかった")
        XCTAssertEqual(referenceClipStorage.updateTagsCallCount, 1, "一時保存領域の永続化済みタグを更新できなかった")
        XCTAssertEqual(referenceClipStorage.deleteTagsCallCount, 0, "一時保存領域からタグが削除されてしまった")
        [
            (#line, clipStorage.beginTransactionCallCount),
            (#line, referenceClipStorage.beginTransactionCallCount),
            (#line, imageStorage.beginTransactionCallCount),
            (#line, temporaryClipStorage.beginTransactionCallCount),
        ].forEach { XCTAssertEqual($0.1, 1, "トランザクションが開始されなかった", line: $0.0) }
        [
            (#line, clipStorage.commitTransactionCallCount),
            (#line, referenceClipStorage.commitTransactionCallCount),
            (#line, imageStorage.commitTransactionCallCount),
            (#line, temporaryClipStorage.commitTransactionCallCount),
        ].forEach { XCTAssertEqual($0.1, 1, "トランザクションがcommitされなかった", line: $0.0) }
        [
            (#line, clipStorage.cancelTransactionIfNeededCallCount),
            (#line, referenceClipStorage.cancelTransactionIfNeededCallCount),
            (#line, imageStorage.cancelTransactionIfNeededCallCount),
            (#line, temporaryClipStorage.cancelTransactionIfNeededCallCount),
        ].forEach { XCTAssertEqual($0.1, 0, "トランザクションがキャンセルされてしまった", line: $0.0) }
    }

    func test_persistTemporaryDirtyTags_一時保存領域の読み込みに成功し_永続化に成功し_一時保存領域更新できない場合_falseを返す() {
        setUp_一時保存したタグを読み込める()
        setUp_一時保存タグを全て永続化できる()
        referenceClipStorage.updateTagsHandler = { _, _ in return .failure(.internalError) }

        XCTAssertFalse(service.persistTemporaryDirtyTags(), "falseが返らなかった")

        [
            (#line, clipStorage.beginTransactionCallCount),
            (#line, referenceClipStorage.beginTransactionCallCount),
            (#line, imageStorage.beginTransactionCallCount),
            (#line, temporaryClipStorage.beginTransactionCallCount),
        ].forEach { XCTAssertEqual($0.1, 1, "トランザクションが開始されなかった", line: $0.0) }
        [
            (#line, clipStorage.commitTransactionCallCount),
            (#line, referenceClipStorage.commitTransactionCallCount),
            (#line, imageStorage.commitTransactionCallCount),
            (#line, temporaryClipStorage.commitTransactionCallCount),
        ].forEach { XCTAssertEqual($0.1, 0, "トランザクションがcommitされてしまった", line: $0.0) }
        [
            (#line, clipStorage.cancelTransactionIfNeededCallCount),
            (#line, referenceClipStorage.cancelTransactionIfNeededCallCount),
            (#line, imageStorage.cancelTransactionIfNeededCallCount),
            (#line, temporaryClipStorage.cancelTransactionIfNeededCallCount),
        ].forEach { XCTAssertEqual($0.1, 1, "トランザクションがキャンセルされなかった", line: $0.0) }
    }

    func test_persistTemporaryDirtyTags_一時保存領域の読み込みに成功し_永続化時に重複が存在し_一時保存領域から重複分を削除できる場合_trueを返す() {
        setUp_一時保存したタグを読み込める()
        setUp_一時保存タグを永続化できるが一部重複している()
        setUp_一時保存タグを重複していない分のみ更新できる()
        setUp_一時保存タグを重複した分のみ削除できる()

        XCTAssertTrue(service.persistTemporaryDirtyTags(), "trueが返らなかった")

        XCTAssertEqual(referenceClipStorage.readAllDirtyTagsCallCount, 1, "一時保存領域のタグ群が読み込めなかった")
        XCTAssertEqual(clipStorage.createTagCallCount, 3, "対象の一時保存領域のタグが永続化されなかった")
        XCTAssertEqual(referenceClipStorage.updateTagsCallCount, 1, "一時保存領域の永続化済みタグを更新できなかった")
        XCTAssertEqual(referenceClipStorage.deleteTagsCallCount, 1, "一時保存領域から重複タグが削除されなかった")
        [
            (#line, clipStorage.beginTransactionCallCount),
            (#line, referenceClipStorage.beginTransactionCallCount),
            (#line, imageStorage.beginTransactionCallCount),
            (#line, temporaryClipStorage.beginTransactionCallCount),
        ].forEach { XCTAssertEqual($0.1, 1, "トランザクションが開始されなかった", line: $0.0) }
        [
            (#line, clipStorage.commitTransactionCallCount),
            (#line, referenceClipStorage.commitTransactionCallCount),
            (#line, imageStorage.commitTransactionCallCount),
            (#line, temporaryClipStorage.commitTransactionCallCount),
        ].forEach { XCTAssertEqual($0.1, 1, "トランザクションがcommitされなかった", line: $0.0) }
        [
            (#line, clipStorage.cancelTransactionIfNeededCallCount),
            (#line, referenceClipStorage.cancelTransactionIfNeededCallCount),
            (#line, imageStorage.cancelTransactionIfNeededCallCount),
            (#line, temporaryClipStorage.cancelTransactionIfNeededCallCount),
        ].forEach { XCTAssertEqual($0.1, 0, "トランザクションがキャンセルされてしまった", line: $0.0) }
    }

    func test_persistTemporaryDirtyTags_一時保存領域の読み込みに成功し_永続化時に重複が存在し_一時保存領域から重複分を削除できない場合_falseを返す() {
        setUp_一時保存したタグを読み込める()
        setUp_一時保存タグを永続化できるが一部重複している()
        setUp_一時保存タグを重複していない分のみ更新できる()
        referenceClipStorage.deleteTagsHandler = { _ in .failure(.internalError) }

        XCTAssertFalse(service.persistTemporaryDirtyTags(), "falseが返らなかった")

        [
            (#line, clipStorage.beginTransactionCallCount),
            (#line, referenceClipStorage.beginTransactionCallCount),
            (#line, imageStorage.beginTransactionCallCount),
            (#line, temporaryClipStorage.beginTransactionCallCount),
        ].forEach { XCTAssertEqual($0.1, 1, "トランザクションが開始されなかった", line: $0.0) }
        [
            (#line, clipStorage.commitTransactionCallCount),
            (#line, referenceClipStorage.commitTransactionCallCount),
            (#line, imageStorage.commitTransactionCallCount),
            (#line, temporaryClipStorage.commitTransactionCallCount),
        ].forEach { XCTAssertEqual($0.1, 0, "トランザクションがcommitされてしまった", line: $0.0) }
        [
            (#line, clipStorage.cancelTransactionIfNeededCallCount),
            (#line, referenceClipStorage.cancelTransactionIfNeededCallCount),
            (#line, imageStorage.cancelTransactionIfNeededCallCount),
            (#line, temporaryClipStorage.cancelTransactionIfNeededCallCount),
        ].forEach { XCTAssertEqual($0.1, 1, "トランザクションがキャンセルされなかった", line: $0.0) }
    }

    func test_persistTemporaryDirtyTags_一時保存領域の読み込みに成功し_永続化に失敗する場合_falseを返す() {
        setUp_一時保存したタグを読み込める()
        clipStorage.createTagHandler = { _ in .failure(.internalError) }

        XCTAssertFalse(service.persistTemporaryDirtyTags(), "falseが返らなかった")

        [
            (#line, clipStorage.beginTransactionCallCount),
            (#line, referenceClipStorage.beginTransactionCallCount),
            (#line, imageStorage.beginTransactionCallCount),
            (#line, temporaryClipStorage.beginTransactionCallCount),
        ].forEach { XCTAssertEqual($0.1, 1, "トランザクションが開始されなかった", line: $0.0) }
        [
            (#line, clipStorage.commitTransactionCallCount),
            (#line, referenceClipStorage.commitTransactionCallCount),
            (#line, imageStorage.commitTransactionCallCount),
            (#line, temporaryClipStorage.commitTransactionCallCount),
        ].forEach { XCTAssertEqual($0.1, 0, "トランザクションがcommitされてしまった", line: $0.0) }
        [
            (#line, clipStorage.cancelTransactionIfNeededCallCount),
            (#line, referenceClipStorage.cancelTransactionIfNeededCallCount),
            (#line, imageStorage.cancelTransactionIfNeededCallCount),
            (#line, temporaryClipStorage.cancelTransactionIfNeededCallCount),
        ].forEach { XCTAssertEqual($0.1, 1, "トランザクションがキャンセルされなかった", line: $0.0) }
    }

    func test_persistTemporaryDirtyTags_一時保存領域の読み込みに失敗する場合_falseを返す() {
        referenceClipStorage.readAllDirtyTagsHandler = { .failure(.internalError) }

        XCTAssertFalse(service.persistTemporaryDirtyTags(), "falseが返らなかった")

        [
            // begin
            (#line, clipStorage.beginTransactionCallCount),
            (#line, referenceClipStorage.beginTransactionCallCount),
            (#line, imageStorage.beginTransactionCallCount),
            (#line, temporaryClipStorage.beginTransactionCallCount),
            // commit
            (#line, clipStorage.commitTransactionCallCount),
            (#line, referenceClipStorage.commitTransactionCallCount),
            (#line, imageStorage.commitTransactionCallCount),
            (#line, temporaryClipStorage.commitTransactionCallCount),
            // cancel
            (#line, clipStorage.cancelTransactionIfNeededCallCount),
            (#line, referenceClipStorage.cancelTransactionIfNeededCallCount),
            (#line, imageStorage.cancelTransactionIfNeededCallCount),
            (#line, temporaryClipStorage.cancelTransactionIfNeededCallCount),
        ].forEach { XCTAssertEqual($0.1, 0, "トランザクションの操作が行われてしまっている", line: $0.0) }
    }

    // MARK: - Test persistTemporaryClips

    func test_persistentTemporaryClips_一時保存領域の読み込みに成功し_永続化に成功し_一時保存領域の更新に成功し_一時保存領域からの画像の移動に成功した場合_trueを返す() {
        setUp_永続化の進捗を受け取れる()
        setUp_一時保存したクリップを読み込める()
        setUp_一時保存クリップを全て永続化できる()
        setUp_一時保存クリップを全て削除できる()
        setUp_一時保存領域からの画像の移動に成功する()

        XCTAssertTrue(service.persistTemporaryClips(), "trueが返らなかった")

        XCTAssertEqual(temporaryClipStorage.readAllClipsCallCount, 1, "一時保存領域の読み込みが行われなかった")
        XCTAssertEqual(observer.temporariesPersistServiceCallCount, 3, "Observerに進捗が通知されなかった")
        XCTAssertEqual(clipStorage.createCallCount, 3, "永続化が実行されなかった")
        XCTAssertEqual(temporaryClipStorage.deleteClipsCallCount, 3, "一時保存領域からの削除が実行されなかった")
        XCTAssertEqual(temporaryImageStorage.readImageCallCount, 2 + 1 + 2)
        XCTAssertEqual(imageStorage.createCallCount, 2 + 1 + 2)
        XCTAssertEqual(temporaryImageStorage.deleteCallCount, 2 + 1 + 2)
        XCTAssertEqual(temporaryImageStorage.deleteAllCallCount, 3)
        [
            (#line, clipStorage.beginTransactionCallCount),
            (#line, referenceClipStorage.beginTransactionCallCount),
            (#line, imageStorage.beginTransactionCallCount),
            (#line, temporaryClipStorage.beginTransactionCallCount),
        ].forEach { XCTAssertEqual($0.1, 3, "トランザクションが開始されなかった", line: $0.0) }
        [
            (#line, clipStorage.commitTransactionCallCount),
            (#line, referenceClipStorage.commitTransactionCallCount),
            (#line, imageStorage.commitTransactionCallCount),
            (#line, temporaryClipStorage.commitTransactionCallCount),
        ].forEach { XCTAssertEqual($0.1, 3, "トランザクションがcommitされなかった", line: $0.0) }
        [
            (#line, clipStorage.cancelTransactionIfNeededCallCount),
            (#line, referenceClipStorage.cancelTransactionIfNeededCallCount),
            (#line, imageStorage.cancelTransactionIfNeededCallCount),
            (#line, temporaryClipStorage.cancelTransactionIfNeededCallCount),
        ].forEach { XCTAssertEqual($0.1, 0, "トランザクションがキャンセルされてしまった", line: $0.0) }
    }

    func test_persistentTemporaryClips_一時保存領域の読み込みに成功し_永続化に成功し_一時保存領域の更新に成功し_一時保存領域からの画像の移動に失敗した場合_trueを返す() {
        setUp_永続化の進捗を受け取れる()
        setUp_一時保存したクリップを読み込める()
        setUp_一時保存クリップを全て永続化できる()
        setUp_一時保存クリップを全て削除できる()
        setUp_一時保存領域からの画像の移動に失敗する()

        // 画像の移動に失敗しても、trueを返す
        XCTAssertTrue(service.persistTemporaryClips(), "trueが返らなかった")

        XCTAssertEqual(temporaryClipStorage.readAllClipsCallCount, 1, "一時保存領域の読み込みが行われなかった")
        XCTAssertEqual(observer.temporariesPersistServiceCallCount, 3, "Observerに進捗が通知されなかった")
        XCTAssertEqual(clipStorage.createCallCount, 3, "永続化が実行されなかった")
        XCTAssertEqual(temporaryClipStorage.deleteClipsCallCount, 3, "一時保存領域からの削除が実行されなかった")
        XCTAssertEqual(temporaryImageStorage.readImageCallCount, 2 + 1 + 2)
        XCTAssertEqual(imageStorage.createCallCount, 2 /* + 1 */ + 2)
        XCTAssertEqual(temporaryImageStorage.deleteCallCount, 2 /* + 1 */ + 2)
        XCTAssertEqual(temporaryImageStorage.deleteAllCallCount, 3)
        [
            (#line, clipStorage.beginTransactionCallCount),
            (#line, referenceClipStorage.beginTransactionCallCount),
            (#line, imageStorage.beginTransactionCallCount),
            (#line, temporaryClipStorage.beginTransactionCallCount),
        ].forEach { XCTAssertEqual($0.1, 3, "トランザクションが開始されなかった", line: $0.0) }
        [
            (#line, clipStorage.commitTransactionCallCount),
            (#line, referenceClipStorage.commitTransactionCallCount),
            (#line, imageStorage.commitTransactionCallCount),
            (#line, temporaryClipStorage.commitTransactionCallCount),
        ].forEach { XCTAssertEqual($0.1, 3, "トランザクションがcommitされなかった", line: $0.0) }
        [
            (#line, clipStorage.cancelTransactionIfNeededCallCount),
            (#line, referenceClipStorage.cancelTransactionIfNeededCallCount),
            (#line, imageStorage.cancelTransactionIfNeededCallCount),
            (#line, temporaryClipStorage.cancelTransactionIfNeededCallCount),
        ].forEach { XCTAssertEqual($0.1, 0, "トランザクションがキャンセルされてしまった", line: $0.0) }
    }

    func test_persistentTemporaryClips_一時保存領域の読み込みに成功し_永続化に成功し_一時保存領域の更新に失敗した場合_falseを返す() {
        setUp_永続化の進捗を受け取れる()
        setUp_一時保存したクリップを読み込める()
        setUp_一時保存クリップを全て永続化できる()
        temporaryClipStorage.deleteClipsHandler = { _ in .failure(.internalError) }

        XCTAssertFalse(service.persistTemporaryClips(), "falseが返らなかった")

        XCTAssertEqual(temporaryClipStorage.readAllClipsCallCount, 1, "一時保存領域の読み込みが行われなかった")
        XCTAssertEqual(observer.temporariesPersistServiceCallCount, 3, "Observerに進捗が通知されなかった")
        XCTAssertEqual(clipStorage.createCallCount, 3, "永続化が実行されなかった")
        XCTAssertEqual(temporaryClipStorage.deleteClipsCallCount, 3, "一時保存領域からの削除が実行されなかった")
        [
            (#line, clipStorage.beginTransactionCallCount),
            (#line, referenceClipStorage.beginTransactionCallCount),
            (#line, imageStorage.beginTransactionCallCount),
            (#line, temporaryClipStorage.beginTransactionCallCount),
        ].forEach { XCTAssertEqual($0.1, 3, "トランザクションが開始されなかった", line: $0.0) }
        [
            (#line, clipStorage.commitTransactionCallCount),
            (#line, referenceClipStorage.commitTransactionCallCount),
            (#line, imageStorage.commitTransactionCallCount),
            (#line, temporaryClipStorage.commitTransactionCallCount),
        ].forEach { XCTAssertEqual($0.1, 0, "トランザクションがcommitされてしまった", line: $0.0) }
        [
            (#line, clipStorage.cancelTransactionIfNeededCallCount),
            (#line, referenceClipStorage.cancelTransactionIfNeededCallCount),
            (#line, imageStorage.cancelTransactionIfNeededCallCount),
            (#line, temporaryClipStorage.cancelTransactionIfNeededCallCount),
        ].forEach { XCTAssertEqual($0.1, 3, "トランザクションがキャンセルされなかった", line: $0.0) }
    }

    func test_persistentTemporaryClips_一時保存領域の読み込みに成功し_永続化に失敗する場合_falseを返す() {
        setUp_永続化の進捗を受け取れる()
        setUp_一時保存したクリップを読み込める()
        clipStorage.createHandler = { _ in .failure(.internalError) }

        XCTAssertFalse(service.persistTemporaryClips(), "falseが返らなかった")

        XCTAssertEqual(temporaryClipStorage.readAllClipsCallCount, 1, "一時保存領域の読み込みが行われなかった")
        XCTAssertEqual(observer.temporariesPersistServiceCallCount, 3, "Observerに進捗が通知されなかった")
        XCTAssertEqual(clipStorage.createCallCount, 3, "永続化が実行されなかった")
        XCTAssertEqual(temporaryClipStorage.deleteClipsCallCount, 0, "一時保存領域からの削除が実行された")
        [
            (#line, clipStorage.beginTransactionCallCount),
            (#line, referenceClipStorage.beginTransactionCallCount),
            (#line, imageStorage.beginTransactionCallCount),
            (#line, temporaryClipStorage.beginTransactionCallCount),
        ].forEach { XCTAssertEqual($0.1, 3, "トランザクションが開始されなかった", line: $0.0) }
        [
            (#line, clipStorage.commitTransactionCallCount),
            (#line, referenceClipStorage.commitTransactionCallCount),
            (#line, imageStorage.commitTransactionCallCount),
            (#line, temporaryClipStorage.commitTransactionCallCount),
        ].forEach { XCTAssertEqual($0.1, 0, "トランザクションがcommitされてしまった", line: $0.0) }
        [
            (#line, clipStorage.cancelTransactionIfNeededCallCount),
            (#line, referenceClipStorage.cancelTransactionIfNeededCallCount),
            (#line, imageStorage.cancelTransactionIfNeededCallCount),
            (#line, temporaryClipStorage.cancelTransactionIfNeededCallCount),
        ].forEach { XCTAssertEqual($0.1, 3, "トランザクションがキャンセルされなかった", line: $0.0) }
    }

    func test_persistentTemporaryClips_一時保存領域の読み込みに失敗する場合_falseを返す() {
        temporaryClipStorage.readAllClipsHandler = { .failure(.internalError) }

        XCTAssertFalse(service.persistTemporaryClips(), "falseが返らなかった")

        XCTAssertEqual(temporaryClipStorage.readAllClipsCallCount, 1, "一時保存領域の読み込みが行われなかった")
        [
            // begin
            (#line, clipStorage.beginTransactionCallCount),
            (#line, referenceClipStorage.beginTransactionCallCount),
            (#line, imageStorage.beginTransactionCallCount),
            (#line, temporaryClipStorage.beginTransactionCallCount),
            // commit
            (#line, clipStorage.commitTransactionCallCount),
            (#line, referenceClipStorage.commitTransactionCallCount),
            (#line, imageStorage.commitTransactionCallCount),
            (#line, temporaryClipStorage.commitTransactionCallCount),
            // cancel
            (#line, clipStorage.cancelTransactionIfNeededCallCount),
            (#line, referenceClipStorage.cancelTransactionIfNeededCallCount),
            (#line, imageStorage.cancelTransactionIfNeededCallCount),
            (#line, temporaryClipStorage.cancelTransactionIfNeededCallCount),
        ].forEach { XCTAssertEqual($0.1, 0, "トランザクションの操作が行われてしまっている", line: $0.0) }
    }
}
