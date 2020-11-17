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

        beforeEach {
            clipStorage = ClipStorageProtocolMock()
            referenceClipStorage = ReferenceClipStorageProtocolMock()
            service = ClipReferencesIntegrityValidationService(clipStorage: clipStorage,
                                                               referenceClipStorage: referenceClipStorage,
                                                               logger: RootLogger.shared,
                                                               queue: DispatchQueue(label: "net.tasuwo.TBox.ClipReferencesIntegrityValidationServiceSpec"))

            clipStorage.readAllClipsHandler = { .success([]) }
            clipStorage.readAllTagsHandler = { .success([]) }
            referenceClipStorage.readAllClipsHandler = { .success([]) }
            referenceClipStorage.readAllTagsHandler = { .success([]) }
            referenceClipStorage.updateTagHandler = { _, _ in .success(()) }
            referenceClipStorage.createTagHandler = { _ in .success(()) }
            referenceClipStorage.deleteTagsHandler = { _ in .success(()) }
            referenceClipStorage.createHandler = { _ in .success(()) }
            referenceClipStorage.deleteClipsHandler = { _ in .success(()) }
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
                        expect(referenceClipStorage.beginTransactionCallCount).to(equal(2))
                        expect(referenceClipStorage.updateTagCallCount).to(equal(0))
                        expect(referenceClipStorage.createTagCallCount).to(equal(0))
                        expect(referenceClipStorage.deleteTagsCallCount).to(equal(0))
                        expect(referenceClipStorage.createCallCount).to(equal(0))
                        expect(referenceClipStorage.commitTransactionCallCount).to(equal(2))
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
                            expect(referenceClipStorage.beginTransactionCallCount).to(equal(2))
                            expect(referenceClipStorage.updateTagCallCount).to(equal(0))
                            expect(referenceClipStorage.createTagCallCount).to(equal(0))
                            expect(referenceClipStorage.deleteTagsCallCount).to(equal(0))
                            expect(referenceClipStorage.createCallCount).to(equal(0))
                            expect(referenceClipStorage.commitTransactionCallCount).to(equal(2))
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

                                case UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!:
                                    expect(name).to(equal("pue"))

                                default:
                                    fail("Unexpected updation")
                                }

                                return .success(())
                            }
                            service.validateAndFixIntegrityIfNeeded()
                        }
                        it("整合のためにタグを更新する") {
                            expect(referenceClipStorage.beginTransactionCallCount).to(equal(2))
                            expect(referenceClipStorage.updateTagCallCount).to(equal(2))
                            expect(referenceClipStorage.createTagCallCount).to(equal(0))
                            expect(referenceClipStorage.deleteTagsCallCount).to(equal(0))
                            expect(referenceClipStorage.createCallCount).to(equal(0))
                            expect(referenceClipStorage.commitTransactionCallCount).to(equal(2))
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
                        referenceClipStorage.createTagHandler = { tag in
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
                        expect(referenceClipStorage.beginTransactionCallCount).to(equal(2))
                        expect(referenceClipStorage.updateTagCallCount).to(equal(0))
                        expect(referenceClipStorage.createTagCallCount).to(equal(2))
                        expect(referenceClipStorage.deleteTagsCallCount).to(equal(0))
                        expect(referenceClipStorage.createCallCount).to(equal(0))
                        expect(referenceClipStorage.commitTransactionCallCount).to(equal(2))
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
                            expect(referenceClipStorage.beginTransactionCallCount).to(equal(2))
                            expect(referenceClipStorage.updateTagCallCount).to(equal(0))
                            expect(referenceClipStorage.createTagCallCount).to(equal(0))
                            expect(referenceClipStorage.deleteTagsCallCount).to(equal(0))
                            expect(referenceClipStorage.createCallCount).to(equal(0))
                            expect(referenceClipStorage.commitTransactionCallCount).to(equal(2))
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
                            expect(referenceClipStorage.beginTransactionCallCount).to(equal(2))
                            expect(referenceClipStorage.updateTagCallCount).to(equal(0))
                            expect(referenceClipStorage.createTagCallCount).to(equal(0))
                            expect(referenceClipStorage.deleteTagsCallCount).to(equal(1))
                            expect(referenceClipStorage.createCallCount).to(equal(0))
                            expect(referenceClipStorage.commitTransactionCallCount).to(equal(2))
                            expect(referenceClipStorage.cancelTransactionIfNeededCallCount).to(equal(0))
                        }
                    }
                }
            }

            describe("クリップ") {
                context("クリップの整合性が取れている") {
                    beforeEach {
                        clipStorage.readAllClipsHandler = {
                            return .success([
                                .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!, description: "my description 1"),
                                .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!, description: "my description 2"),
                                .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!, description: "my description 3"),
                            ])
                        }
                        referenceClipStorage.readAllClipsHandler = {
                            return .success([
                                .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!, description: "my description 1", isDirty: false),
                                .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!, description: "my description 2", isDirty: false),
                                .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!, description: "my description 3", isDirty: false),
                            ])
                        }
                        service.validateAndFixIntegrityIfNeeded()
                    }
                    it("何もしない") {
                        expect(referenceClipStorage.beginTransactionCallCount).to(equal(2))
                        expect(referenceClipStorage.updateTagCallCount).to(equal(0))
                        expect(referenceClipStorage.createTagCallCount).to(equal(0))
                        expect(referenceClipStorage.deleteTagsCallCount).to(equal(0))
                        expect(referenceClipStorage.createCallCount).to(equal(0))
                        expect(referenceClipStorage.deleteClipsCallCount).to(equal(0))
                        expect(referenceClipStorage.commitTransactionCallCount).to(equal(2))
                        expect(referenceClipStorage.cancelTransactionIfNeededCallCount).to(equal(0))
                    }
                }

                context("内容が異なるクリップが存在する") {
                    context("Dirtyフラグが立っている") {
                        beforeEach {
                            clipStorage.readAllClipsHandler = {
                                return .success([
                                    .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!, description: "my description 1", isHidden: false),
                                    .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!, description: "my description 2", isHidden: false),
                                    .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!, description: "my description 3", isHidden: false),
                                ])
                            }
                            referenceClipStorage.readAllClipsHandler = {
                                return .success([
                                    .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!, description: "my description 1", isHidden: false, isDirty: false),
                                    .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!, description: "my new description 2", isHidden: true, isDirty: true),
                                    .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!, description: "my description 3", isHidden: false, isDirty: false),
                                ])
                            }
                            service.validateAndFixIntegrityIfNeeded()
                        }
                        it("何もしない") {
                            expect(referenceClipStorage.beginTransactionCallCount).to(equal(2))
                            expect(referenceClipStorage.updateTagCallCount).to(equal(0))
                            expect(referenceClipStorage.createTagCallCount).to(equal(0))
                            expect(referenceClipStorage.deleteTagsCallCount).to(equal(0))
                            expect(referenceClipStorage.createCallCount).to(equal(0))
                            expect(referenceClipStorage.deleteClipsCallCount).to(equal(0))
                            expect(referenceClipStorage.commitTransactionCallCount).to(equal(2))
                            expect(referenceClipStorage.cancelTransactionIfNeededCallCount).to(equal(0))
                        }
                    }

                    context("Dirtyフラグが立っていない") {
                        beforeEach {
                            clipStorage.readAllClipsHandler = {
                                return .success([
                                    .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!, description: "my description 1", isHidden: false),
                                    .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!, description: "my description 2", isHidden: false),
                                    .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!, description: "my description 3", isHidden: false),
                                ])
                            }
                            referenceClipStorage.readAllClipsHandler = {
                                return .success([
                                    .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!, description: "my description 1", isHidden: false, isDirty: false),
                                    .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!, description: "my new description 2", isHidden: true, isDirty: false),
                                    .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!, description: "my description 3", isHidden: false, isDirty: false),
                                ])
                            }
                            referenceClipStorage.createHandler = { clip in
                                expect(clip).to(equal(.makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!,
                                                                   description: "my description 2",
                                                                   isHidden: false,
                                                                   isDirty: false)))

                                return .success(())
                            }
                            service.validateAndFixIntegrityIfNeeded()
                        }
                        it("整合のためにクリップを更新する") {
                            expect(referenceClipStorage.beginTransactionCallCount).to(equal(2))
                            expect(referenceClipStorage.updateTagCallCount).to(equal(0))
                            expect(referenceClipStorage.createTagCallCount).to(equal(0))
                            expect(referenceClipStorage.deleteTagsCallCount).to(equal(0))
                            expect(referenceClipStorage.createCallCount).to(equal(1))
                            expect(referenceClipStorage.deleteClipsCallCount).to(equal(0))
                            expect(referenceClipStorage.commitTransactionCallCount).to(equal(2))
                            expect(referenceClipStorage.cancelTransactionIfNeededCallCount).to(equal(0))
                        }
                    }
                }

                context("クリップが不足している") {
                    beforeEach {
                        clipStorage.readAllClipsHandler = {
                            return .success([
                                .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!),
                                .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!),
                                .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!),
                                .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E54")!),
                            ])
                        }
                        referenceClipStorage.readAllClipsHandler = {
                            return .success([
                                .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!, isDirty: false),
                                .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!, isDirty: false),
                            ])
                        }
                        referenceClipStorage.createHandler = { clip in
                            switch clip.id {
                            case UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!:
                                expect(clip).to(equal(.makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!)))

                            case UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E54")!:
                                expect(clip).to(equal(.makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E54")!)))

                            default:
                                fail("Unexpected clip")
                            }

                            return .success(())
                        }
                        service.validateAndFixIntegrityIfNeeded()
                    }
                    it("整合のためにクリップを作成する") {
                        expect(referenceClipStorage.beginTransactionCallCount).to(equal(2))
                        expect(referenceClipStorage.updateTagCallCount).to(equal(0))
                        expect(referenceClipStorage.createTagCallCount).to(equal(0))
                        expect(referenceClipStorage.deleteTagsCallCount).to(equal(0))
                        expect(referenceClipStorage.createCallCount).to(equal(2))
                        expect(referenceClipStorage.deleteClipsCallCount).to(equal(0))
                        expect(referenceClipStorage.commitTransactionCallCount).to(equal(2))
                        expect(referenceClipStorage.cancelTransactionIfNeededCallCount).to(equal(0))
                    }
                }

                context("余分なクリップが存在する") {
                    context("Dirtyフラグが立っている") {
                        beforeEach {
                            clipStorage.readAllClipsHandler = {
                                return .success([
                                    .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!),
                                    .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!),
                                ])
                            }
                            referenceClipStorage.readAllClipsHandler = {
                                return .success([
                                    .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!, isDirty: false),
                                    .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!, isDirty: true),
                                    .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!, isDirty: false),
                                    .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E54")!, isDirty: true),
                                ])
                            }
                            service.validateAndFixIntegrityIfNeeded()
                        }
                        it("何もしない") {
                            expect(referenceClipStorage.beginTransactionCallCount).to(equal(2))
                            expect(referenceClipStorage.updateTagCallCount).to(equal(0))
                            expect(referenceClipStorage.createTagCallCount).to(equal(0))
                            expect(referenceClipStorage.deleteTagsCallCount).to(equal(0))
                            expect(referenceClipStorage.createCallCount).to(equal(0))
                            expect(referenceClipStorage.deleteClipsCallCount).to(equal(0))
                            expect(referenceClipStorage.commitTransactionCallCount).to(equal(2))
                            expect(referenceClipStorage.cancelTransactionIfNeededCallCount).to(equal(0))
                        }
                    }

                    context("Dirtyフラグが立っていない") {
                        beforeEach {
                            clipStorage.readAllClipsHandler = {
                                return .success([
                                    .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!),
                                    .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!),
                                ])
                            }
                            referenceClipStorage.readAllClipsHandler = {
                                return .success([
                                    .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!, isDirty: false),
                                    .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!, isDirty: false),
                                    .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!, isDirty: false),
                                    .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E54")!, isDirty: false),
                                ])
                            }
                            referenceClipStorage.deleteClipsHandler = { clipIds in
                                expect(Set(clipIds)).to(equal(Set([
                                    UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!,
                                    UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E54")!
                                ])))
                                return .success(())
                            }
                            service.validateAndFixIntegrityIfNeeded()
                        }
                        it("整合のためにクリップを削除する") {
                            expect(referenceClipStorage.beginTransactionCallCount).to(equal(2))
                            expect(referenceClipStorage.updateTagCallCount).to(equal(0))
                            expect(referenceClipStorage.createTagCallCount).to(equal(0))
                            expect(referenceClipStorage.deleteTagsCallCount).to(equal(0))
                            expect(referenceClipStorage.createCallCount).to(equal(0))
                            expect(referenceClipStorage.deleteClipsCallCount).to(equal(1))
                            expect(referenceClipStorage.commitTransactionCallCount).to(equal(2))
                            expect(referenceClipStorage.cancelTransactionIfNeededCallCount).to(equal(0))
                        }
                    }
                }
            }
        }
    }
}
