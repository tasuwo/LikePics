//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
@testable import Domain
import Nimble
import Quick
@testable import TestHelper

class TemporariesPersistServiceSpec: QuickSpec {
    enum TestError: Error { case dummy }

    override func spec() {
        var service: TemporariesPersistService!
        var temporaryClipStorage: TemporaryClipStorageProtocolMock!
        var temporaryImageStorage: TemporaryImageStorageProtocolMock!
        var clipStorage: ClipStorageProtocolMock!
        var referenceClipStorage: ReferenceClipStorageProtocolMock!
        var imageStorage: ImageStorageProtocolMock!
        var observer: TemporariesPersistServiceObserverMock!

        beforeEach {
            temporaryClipStorage = TemporaryClipStorageProtocolMock()
            temporaryImageStorage = TemporaryImageStorageProtocolMock()
            clipStorage = ClipStorageProtocolMock()
            referenceClipStorage = ReferenceClipStorageProtocolMock()
            imageStorage = ImageStorageProtocolMock()
            observer = TemporariesPersistServiceObserverMock()

            clipStorage.performAndWaitHandler = { $0() }
            temporaryClipStorage.readAllClipsHandler = { .success([]) }
            temporaryClipStorage.deleteAllHandler = { .success(()) }
            referenceClipStorage.readAllDirtyTagsHandler = { .success([]) }

            service = .init(temporaryClipStorage: temporaryClipStorage,
                            temporaryImageStorage: temporaryImageStorage,
                            clipStorage: clipStorage,
                            referenceClipStorage: referenceClipStorage,
                            imageStorage: imageStorage,
                            logger: RootLogger.shared,
                            queue: .global())
            service.set(observer: observer)
        }

        describe("persistTemporaryDirtyTags") {
            var result: Bool!

            beforeEach {
                result = nil
            }

            context("一時保存されたタグ群を読み込める") {
                beforeEach {
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

                context("一時保存されたタグを永続化できる") {
                    var createCounter = 0

                    beforeEach {
                        createCounter = 0

                        clipStorage.createTagHandler = { tag in
                            defer { createCounter += 1 }
                            switch createCounter {
                            case 0:
                                expect(tag.id).to(equal(UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!))
                                expect(tag.name).to(equal("hoge"))
                                expect(tag.isHidden).to(beTrue())
                                return .success(.makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!,
                                                             name: "hoge",
                                                             isHidden: true))
                            case 1:
                                expect(tag.id).to(equal(UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!))
                                expect(tag.name).to(equal("fuga"))
                                expect(tag.isHidden).to(beFalse())
                                return .success(.makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!,
                                                             name: "fuga",
                                                             isHidden: false))
                            case 2:
                                expect(tag.id).to(equal(UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!))
                                expect(tag.name).to(equal("piyo"))
                                expect(tag.isHidden).to(beTrue())
                                return .success(.makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!,
                                                             name: "piyo",
                                                             isHidden: true))
                            default:
                                fail("Unexpected call")
                                return .failure(.internalError)
                            }
                        }
                    }

                    context("永続化成功した一時保存されたタグのDirtyフラグを折ることができる") {
                        beforeEach {
                            referenceClipStorage.updateTagsHandler = { ids, toDirty in
                                expect(ids).to(equal([
                                    UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!,
                                    UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!,
                                    UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!
                                ]))
                                expect(false).to(beFalse())
                                return .success(())
                            }

                            result = service.persistTemporaryDirtyTags()
                        }

                        it("trueが返る") {
                            expect(result).to(beTrue())
                        }
                        it("一時保存されたDirtyなタグ群が読み込める") {
                            expect(referenceClipStorage.readAllDirtyTagsCallCount).to(equal(1))
                        }
                        it("読み込んだタグ群を永続化できる") {
                            expect(clipStorage.createTagCallCount).to(equal(3))
                        }
                        it("永続化できたタグ群について一時保存領域内でDirtyフラグを折る") {
                            expect(referenceClipStorage.updateTagsCallCount).to(equal(1))
                        }
                        it("トランザクションの開始/終了が行われる") {
                            expect(clipStorage.beginTransactionCallCount).to(equal(1))
                            expect(referenceClipStorage.beginTransactionCallCount).to(equal(1))
                            expect(imageStorage.beginTransactionCallCount).to(equal(1))
                            expect(temporaryClipStorage.beginTransactionCallCount).to(equal(1))

                            expect(clipStorage.commitTransactionCallCount).to(equal(1))
                            expect(referenceClipStorage.commitTransactionCallCount).to(equal(1))
                            expect(imageStorage.commitTransactionCallCount).to(equal(1))
                            expect(temporaryClipStorage.commitTransactionCallCount).to(equal(1))

                            expect(clipStorage.cancelTransactionIfNeededCallCount).to(equal(0))
                            expect(referenceClipStorage.cancelTransactionIfNeededCallCount).to(equal(0))
                            expect(imageStorage.cancelTransactionIfNeededCallCount).to(equal(0))
                            expect(temporaryClipStorage.cancelTransactionIfNeededCallCount).to(equal(0))
                        }
                    }

                    context("永続化成功した一時保存されたタグのDirtyフラグを折るのに失敗した") {
                        beforeEach {
                            referenceClipStorage.updateTagsHandler = { _, _ in return .failure(.internalError) }

                            result = service.persistTemporaryDirtyTags()
                        }
                        it("falseが返る") {
                            expect(result).to(beFalse())
                        }
                        it("トランザクションのキャンセルが行われる") {
                            expect(clipStorage.beginTransactionCallCount).to(equal(1))
                            expect(referenceClipStorage.beginTransactionCallCount).to(equal(1))
                            expect(imageStorage.beginTransactionCallCount).to(equal(1))
                            expect(temporaryClipStorage.beginTransactionCallCount).to(equal(1))

                            expect(clipStorage.commitTransactionCallCount).to(equal(0))
                            expect(referenceClipStorage.commitTransactionCallCount).to(equal(0))
                            expect(imageStorage.commitTransactionCallCount).to(equal(0))
                            expect(temporaryClipStorage.commitTransactionCallCount).to(equal(0))

                            expect(clipStorage.cancelTransactionIfNeededCallCount).to(equal(1))
                            expect(referenceClipStorage.cancelTransactionIfNeededCallCount).to(equal(1))
                            expect(imageStorage.cancelTransactionIfNeededCallCount).to(equal(1))
                            expect(temporaryClipStorage.cancelTransactionIfNeededCallCount).to(equal(1))
                        }
                    }
                }

                context("一時保存されたタグと名前が重複したタグが既に存在した") {
                    var createCounter = 0

                    beforeEach {
                        createCounter = 0

                        clipStorage.createTagHandler = { tag in
                            defer { createCounter += 1 }
                            switch createCounter {
                            case 0:
                                expect(tag.id).to(equal(UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!))
                                expect(tag.name).to(equal("hoge"))
                                expect(tag.isHidden).to(beTrue())
                                return .failure(.duplicated)
                            case 1:
                                expect(tag.id).to(equal(UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!))
                                expect(tag.name).to(equal("fuga"))
                                expect(tag.isHidden).to(beFalse())
                                return .success(.makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!,
                                                             name: "fuga",
                                                             isHidden: false))
                            case 2:
                                expect(tag.id).to(equal(UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!))
                                expect(tag.name).to(equal("piyo"))
                                expect(tag.isHidden).to(beTrue())
                                return .failure(.duplicated)
                            default:
                                fail("Unexpected call")
                                return .failure(.internalError)
                            }
                        }

                        // 永続化成功した一時保存されたタグのDirtyフラグを折ることができる
                        referenceClipStorage.updateTagsHandler = { ids, toDirty in
                            expect(ids).to(equal([UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!]))
                            expect(false).to(beFalse())
                            return .success(())
                        }
                    }

                    context("名前が重複している一時保存されたタグを一時保存領域から削除できた") {
                        beforeEach {
                            referenceClipStorage.deleteTagsHandler = { ids in
                                expect(ids).to(equal([
                                    UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!,
                                    UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!
                                ]))
                                return .success(())
                            }

                            result = service.persistTemporaryDirtyTags()
                        }

                        it("trueが返る") {
                            expect(result).to(beTrue())
                        }
                        it("一時保存されたDirtyなタグ群が読み込める") {
                            expect(referenceClipStorage.readAllDirtyTagsCallCount).to(equal(1))
                        }
                        it("読み込んだタグ群を永続化できる") {
                            expect(clipStorage.createTagCallCount).to(equal(3))
                        }
                        it("永続化できたタグ群について一時保存領域内でDirtyフラグを折る") {
                            expect(referenceClipStorage.updateTagsCallCount).to(equal(1))
                        }
                        it("一時保存領域に重複したタグが存在した場合は、削除する") {
                            expect(referenceClipStorage.deleteTagsCallCount).to(equal(1))
                        }
                        it("トランザクションの開始/終了が行われる") {
                            expect(clipStorage.beginTransactionCallCount).to(equal(1))
                            expect(referenceClipStorage.beginTransactionCallCount).to(equal(1))
                            expect(imageStorage.beginTransactionCallCount).to(equal(1))
                            expect(temporaryClipStorage.beginTransactionCallCount).to(equal(1))

                            expect(clipStorage.commitTransactionCallCount).to(equal(1))
                            expect(referenceClipStorage.commitTransactionCallCount).to(equal(1))
                            expect(imageStorage.commitTransactionCallCount).to(equal(1))
                            expect(temporaryClipStorage.commitTransactionCallCount).to(equal(1))

                            expect(clipStorage.cancelTransactionIfNeededCallCount).to(equal(0))
                            expect(referenceClipStorage.cancelTransactionIfNeededCallCount).to(equal(0))
                            expect(imageStorage.cancelTransactionIfNeededCallCount).to(equal(0))
                            expect(temporaryClipStorage.cancelTransactionIfNeededCallCount).to(equal(0))
                        }
                    }

                    context("名前が重複している一時保存されたタグの一時保存領域からの削除に失敗した") {
                        beforeEach {
                            referenceClipStorage.deleteTagsHandler = { _ in .failure(.internalError) }

                            result = service.persistTemporaryDirtyTags()
                        }
                        it("falseが返る") {
                            expect(result).to(beFalse())
                        }
                        it("トランザクションのキャンセルが行われる") {
                            expect(clipStorage.beginTransactionCallCount).to(equal(1))
                            expect(referenceClipStorage.beginTransactionCallCount).to(equal(1))
                            expect(imageStorage.beginTransactionCallCount).to(equal(1))
                            expect(temporaryClipStorage.beginTransactionCallCount).to(equal(1))

                            expect(clipStorage.commitTransactionCallCount).to(equal(0))
                            expect(referenceClipStorage.commitTransactionCallCount).to(equal(0))
                            expect(imageStorage.commitTransactionCallCount).to(equal(0))
                            expect(temporaryClipStorage.commitTransactionCallCount).to(equal(0))

                            expect(clipStorage.cancelTransactionIfNeededCallCount).to(equal(1))
                            expect(referenceClipStorage.cancelTransactionIfNeededCallCount).to(equal(1))
                            expect(imageStorage.cancelTransactionIfNeededCallCount).to(equal(1))
                            expect(temporaryClipStorage.cancelTransactionIfNeededCallCount).to(equal(1))
                        }
                    }
                }

