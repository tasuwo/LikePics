//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import Nimble
@testable import Persistence
import Quick

@testable import Domain
@testable import TestHelper

class ClipReferencesIntegrityValidationServiceSpec: QuickSpec {
    override func spec() {
        var service: ClipReferencesIntegrityValidationService!
        var clipStorage: ClipStorageProtocolMock!
        var referenceClipStorage: ReferenceClipStorageProtocolMock!
        var queue: StorageCommandQueueMock!

        beforeEach {
            clipStorage = ClipStorageProtocolMock()
            referenceClipStorage = ReferenceClipStorageProtocolMock()
            queue = StorageCommandQueueMock()
            service = ClipReferencesIntegrityValidationService(clipStorage: clipStorage,
                                                               referenceClipStorage: referenceClipStorage,
                                                               commandQueue: queue,
                                                               lock: NSRecursiveLock(),
                                                               logger: RootLogger.shared)

            queue.syncHandler = { $0() }
            queue.syncBlockHandler = { try $0() }
            clipStorage.readAllClipsHandler = { .success([]) }
            clipStorage.readAllTagsHandler = { .success([]) }
            referenceClipStorage.readAllTagsHandler = { .success([]) }
            referenceClipStorage.updateTagHandler = { _, _ in .success(()) }
            referenceClipStorage.createHandler = { _ in .success(()) }
            referenceClipStorage.deleteTagsHandler = { _ in .success(()) }
        }

        describe("validateAndFixIntegrityIfNeeded()") {
            describe("タグ") {
                context("タグの整合性が取れている") {
                    beforeEach {
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
                    }
                    it("何もしない") {
                        expect(referenceClipStorage.beginTransactionCallCount).to(equal(1))
                        expect(referenceClipStorage.updateTagCallCount).to(equal(0))
                        expect(referenceClipStorage.createCallCount).to(equal(0))
                        expect(referenceClipStorage.deleteTagsCallCount).to(equal(0))
                        expect(referenceClipStorage.createCallCount).to(equal(0))
                        expect(referenceClipStorage.commitTransactionCallCount).to(equal(1))
                        expect(referenceClipStorage.cancelTransactionIfNeededCallCount).to(equal(0))
                    }
                }

                context("名前が違うタグが存在する") {
                    context("Dirtyフラグが立っている") {
                        beforeEach {
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
                        }
                        it("何もしない") {
                            expect(referenceClipStorage.beginTransactionCallCount).to(equal(1))
                            expect(referenceClipStorage.updateTagCallCount).to(equal(0))
                            expect(referenceClipStorage.createCallCount).to(equal(0))
                            expect(referenceClipStorage.deleteTagsCallCount).to(equal(0))
                            expect(referenceClipStorage.createCallCount).to(equal(0))
                            expect(referenceClipStorage.commitTransactionCallCount).to(equal(1))
                            expect(referenceClipStorage.cancelTransactionIfNeededCallCount).to(equal(0))
                        }
                    }

                    context("Dirtyフラグが立っていない") {
                        beforeEach {
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
                                    expect(name).to(equal("fuga"))

                                case UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E54")!:
                                    expect(name).to(equal("pue"))

                                default:
                                    fail("Unexpected updation")
                                }

                                return .success(())
                            }
                            service.validateAndFixIntegrityIfNeeded()
                        }
                        it("整合のためにタグを更新する") {
                            expect(referenceClipStorage.beginTransactionCallCount).to(equal(1))
                            expect(referenceClipStorage.updateTagCallCount).to(equal(2))
                            expect(referenceClipStorage.createCallCount).to(equal(0))
                            expect(referenceClipStorage.deleteTagsCallCount).to(equal(0))
                            expect(referenceClipStorage.createCallCount).to(equal(0))
                            expect(referenceClipStorage.commitTransactionCallCount).to(equal(1))
                            expect(referenceClipStorage.cancelTransactionIfNeededCallCount).to(equal(0))
                        }
                    }
                }

                context("タグが不足している") {
                    beforeEach {
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
                                expect(tag).to(equal(.makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!, name: "fuga", isDirty: false)))

                            case UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E54")!:
                                expect(tag).to(equal(.makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E54")!, name: "pon", isDirty: false)))

                            default:
                                fail("Unexpected updation")
                            }

                            return .success(())
                        }
                        service.validateAndFixIntegrityIfNeeded()
                    }
                    it("整合のためにタグを追加する") {
                        expect(referenceClipStorage.beginTransactionCallCount).to(equal(1))
                        expect(referenceClipStorage.updateTagCallCount).to(equal(0))
                        expect(referenceClipStorage.deleteTagsCallCount).to(equal(0))
                        expect(referenceClipStorage.createCallCount).to(equal(2))
                        expect(referenceClipStorage.commitTransactionCallCount).to(equal(1))
                        expect(referenceClipStorage.cancelTransactionIfNeededCallCount).to(equal(0))
                    }
                }

                context("余分なタグが存在している") {
                    context("Dirtyフラグが立っている") {
                        beforeEach {
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
                        }
                        it("何もしない") {
                            expect(referenceClipStorage.beginTransactionCallCount).to(equal(1))
                            expect(referenceClipStorage.updateTagCallCount).to(equal(0))
                            expect(referenceClipStorage.createCallCount).to(equal(0))
                            expect(referenceClipStorage.deleteTagsCallCount).to(equal(0))
                            expect(referenceClipStorage.createCallCount).to(equal(0))
                            expect(referenceClipStorage.commitTransactionCallCount).to(equal(1))
                            expect(referenceClipStorage.cancelTransactionIfNeededCallCount).to(equal(0))
                        }
                    }

                    context("Dirtyフラグが立っていない") {
                        beforeEach {
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
                                expect(Set(tagIds)).to(equal(Set([
                                    UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E50")!,
                                    UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!,
                                    UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E54")!
                                ])))
                                return .success(())
                            }
                            service.validateAndFixIntegrityIfNeeded()
                        }
                        it("整合のためにタグを削除する") {
                            expect(referenceClipStorage.beginTransactionCallCount).to(equal(1))
                            expect(referenceClipStorage.updateTagCallCount).to(equal(0))
                            expect(referenceClipStorage.createCallCount).to(equal(0))
                            expect(referenceClipStorage.deleteTagsCallCount).to(equal(1))
                            expect(referenceClipStorage.createCallCount).to(equal(0))
                            expect(referenceClipStorage.commitTransactionCallCount).to(equal(1))
                            expect(referenceClipStorage.cancelTransactionIfNeededCallCount).to(equal(0))
                        }
                    }
                }
            }
        }
    }
}
