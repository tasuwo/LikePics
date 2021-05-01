//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
@testable import Domain
import Nimble
import Quick
@testable import TestHelper

class TemporariesPersistServiceSpec: QuickSpec {
    override func spec() {
        var service: TemporariesPersistService!
        var temporaryClipStorage: TemporaryClipStorageProtocolMock!
        var temporaryImageStorage: TemporaryImageStorageProtocolMock!
        var clipStorage: ClipStorageProtocolMock!
        var referenceClipStorage: ReferenceClipStorageProtocolMock!
        var imageStorage: ImageStorageProtocolMock!

        beforeEach {
            temporaryClipStorage = TemporaryClipStorageProtocolMock()
            temporaryImageStorage = TemporaryImageStorageProtocolMock()
            clipStorage = ClipStorageProtocolMock()
            referenceClipStorage = ReferenceClipStorageProtocolMock()
            imageStorage = ImageStorageProtocolMock()

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
        }

        describe("persistDirtyTags") {
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

                            result = service.persistDirtyTags()
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

                            result = service.persistDirtyTags()
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

                            result = service.persistDirtyTags()
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

                            result = service.persistDirtyTags()
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

                        result = service.persistDirtyTags()
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

                    result = service.persistDirtyTags()
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
    }
}