                context("一時保存されたタグの永続化に失敗する") {
                    beforeEach {
                        clipStorage.createTagHandler = { _ in .failure(.internalError) }

                        result = service.persistTemporaryDirtyTags()
                    }
                    it("falseが返る") {
                        expect(result).to(beFalse())
                    }
                    it("トランザクションのキャンセルが行われる") {
                        expect(clipStorage.beginTransactionCallCount).to(equal(1))
                        expect(referenceClipStorage.beginTransactionCallCount).to(equal(1))
                        expect(imageStorage.beginTransactionCallCount).to(equal(1))
                        expect(temporaryClipStorage.beginTransactionCallCount).to(equal(1))

                        expect(clipStorage.commitTransactionCallCount).to(equal(0))
                        expect(referenceClipStorage.commitTransactionCallCount).to(equal(0))
                        expect(imageStorage.commitTransactionCallCount).to(equal(0))
                        expect(temporaryClipStorage.commitTransactionCallCount).to(equal(0))

                        expect(clipStorage.cancelTransactionIfNeededCallCount).to(equal(1))
                        expect(referenceClipStorage.cancelTransactionIfNeededCallCount).to(equal(1))
                        expect(imageStorage.cancelTransactionIfNeededCallCount).to(equal(1))
                        expect(temporaryClipStorage.cancelTransactionIfNeededCallCount).to(equal(1))
                    }
                }
            }

            context("一時保存されたタグ群の読み込みに失敗した") {
                beforeEach {
                    referenceClipStorage.readAllDirtyTagsHandler = { .failure(.internalError) }

                    result = service.persistTemporaryDirtyTags()
                }
                it("falseが返る") {
                    expect(result).to(beFalse())
                }
                it("トランザクションが開始されない") {
                    expect(clipStorage.beginTransactionCallCount).to(equal(0))
                    expect(referenceClipStorage.beginTransactionCallCount).to(equal(0))
                    expect(imageStorage.beginTransactionCallCount).to(equal(0))
                    expect(temporaryClipStorage.beginTransactionCallCount).to(equal(0))

                    expect(clipStorage.commitTransactionCallCount).to(equal(0))
                    expect(referenceClipStorage.commitTransactionCallCount).to(equal(0))
                    expect(imageStorage.commitTransactionCallCount).to(equal(0))
                    expect(temporaryClipStorage.commitTransactionCallCount).to(equal(0))

                    expect(clipStorage.cancelTransactionIfNeededCallCount).to(equal(0))
                    expect(referenceClipStorage.cancelTransactionIfNeededCallCount).to(equal(0))
                    expect(imageStorage.cancelTransactionIfNeededCallCount).to(equal(0))
                    expect(temporaryClipStorage.cancelTransactionIfNeededCallCount).to(equal(0))
                }
            }
        }

        describe("persistTemporaryClips") {
            var result: Bool!

            beforeEach {
                result = nil
            }

            context("一時保存されたクリップメタ情報を読み込める") {
                var progressCount = 0

                beforeEach {
                    progressCount = 0
                }

                beforeEach {
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

                    // Observerに進捗が通知される
                    observer.temporariesPersistServiceHandler = { _, index, count in
                        expect(index).to(equal(progressCount + 1))
                        expect(count).to(equal(3))
                        progressCount += 1
                    }
                }

                context("メタ情報を永続化できる") {
                    var createCount = 0

                    beforeEach {
                        createCount = 0
                    }

                    beforeEach {
                        clipStorage.createHandler = { recipe in
                            defer { createCount += 1 }
                            switch createCount {
                            case 0:
                                expect(recipe.id).to(equal(UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!))
                                return .success(.makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!))
                            case 1:
                                expect(recipe.id).to(equal(UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!))
                                return .success(.makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!))
                            case 2:
                                expect(recipe.id).to(equal(UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!))
                                return .success(.makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!))
                            default:
                                fail("Unexpected call")
                                return .failure(.internalError)
                            }
                        }
                    }

                    context("一時保存されたクリップメタ情報の削除に成功する") {
                        var deleteClipCount = 0

                        beforeEach {
                            deleteClipCount = 0
                        }

                        beforeEach {
                            temporaryClipStorage.deleteClipsHandler = { ids in
                                defer { deleteClipCount += 1 }
                                switch deleteClipCount {
                                case 0:
                                    expect(ids).to(equal([UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!]))
                                case 1:
                                    expect(ids).to(equal([UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!]))
                                case 2:
                                    expect(ids).to(equal([UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!]))
                                default:
                                    fail("Unexpected call")
                                    return .failure(.internalError)
                                }
                                return .success([])
                            }
                        }

                        context("一時保存領域から画像を移動できる") {
                            var readImageCount = 0
                            var createImageCount = 0
                            var deleteImageCount = 0
                            var deleteAllCount = 0

                            beforeEach {
                                readImageCount = 0
                                createImageCount = 0
                                deleteImageCount = 0
                                deleteAllCount = 0
                            }

                            beforeEach {
                                temporaryImageStorage.readImageHandler = { imageFileName, clipId in
                                    defer { readImageCount += 1 }
                                    switch readImageCount {
                                    case 0:
                                        expect(clipId).to(equal(UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!))
                                        expect(imageFileName).to(equal("1-1"))
                                        return "1-1".data(using: .utf8)
                                    case 1:
                                        expect(clipId).to(equal(UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!))
                                        expect(imageFileName).to(equal("1-2"))
                                        return "1-2".data(using: .utf8)
                                    case 2:
                                        expect(clipId).to(equal(UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!))
                                        expect(imageFileName).to(equal("2-1"))
                                        return "2-1".data(using: .utf8)
                                    case 3:
                                        expect(clipId).to(equal(UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!))
                                        expect(imageFileName).to(equal("3-1"))
                                        return "3-1".data(using: .utf8)
                                    case 4:
                                        expect(clipId).to(equal(UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!))
                                        expect(imageFileName).to(equal("3-2"))
                                        return "3-2".data(using: .utf8)
                                    default:
                                        fail("Unexpected call")
                                        throw TestError.dummy
                                    }
                                }

                                imageStorage.createHandler = { data, imageId in
                                    defer { createImageCount += 1 }
                                    switch createImageCount {
                                    case 0:
                                        expect(data).to(equal("1-1".data(using: .utf8)))
                                        expect(imageId).to(equal(UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E61")!))
                                    case 1:
                                        expect(data).to(equal("1-2".data(using: .utf8)))
                                        expect(imageId).to(equal(UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E62")!))
                                    case 2:
                                        expect(data).to(equal("2-1".data(using: .utf8)))
                                        expect(imageId).to(equal(UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E71")!))
                                    case 3:
                                        expect(data).to(equal("3-1".data(using: .utf8)))
                                        expect(imageId).to(equal(UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E81")!))
                                    case 4:
                                        expect(data).to(equal("3-2".data(using: .utf8)))
                                        expect(imageId).to(equal(UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E82")!))
                                    default:
                                        fail("Unexpected call")
                                        throw TestError.dummy
                                    }
                                }

                                temporaryImageStorage.deleteHandler = { imageFileName, clipId in
                                    defer { deleteImageCount += 1 }
                                    switch deleteImageCount {
                                    case 0:
                                        expect(clipId).to(equal(UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!))
                                        expect(imageFileName).to(equal("1-1"))
                                    case 1:
                                        expect(clipId).to(equal(UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!))
                                        expect(imageFileName).to(equal("1-2"))
                                    case 2:
                                        expect(clipId).to(equal(UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!))
                                        expect(imageFileName).to(equal("2-1"))
                                    case 3:
                                        expect(clipId).to(equal(UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!))
                                        expect(imageFileName).to(equal("3-1"))
                                    case 4:
                                        expect(clipId).to(equal(UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!))
                                        expect(imageFileName).to(equal("3-2"))
                                    default:
                                        fail("Unexpected call")
                                        throw TestError.dummy
                                    }
                                }

                                temporaryImageStorage.deleteAllHandler = { clipId in
                                    defer { deleteAllCount += 1 }
                                    switch deleteAllCount {
                                    case 0:
                                        expect(clipId).to(equal(UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!))
                                    case 1:
                                        expect(clipId).to(equal(UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!))
                                    case 2:
                                        expect(clipId).to(equal(UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!))
                                    default:
                                        fail("Unexpected call")
                                        throw TestError.dummy
                                    }
                                }

                                result = service.persistTemporaryClips()
                            }

                            it("trueが返る") {
                                expect(result).to(beTrue())
                            }
                            it("一時保存されているクリップの読み込みが行われる") {
                                expect(temporaryClipStorage.readAllClipsCallCount).to(equal(1))
                            }
                            it("observerに進捗が通知される") {
                                expect(observer.temporariesPersistServiceCallCount).to(equal(3))
                            }
                            it("一時保存されていたクリップの永続化が実施される") {
                                expect(clipStorage.createCallCount).to(equal(3))
                            }
                            it("永続化済みの一時保存クリップを一時保存領域から削除する") {
                                expect(temporaryClipStorage.deleteClipsCallCount).to(equal(3))
                            }
                            it("画像データを一時保存領域から移動できる") {
                                expect(temporaryImageStorage.readImageCallCount).to(equal(2 + 1 + 2))
                                expect(imageStorage.createCallCount).to(equal(2 + 1 + 2))
                                expect(temporaryImageStorage.deleteCallCount).to(equal(2 + 1 + 2))
                                expect(temporaryImageStorage.deleteAllCallCount).to(equal(3))
                            }
                            it("トランザクションが開始,commitされる") {
                                expect(clipStorage.beginTransactionCallCount).to(equal(3))
                                expect(referenceClipStorage.beginTransactionCallCount).to(equal(3))
                                expect(imageStorage.beginTransactionCallCount).to(equal(3))
                                expect(temporaryClipStorage.beginTransactionCallCount).to(equal(3))

                                expect(clipStorage.commitTransactionCallCount).to(equal(3))
                                expect(referenceClipStorage.commitTransactionCallCount).to(equal(3))
                                expect(imageStorage.commitTransactionCallCount).to(equal(3))
                                expect(temporaryClipStorage.commitTransactionCallCount).to(equal(3))

                                expect(clipStorage.cancelTransactionIfNeededCallCount).to(equal(0))
                                expect(referenceClipStorage.cancelTransactionIfNeededCallCount).to(equal(0))
                                expect(imageStorage.cancelTransactionIfNeededCallCount).to(equal(0))
                                expect(temporaryClipStorage.cancelTransactionIfNeededCallCount).to(equal(0))
                            }
                        }

                        context("一時保存領域からの画像の移動に失敗する") {
                            var readImageCount = 0
                            var createImageCount = 0
                            var deleteImageCount = 0
                            var deleteAllCount = 0

                            beforeEach {
                                readImageCount = 0
                                createImageCount = 0
                                deleteImageCount = 0
                                deleteAllCount = 0
                            }

                            beforeEach {
                                temporaryImageStorage.readImageHandler = { imageFileName, clipId in
                                    defer { readImageCount += 1 }
                                    switch readImageCount {
                                    case 0:
                                        expect(clipId).to(equal(UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!))
                                        expect(imageFileName).to(equal("1-1"))
                                        return "1-1".data(using: .utf8)
                                    case 1:
                                        expect(clipId).to(equal(UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!))
                                        expect(imageFileName).to(equal("1-2"))
                                        return "1-2".data(using: .utf8)
                                    case 2:
                                        return nil
                                    case 3:
                                        expect(clipId).to(equal(UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!))
                                        expect(imageFileName).to(equal("3-1"))
                                        return "3-1".data(using: .utf8)
                                    case 4:
                                        expect(clipId).to(equal(UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!))
                                        expect(imageFileName).to(equal("3-2"))
                                        return "3-2".data(using: .utf8)
                                    default:
                                        fail("Unexpected call")
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
                                        expect(data).to(equal("3-1".data(using: .utf8)))
                                        expect(imageId).to(equal(UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E81")!))
                                    case 3:
                                        expect(data).to(equal("3-2".data(using: .utf8)))
                                        expect(imageId).to(equal(UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E82")!))
                                    default:
                                        fail("Unexpected call")
                                        throw TestError.dummy
                                    }
                                }

                                temporaryImageStorage.deleteHandler = { imageFileName, clipId in
                                    defer { deleteImageCount += 1 }
                                    switch deleteImageCount {
                                    case 0:
                                        expect(clipId).to(equal(UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!))
                                        expect(imageFileName).to(equal("1-1"))
                                    case 1:
                                        expect(clipId).to(equal(UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!))
                                        expect(imageFileName).to(equal("1-2"))
                                    case 2:
                                        throw TestError.dummy
                                    case 3:
                                        throw TestError.dummy
                                    default:
                                        fail("Unexpected call")
                                        throw TestError.dummy
                                    }
                                }

                                temporaryImageStorage.deleteAllHandler = { clipId in
                                    defer { deleteAllCount += 1 }
                                    switch deleteAllCount {
                                    case 0:
                                        expect(clipId).to(equal(UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!))
                                    case 1:
                                        expect(clipId).to(equal(UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!))
                                    case 2:
                                        expect(clipId).to(equal(UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!))
                                    default:
                                        fail("Unexpected call")
                                        throw TestError.dummy
                                    }
                                }

                                result = service.persistTemporaryClips()
                            }

                            it("trueが返る") {
                                // 画像の移動に失敗しても、trueを返す
                                expect(result).to(beTrue())
                            }
                            it("一時保存されているクリップの読み込みが行われる") {
                                expect(temporaryClipStorage.readAllClipsCallCount).to(equal(1))
                            }
                            it("observerに進捗が通知される") {
                                expect(observer.temporariesPersistServiceCallCount).to(equal(3))
                            }
                            it("一時保存されていたクリップの永続化が実施される") {
                                expect(clipStorage.createCallCount).to(equal(3))
                            }
                            it("永続化済みの一時保存クリップを一時保存領域から削除する") {
                                expect(temporaryClipStorage.deleteClipsCallCount).to(equal(3))
                            }
                            it("画像データを一時保存領域から移動できる") {
                                expect(temporaryImageStorage.readImageCallCount).to(equal(2 + 1 + 2))
                                expect(imageStorage.createCallCount).to(equal(2 /* + 1 */ + 2))
                                expect(temporaryImageStorage.deleteCallCount).to(equal(2 /* + 1 */ + 2))
                                expect(temporaryImageStorage.deleteAllCallCount).to(equal(3))
                            }
                            it("トランザクションが開始,commitされる") {
                                // 画像の移動に失敗しても、キャンセル処理は行われない

                                expect(clipStorage.beginTransactionCallCount).to(equal(3))
                                expect(referenceClipStorage.beginTransactionCallCount).to(equal(3))
                                expect(imageStorage.beginTransactionCallCount).to(equal(3))
                                expect(temporaryClipStorage.beginTransactionCallCount).to(equal(3))

                                expect(clipStorage.commitTransactionCallCount).to(equal(3))
                                expect(referenceClipStorage.commitTransactionCallCount).to(equal(3))
                                expect(imageStorage.commitTransactionCallCount).to(equal(3))
                                expect(temporaryClipStorage.commitTransactionCallCount).to(equal(3))

                                expect(clipStorage.cancelTransactionIfNeededCallCount).to(equal(0))
                                expect(referenceClipStorage.cancelTransactionIfNeededCallCount).to(equal(0))
                                expect(imageStorage.cancelTransactionIfNeededCallCount).to(equal(0))
                                expect(temporaryClipStorage.cancelTransactionIfNeededCallCount).to(equal(0))
                            }
                        }
                    }

                    context("一時保存されたクリップメタ情報の削除に失敗した") {
                        beforeEach {
                            temporaryClipStorage.deleteClipsHandler = { _ in .failure(.internalError) }

                            result = service.persistTemporaryClips()
                        }
                        it("falseが返る") {
                            expect(result).to(beFalse())
                        }
                        it("一時保存されているクリップの読み込みが行われる") {
                            expect(temporaryClipStorage.readAllClipsCallCount).to(equal(1))
                        }
                        it("observerに進捗が通知される") {
                            expect(observer.temporariesPersistServiceCallCount).to(equal(3))
                        }
                        it("一時保存されていたクリップの永続化が実施される") {
                            expect(clipStorage.createCallCount).to(equal(3))
                        }
                        it("永続化済みの一時保存クリップを一時保存領域から削除する") {
                            expect(temporaryClipStorage.deleteClipsCallCount).to(equal(3))
                        }
                        it("トランザクションが開始,キャンセルされる") {
                            expect(clipStorage.beginTransactionCallCount).to(equal(3))
                            expect(referenceClipStorage.beginTransactionCallCount).to(equal(3))
                            expect(imageStorage.beginTransactionCallCount).to(equal(3))
                            expect(temporaryClipStorage.beginTransactionCallCount).to(equal(3))

                            expect(clipStorage.commitTransactionCallCount).to(equal(0))
                            expect(referenceClipStorage.commitTransactionCallCount).to(equal(0))
                            expect(imageStorage.commitTransactionCallCount).to(equal(0))
                            expect(temporaryClipStorage.commitTransactionCallCount).to(equal(0))

                            expect(clipStorage.cancelTransactionIfNeededCallCount).to(equal(3))
                            expect(referenceClipStorage.cancelTransactionIfNeededCallCount).to(equal(3))
                            expect(imageStorage.cancelTransactionIfNeededCallCount).to(equal(3))
                            expect(temporaryClipStorage.cancelTransactionIfNeededCallCount).to(equal(3))
                        }
                    }
                }

                context("メタ情報の永続化に失敗した") {
                    beforeEach {
                        clipStorage.createHandler = { _ in .failure(.internalError) }

                        result = service.persistTemporaryClips()
                    }
                    it("falseが返る") {
                        expect(result).to(beFalse())
                    }
                    it("一時保存されているクリップの読み込みが行われる") {
                        expect(temporaryClipStorage.readAllClipsCallCount).to(equal(1))
                    }
                    it("observerに進捗が通知される") {
                        expect(observer.temporariesPersistServiceCallCount).to(equal(3))
                    }
                    it("クリップの永続化が実施される") {
                        expect(clipStorage.createCallCount).to(equal(3))
                    }
                    it("トランザクションが開始,キャンセルされる") {
                        expect(clipStorage.beginTransactionCallCount).to(equal(3))
                        expect(referenceClipStorage.beginTransactionCallCount).to(equal(3))
                        expect(imageStorage.beginTransactionCallCount).to(equal(3))
                        expect(temporaryClipStorage.beginTransactionCallCount).to(equal(3))

                        expect(clipStorage.commitTransactionCallCount).to(equal(0))
                        expect(referenceClipStorage.commitTransactionCallCount).to(equal(0))
                        expect(imageStorage.commitTransactionCallCount).to(equal(0))
                        expect(temporaryClipStorage.commitTransactionCallCount).to(equal(0))

                        expect(clipStorage.cancelTransactionIfNeededCallCount).to(equal(3))
                        expect(referenceClipStorage.cancelTransactionIfNeededCallCount).to(equal(3))
                        expect(imageStorage.cancelTransactionIfNeededCallCount).to(equal(3))
                        expect(temporaryClipStorage.cancelTransactionIfNeededCallCount).to(equal(3))
                    }
                }
            }

            context("一時保存されたクリップメタ情報を読み込めない") {
                beforeEach {
                    temporaryClipStorage.readAllClipsHandler = { .failure(.internalError) }

                    result = service.persistTemporaryClips()
                }
                it("falseが返る") {
                    expect(result).to(beFalse())
                }
                it("一時保存されているクリップの読み込みが行われる") {
                    expect(temporaryClipStorage.readAllClipsCallCount).to(equal(1))
                }
                it("トランザクションが開始されない") {
                    expect(clipStorage.beginTransactionCallCount).to(equal(0))
                    expect(referenceClipStorage.beginTransactionCallCount).to(equal(0))
                    expect(imageStorage.beginTransactionCallCount).to(equal(0))
                    expect(temporaryClipStorage.beginTransactionCallCount).to(equal(0))

                    expect(clipStorage.commitTransactionCallCount).to(equal(0))
                    expect(referenceClipStorage.commitTransactionCallCount).to(equal(0))
                    expect(imageStorage.commitTransactionCallCount).to(equal(0))
                    expect(temporaryClipStorage.commitTransactionCallCount).to(equal(0))

                    expect(clipStorage.cancelTransactionIfNeededCallCount).to(equal(0))
                    expect(referenceClipStorage.cancelTransactionIfNeededCallCount).to(equal(0))
                    expect(imageStorage.cancelTransactionIfNeededCallCount).to(equal(0))
                    expect(temporaryClipStorage.cancelTransactionIfNeededCallCount).to(equal(0))
                }
            }
        }
    }
}
