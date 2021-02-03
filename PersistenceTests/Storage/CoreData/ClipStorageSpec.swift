//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import CoreData
import Domain

import Nimble
import Quick

@testable import Persistence
@testable import TestHelper

class ClipStorageSpec: QuickSpec {
    func coreDataStack() -> NSPersistentContainer {
        let bundle = Bundle(for: PersistentContainerLoader.Class.self)
        guard let url = bundle.url(forResource: "Model", withExtension: "momd"),
              let model = NSManagedObjectModel(contentsOf: url)
        else {
            fatalError("Unable to load Core Data Model")
        }
        let container = NSPersistentContainer(name: "Model", managedObjectModel: model)

        let persistentStoreDescription = NSPersistentStoreDescription()
        persistentStoreDescription.url = URL(fileURLWithPath: "/dev/null")
        container.persistentStoreDescriptions = [persistentStoreDescription]

        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Unresolved error: \(error.localizedDescription)")
            }
        }

        return container
    }

    override func spec() {
        var container: NSPersistentContainer!
        var managedContext: NSManagedObjectContext!
        var service: ClipStorage!

        beforeEach {
            container = self.coreDataStack()
            managedContext = container.newBackgroundContext()
            service = ClipStorage(context: managedContext)
        }

        describe("create(clip:overwrite:)") {
            context("overwrite==true") {
                context("同一IDの既存のクリップが存在しない") {
                    // TODO:
                }
                context("同一IDの既存のクリップが存在する") {
                    // TODO:
                    it("正常に保存できる") {
                    }
                    it("古いClipItem群は削除される") {
                    }
                }
            }

            context("overwrite==false") {
                context("同一IDの既存のクリップが存在しない") {
                    // TODO:
                }
                context("同一IDの既存のクリップが存在する") {
                    // TODO:
                    it("エラーとなる") {
                    }
                }
            }

            context("IDが同一の既存のタグが存在する") {
                beforeEach {
                    let tag = Persistence.Tag(context: managedContext)
                    tag.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                    tag.name = "hoge"
                    try! managedContext.save()

                    _ = service.create(clip: .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!,
                                                          tagIds: [UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!]))
                }
                it("既存のタグを付与したクリップが保存される") {
                    let request: NSFetchRequest<Persistence.Clip> = Clip.fetchRequest()
                    request.predicate = NSPredicate(format: "id == %@", UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")! as CVarArg)
                    let clip = try! managedContext.fetch(request).first!
                    let tags = clip.tags?.allObjects.compactMap { $0 as? Persistence.Tag }
                    expect(tags).to(haveCount(1))
                    expect(tags!.first!.id).to(equal(UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!))
                    expect(tags!.first!.name).to(equal("hoge"))
                }
                it("新規にタグは作成されない") {
                    let request: NSFetchRequest<Persistence.Tag> = Persistence.Tag.fetchRequest()
                    let tags = try! managedContext.fetch(request)
                    expect(tags).to(haveCount(1))
                }
            }

            context("IDは異なるが名前が同一の既存のタグが存在する") {
                beforeEach {
                    let tag = Persistence.Tag(context: managedContext)
                    tag.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E59")
                    tag.name = "hoge"
                    try! managedContext.save()

                    _ = service.create(clip: .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!,
                                                          tagIds: [UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!]))
                }
                it("既存のタグを付与したクリップが保存される") {
                    let request: NSFetchRequest<Persistence.Clip> = Clip.fetchRequest()
                    request.predicate = NSPredicate(format: "id == %@", UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")! as CVarArg)
                    let clip = try! managedContext.fetch(request).first!
                    let tags = clip.tags?.allObjects.compactMap { $0 as? Persistence.Tag }
                    expect(tags).to(haveCount(0))
                }
                it("新規にタグは作成されない") {
                    let request: NSFetchRequest<Persistence.Tag> = Persistence.Tag.fetchRequest()
                    let tags = try! managedContext.fetch(request)
                    expect(tags).to(haveCount(1))
                }
            }

            context("ID/名前が同一の既存のタグが存在しない") {
                beforeEach {
                    let tag = Persistence.Tag(context: managedContext)
                    tag.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E59")
                    tag.name = "fuga"
                    try! managedContext.save()

                    _ = service.create(clip: .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!,
                                                          tagIds: [UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!]))
                }
                it("タグの付与がスキップされる") {
                    let request: NSFetchRequest<Persistence.Clip> = Clip.fetchRequest()
                    request.predicate = NSPredicate(format: "id == %@", UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")! as CVarArg)
                    let clip = try! managedContext.fetch(request).first!
                    let tags = clip.tags?.allObjects.compactMap { $0 as? Persistence.Tag }
                    expect(tags).to(haveCount(0))
                }
                it("新規にタグは作成されない") {
                    let request: NSFetchRequest<Persistence.Tag> = Persistence.Tag.fetchRequest()
                    let tags = try! managedContext.fetch(request)
                    expect(tags).to(haveCount(1))
                }
            }
        }

        describe("updateClips(having:byAddingTagsHaving:)") {
            context("追加対象のタグが全て存在") {
                context("全てのタグが未追加") {
                    beforeEach {
                        let tag1 = Persistence.Tag(context: managedContext)
                        tag1.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                        tag1.name = "hoge"
                        let tag2 = Persistence.Tag(context: managedContext)
                        tag2.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")
                        tag2.name = "fuga"
                        let clip = Persistence.Clip(context: managedContext)
                        clip.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                        clip.descriptionText = "piyo"
                        clip.updatedDate = Date(timeIntervalSince1970: 0)
                        try! managedContext.save()

                        _ = service.updateClips(having: [UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!],
                                                byAddingTagsHaving: [
                                                    UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!,
                                                    UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!
                                                ])
                        try! managedContext.save()
                    }
                    it("追加でき、更新される") {
                        let request: NSFetchRequest<Persistence.Clip> = Clip.fetchRequest()
                        request.predicate = NSPredicate(format: "id == %@",
                                                        UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")! as CVarArg)
                        let clip = try! managedContext.fetch(request).first!
                        let tags = clip.tags?
                            .allObjects
                            .compactMap { $0 as? Persistence.Tag }
                        expect(tags).to(haveCount(2))
                        expect(tags?.first(where: { $0.name == "hoge" })).notTo(beNil())
                        expect(tags?.first(where: { $0.name == "fuga" })).notTo(beNil())
                        expect(clip.updatedDate).notTo(equal(Date(timeIntervalSince1970: 0)))
                    }
                }
                context("一部タグが追加済み") {
                    beforeEach {
                        let tag1 = Persistence.Tag(context: managedContext)
                        tag1.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                        tag1.name = "hoge"
                        let tag2 = Persistence.Tag(context: managedContext)
                        tag2.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")
                        tag2.name = "fuga"
                        let clip = Persistence.Clip(context: managedContext)
                        clip.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                        clip.descriptionText = "piyo"
                        clip.tags = NSSet(array: [tag2])
                        clip.updatedDate = Date(timeIntervalSince1970: 0)
                        try! managedContext.save()

                        _ = service.updateClips(having: [UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!],
                                                byAddingTagsHaving: [
                                                    UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!,
                                                    UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!
                                                ])
                        try! managedContext.save()
                    }
                    it("未追加のタグのみ追加され、更新される") {
                        let request: NSFetchRequest<Persistence.Clip> = Clip.fetchRequest()
                        request.predicate = NSPredicate(format: "id == %@",
                                                        UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")! as CVarArg)
                        let clip = try! managedContext.fetch(request).first!
                        let tags = clip.tags?
                            .allObjects
                            .compactMap { $0 as? Persistence.Tag }
                        expect(tags).to(haveCount(2))
                        expect(tags?.first(where: { $0.name == "hoge" })).notTo(beNil())
                        expect(tags?.first(where: { $0.name == "fuga" })).notTo(beNil())
                        expect(clip.updatedDate).notTo(equal(Date(timeIntervalSince1970: 0)))
                    }
                }
                context("全タグが追加済み") {
                    beforeEach {
                        let tag1 = Persistence.Tag(context: managedContext)
                        tag1.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                        tag1.name = "hoge"
                        let tag2 = Persistence.Tag(context: managedContext)
                        tag2.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")
                        tag2.name = "fuga"
                        let clip = Persistence.Clip(context: managedContext)
                        clip.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                        clip.descriptionText = "piyo"
                        clip.tags = NSSet(array: [tag1, tag2])
                        clip.updatedDate = Date(timeIntervalSince1970: 0)
                        try! managedContext.save()

                        _ = service.updateClips(having: [UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!],
                                                byAddingTagsHaving: [
                                                    UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!,
                                                    UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!
                                                ])
                        try! managedContext.save()
                    }
                    it("更新されない") {
                        let request: NSFetchRequest<Persistence.Clip> = Clip.fetchRequest()
                        request.predicate = NSPredicate(format: "id == %@",
                                                        UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")! as CVarArg)
                        let clip = try! managedContext.fetch(request).first!
                        let tags = clip.tags?
                            .allObjects
                            .compactMap { $0 as? Persistence.Tag }
                        expect(tags).to(haveCount(2))
                        expect(tags?.first(where: { $0.name == "hoge" })).notTo(beNil())
                        expect(tags?.first(where: { $0.name == "fuga" })).notTo(beNil())
                        expect(clip.updatedDate).to(equal(Date(timeIntervalSince1970: 0)))
                    }
                }
            }
        }

        describe("updateClips(having:byDeletingTagsHaving:)") {
            context("削除対象のタグが全て存在") {
                context("全タグが追加済み") {
                    beforeEach {
                        let tag1 = Persistence.Tag(context: managedContext)
                        tag1.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                        tag1.name = "hoge"
                        let tag2 = Persistence.Tag(context: managedContext)
                        tag2.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")
                        tag2.name = "fuga"
                        let clip = Persistence.Clip(context: managedContext)
                        clip.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                        clip.descriptionText = "piyo"
                        clip.tags = NSSet(array: [tag1, tag2])
                        clip.updatedDate = Date(timeIntervalSince1970: 0)
                        try! managedContext.save()

                        _ = service.updateClips(having: [UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!],
                                                byDeletingTagsHaving: [
                                                    UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!,
                                                    UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!
                                                ])
                        try! managedContext.save()
                    }
                    it("タグが削除され、更新される") {
                        let request: NSFetchRequest<Persistence.Clip> = Clip.fetchRequest()
                        request.predicate = NSPredicate(format: "id == %@",
                                                        UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")! as CVarArg)
                        let clip = try! managedContext.fetch(request).first!
                        let tags = clip.tags?
                            .allObjects
                            .compactMap { $0 as? Persistence.Tag }
                        expect(tags).to(haveCount(0))
                        expect(clip.updatedDate).notTo(equal(Date(timeIntervalSince1970: 0)))
                    }
                }
                context("一部タグが追加済み") {
                    beforeEach {
                        let tag1 = Persistence.Tag(context: managedContext)
                        tag1.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                        tag1.name = "hoge"
                        let tag2 = Persistence.Tag(context: managedContext)
                        tag2.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")
                        tag2.name = "fuga"
                        let clip = Persistence.Clip(context: managedContext)
                        clip.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                        clip.descriptionText = "piyo"
                        clip.tags = NSSet(array: [tag2])
                        clip.updatedDate = Date(timeIntervalSince1970: 0)
                        try! managedContext.save()

                        _ = service.updateClips(having: [UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!],
                                                byDeletingTagsHaving: [
                                                    UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!,
                                                    UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!
                                                ])
                        try! managedContext.save()
                    }
                    it("追加済みのタグが削除され、更新される") {
                        let request: NSFetchRequest<Persistence.Clip> = Clip.fetchRequest()
                        request.predicate = NSPredicate(format: "id == %@",
                                                        UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")! as CVarArg)
                        let clip = try! managedContext.fetch(request).first!
                        let tags = clip.tags?
                            .allObjects
                            .compactMap { $0 as? Persistence.Tag }
                        expect(tags).to(haveCount(0))
                        expect(clip.updatedDate).notTo(equal(Date(timeIntervalSince1970: 0)))
                    }
                }
                context("全てのタグが未追加") {
                    beforeEach {
                        let tag1 = Persistence.Tag(context: managedContext)
                        tag1.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                        tag1.name = "hoge"
                        let tag2 = Persistence.Tag(context: managedContext)
                        tag2.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")
                        tag2.name = "fuga"
                        let clip = Persistence.Clip(context: managedContext)
                        clip.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                        clip.descriptionText = "piyo"
                        clip.updatedDate = Date(timeIntervalSince1970: 0)
                        try! managedContext.save()

                        _ = service.updateClips(having: [UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!],
                                                byDeletingTagsHaving: [
                                                    UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!,
                                                    UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!
                                                ])
                        try! managedContext.save()
                    }
                    it("更新されない") {
                        let request: NSFetchRequest<Persistence.Clip> = Clip.fetchRequest()
                        request.predicate = NSPredicate(format: "id == %@",
                                                        UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")! as CVarArg)
                        let clip = try! managedContext.fetch(request).first!
                        let tags = clip.tags?
                            .allObjects
                            .compactMap { $0 as? Persistence.Tag }
                        expect(tags).to(haveCount(0))
                        expect(clip.updatedDate).to(equal(Date(timeIntervalSince1970: 0)))
                    }
                }
            }
        }

        describe("updateClips(having:byReplacingTagsHaving:)") {
            context("置換対象のタグが全て存在") {
                context("全タグが追加済み") {
                    beforeEach {
                        let tag1 = Persistence.Tag(context: managedContext)
                        tag1.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                        tag1.name = "hoge"
                        let tag2 = Persistence.Tag(context: managedContext)
                        tag2.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")
                        tag2.name = "fuga"
                        let clip = Persistence.Clip(context: managedContext)
                        clip.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                        clip.descriptionText = "piyo"
                        clip.tags = NSSet(array: [tag1, tag2])
                        clip.updatedDate = Date(timeIntervalSince1970: 0)
                        try! managedContext.save()

                        _ = service.updateClips(having: [UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!],
                                                byReplacingTagsHaving: [
                                                    UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!,
                                                    UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!
                                                ])
                        try! managedContext.save()
                    }
                    it("タグが置換される") {
                        let request: NSFetchRequest<Persistence.Clip> = Clip.fetchRequest()
                        request.predicate = NSPredicate(format: "id == %@",
                                                        UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")! as CVarArg)
                        let clip = try! managedContext.fetch(request).first!
                        let tags = clip.tags?
                            .allObjects
                            .compactMap { $0 as? Persistence.Tag }
                        expect(tags?.first(where: { $0.name == "hoge" })).notTo(beNil())
                        expect(tags?.first(where: { $0.name == "fuga" })).notTo(beNil())
                        expect(clip.updatedDate).notTo(equal(Date(timeIntervalSince1970: 0)))
                    }
                }
                context("一部タグが追加済み") {
                    beforeEach {
                        let tag1 = Persistence.Tag(context: managedContext)
                        tag1.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                        tag1.name = "hoge"
                        let tag2 = Persistence.Tag(context: managedContext)
                        tag2.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")
                        tag2.name = "fuga"
                        let clip = Persistence.Clip(context: managedContext)
                        clip.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                        clip.descriptionText = "piyo"
                        clip.tags = NSSet(array: [tag2])
                        clip.updatedDate = Date(timeIntervalSince1970: 0)
                        try! managedContext.save()

                        _ = service.updateClips(having: [UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!],
                                                byReplacingTagsHaving: [
                                                    UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!,
                                                    UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!
                                                ])
                        try! managedContext.save()
                    }
                    it("タグが置換される") {
                        let request: NSFetchRequest<Persistence.Clip> = Clip.fetchRequest()
                        request.predicate = NSPredicate(format: "id == %@",
                                                        UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")! as CVarArg)
                        let clip = try! managedContext.fetch(request).first!
                        let tags = clip.tags?
                            .allObjects
                            .compactMap { $0 as? Persistence.Tag }
                        expect(tags?.first(where: { $0.name == "hoge" })).notTo(beNil())
                        expect(tags?.first(where: { $0.name == "fuga" })).notTo(beNil())
                        expect(clip.updatedDate).notTo(equal(Date(timeIntervalSince1970: 0)))
                    }
                }
                context("全てのタグが未追加") {
                    beforeEach {
                        let tag1 = Persistence.Tag(context: managedContext)
                        tag1.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                        tag1.name = "hoge"
                        let tag2 = Persistence.Tag(context: managedContext)
                        tag2.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")
                        tag2.name = "fuga"
                        let clip = Persistence.Clip(context: managedContext)
                        clip.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                        clip.descriptionText = "piyo"
                        clip.updatedDate = Date(timeIntervalSince1970: 0)
                        try! managedContext.save()

                        _ = service.updateClips(having: [UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!],
                                                byReplacingTagsHaving: [
                                                    UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!,
                                                    UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!
                                                ])
                        try! managedContext.save()
                    }
                    it("タグが置換される") {
                        let request: NSFetchRequest<Persistence.Clip> = Clip.fetchRequest()
                        request.predicate = NSPredicate(format: "id == %@",
                                                        UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")! as CVarArg)
                        let clip = try! managedContext.fetch(request).first!
                        let tags = clip.tags?
                            .allObjects
                            .compactMap { $0 as? Persistence.Tag }
                        expect(tags?.first(where: { $0.name == "hoge" })).notTo(beNil())
                        expect(tags?.first(where: { $0.name == "fuga" })).notTo(beNil())
                        expect(clip.updatedDate).notTo(equal(Date(timeIntervalSince1970: 0)))
                    }
                }
            }
        }

        describe("updateAlbum(having:byAddingClipsHaving:)") {
            var result: Result<Void, ClipStorageError>!
            context("追加対象のクリップが追加済み") {
                beforeEach {
                    let clip1 = Persistence.Clip(context: managedContext)
                    clip1.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                    let clip2 = Persistence.Clip(context: managedContext)
                    clip2.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")

                    let item1 = AlbumItem(context: managedContext)
                    item1.clip = clip1
                    item1.index = 1
                    let item2 = AlbumItem(context: managedContext)
                    item2.clip = clip2
                    item2.index = 2

                    let album = Album(context: managedContext)
                    album.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                    album.items = NSSet(array: [item1, item2])

                    try! managedContext.save()

                    result = service.updateAlbum(having: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!,
                                                 byAddingClipsHaving: [
                                                     UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!,
                                                     UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!
                                                 ])
                    try! managedContext.save()
                }
                it("エラーとなる") {
                    guard case .failure(.duplicated) = result else {
                        fail()
                        return
                    }
                }
            }
            context("追加対象のクリップが未追加") {
                context("クリップを初めて追加する") {
                    beforeEach {
                        let clip1 = Persistence.Clip(context: managedContext)
                        clip1.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                        let clip2 = Persistence.Clip(context: managedContext)
                        clip2.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")

                        let album = Album(context: managedContext)
                        album.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")

                        try! managedContext.save()

                        _ = service.updateAlbum(having: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!,
                                                byAddingClipsHaving: [
                                                    UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!,
                                                    UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!
                                                ])
                        try! managedContext.save()
                    }
                    it("クリップが追加できる") {
                        let request: NSFetchRequest<Persistence.Album> = Album.fetchRequest()
                        request.predicate = NSPredicate(format: "id == %@",
                                                        UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")! as CVarArg)
                        let album = try! managedContext.fetch(request).first!
                        expect(album.items?.allObjects).to(haveCount(2))

                        guard let item1 = album.items?
                            .allObjects
                            .compactMap({ $0 as? AlbumItem })
                            .first(where: { $0.clip?.id == UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")! })
                        else {
                            fail()
                            return
                        }
                        expect(item1.index).to(equal(1))

                        guard let item2 = album.items?
                            .allObjects
                            .compactMap({ $0 as? AlbumItem })
                            .first(where: { $0.clip?.id == UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")! })
                        else {
                            fail()
                            return
                        }
                        expect(item2.index).to(equal(2))
                    }
                }
                context("既に追加済みのクリップがある") {
                    beforeEach {
                        let clip1 = Persistence.Clip(context: managedContext)
                        clip1.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                        let clip2 = Persistence.Clip(context: managedContext)
                        clip2.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")
                        let clip3 = Persistence.Clip(context: managedContext)
                        clip3.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")
                        let clip4 = Persistence.Clip(context: managedContext)
                        clip4.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E54")

                        let item1 = AlbumItem(context: managedContext)
                        item1.clip = clip1
                        item1.index = 1
                        let item2 = AlbumItem(context: managedContext)
                        item2.clip = clip2
                        item2.index = 2

                        let album = Album(context: managedContext)
                        album.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                        album.items = NSSet(array: [item1, item2])

                        try! managedContext.save()

                        _ = service.updateAlbum(having: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!,
                                                byAddingClipsHaving: [
                                                    UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E54")!,
                                                    UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!
                                                ])
                        try! managedContext.save()
                    }
                    it("クリップが追加できる") {
                        let request: NSFetchRequest<Persistence.Album> = Album.fetchRequest()
                        request.predicate = NSPredicate(format: "id == %@",
                                                        UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")! as CVarArg)
                        let album = try! managedContext.fetch(request).first!
                        expect(album.items?.allObjects).to(haveCount(4))

                        guard let item3 = album.items?
                            .allObjects
                            .compactMap({ $0 as? AlbumItem })
                            .first(where: { $0.clip?.id == UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E54")! })
                        else {
                            fail()
                            return
                        }
                        expect(item3.index).to(equal(3))

                        guard let item4 = album.items?
                            .allObjects
                            .compactMap({ $0 as? AlbumItem })
                            .first(where: { $0.clip?.id == UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")! })
                        else {
                            fail()
                            return
                        }
                        expect(item4.index).to(equal(4))
                    }
                }
            }
        }

        describe("updateAlbum(having:byDeletingClipsHaving:)") {
            var result: Result<Void, ClipStorageError>!
            context("削除対象のクリップが一部存在しない") {
                beforeEach {
                    let clip1 = Persistence.Clip(context: managedContext)
                    clip1.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                    let clip2 = Persistence.Clip(context: managedContext)
                    clip2.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")
                    let clip3 = Persistence.Clip(context: managedContext)
                    clip3.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")
                    let clip4 = Persistence.Clip(context: managedContext)
                    clip4.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E54")

                    let item1 = AlbumItem(context: managedContext)
                    item1.clip = clip1
                    item1.index = 1
                    let item2 = AlbumItem(context: managedContext)
                    item2.clip = clip2
                    item2.index = 2
                    let item3 = AlbumItem(context: managedContext)
                    item3.clip = clip3
                    item3.index = 3
                    let item4 = AlbumItem(context: managedContext)
                    item4.clip = clip4
                    item4.index = 4

                    let album = Album(context: managedContext)
                    album.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                    album.items = NSSet(array: [item1, item2, item4])

                    try! managedContext.save()

                    result = service.updateAlbum(having: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!,
                                                 byDeletingClipsHaving: [
                                                     UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!,
                                                     UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!
                                                 ])
                    try! managedContext.save()
                }
                it("エラーとなる") {
                    guard case .failure(.notFound) = result else {
                        fail()
                        return
                    }
                }
            }
            context("削除対象のクリップが全て存在する") {
                context("一部のクリップを削除する") {
                    beforeEach {
                        let clip1 = Persistence.Clip(context: managedContext)
                        clip1.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                        let clip2 = Persistence.Clip(context: managedContext)
                        clip2.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")
                        let clip3 = Persistence.Clip(context: managedContext)
                        clip3.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")
                        let clip4 = Persistence.Clip(context: managedContext)
                        clip4.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E54")

                        let item1 = AlbumItem(context: managedContext)
                        item1.clip = clip1
                        item1.index = 1
                        let item2 = AlbumItem(context: managedContext)
                        item2.clip = clip2
                        item2.index = 2
                        let item3 = AlbumItem(context: managedContext)
                        item3.clip = clip3
                        item3.index = 3
                        let item4 = AlbumItem(context: managedContext)
                        item4.clip = clip4
                        item4.index = 4

                        let album = Album(context: managedContext)
                        album.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                        album.items = NSSet(array: [item1, item2, item3, item4])

                        try! managedContext.save()

                        result = service.updateAlbum(having: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!,
                                                     byDeletingClipsHaving: [
                                                         UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!,
                                                         UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!
                                                     ])
                        try! managedContext.save()
                    }
                    it("削除され、indexが更新される") {
                        guard case .success = result else {
                            fail()
                            return
                        }
                        let request: NSFetchRequest<Persistence.Album> = Album.fetchRequest()
                        request.predicate = NSPredicate(format: "id == %@",
                                                        UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")! as CVarArg)
                        let album = try! managedContext.fetch(request).first!
                        expect(album.items?.allObjects).to(haveCount(2))

                        guard let item2 = album.items?
                            .allObjects
                            .compactMap({ $0 as? AlbumItem })
                            .first(where: { $0.clip?.id == UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")! })
                        else {
                            fail()
                            return
                        }
                        expect(item2.index).to(equal(1))

                        guard let item4 = album.items?
                            .allObjects
                            .compactMap({ $0 as? AlbumItem })
                            .first(where: { $0.clip?.id == UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E54")! })
                        else {
                            fail()
                            return
                        }
                        expect(item4.index).to(equal(2))
                    }
                    it("AlbumItemも削除される") {
                        let request: NSFetchRequest<AlbumItem> = AlbumItem.fetchRequest()
                        let items = try! managedContext.fetch(request)
                        expect(items).to(haveCount(2))
                    }
                    it("Clipは削除されない") {
                        let request: NSFetchRequest<Persistence.Clip> = Clip.fetchRequest()
                        let clips = try! managedContext.fetch(request)
                        expect(clips).to(haveCount(4))
                    }
                }
            }
        }

        describe("updateAlbum(having:byReorderingClipsHaving:)") {
            var result: Result<Void, ClipStorageError>!
            context("並び替え対象のクリップが足りない") {
                beforeEach {
                    let clip1 = Persistence.Clip(context: managedContext)
                    clip1.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                    let clip2 = Persistence.Clip(context: managedContext)
                    clip2.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")
                    let clip3 = Persistence.Clip(context: managedContext)
                    clip3.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")
                    let clip4 = Persistence.Clip(context: managedContext)
                    clip4.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E54")

                    let item1 = AlbumItem(context: managedContext)
                    item1.clip = clip1
                    item1.index = 1
                    let item2 = AlbumItem(context: managedContext)
                    item2.clip = clip2
                    item2.index = 2
                    let item3 = AlbumItem(context: managedContext)
                    item3.clip = clip3
                    item3.index = 3
                    let item4 = AlbumItem(context: managedContext)
                    item4.clip = clip4
                    item4.index = 4

                    let album = Album(context: managedContext)
                    album.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                    album.items = NSSet(array: [item1, item2, item3, item4])

                    try! managedContext.save()

                    result = service.updateAlbum(having: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!,
                                                 byReorderingClipsHaving: [
                                                     UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!,
                                                     UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!,
                                                     UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E54")!,
                                                 ])
                    try! managedContext.save()
                }
                it("エラーとなる") {
                    guard case .failure(.invalidParameter) = result else {
                        fail()
                        return
                    }
                }
            }
            context("並び替え対象のクリップが一部存在しない") {
                beforeEach {
                    let clip1 = Persistence.Clip(context: managedContext)
                    clip1.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                    let clip2 = Persistence.Clip(context: managedContext)
                    clip2.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")
                    let clip3 = Persistence.Clip(context: managedContext)
                    clip3.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")
                    let clip4 = Persistence.Clip(context: managedContext)
                    clip4.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E54")

                    let item1 = AlbumItem(context: managedContext)
                    item1.clip = clip1
                    item1.index = 1
                    let item2 = AlbumItem(context: managedContext)
                    item2.clip = clip2
                    item2.index = 2
                    let item3 = AlbumItem(context: managedContext)
                    item3.clip = clip3
                    item3.index = 3
                    let item4 = AlbumItem(context: managedContext)
                    item4.clip = clip4
                    item4.index = 4

                    let album = Album(context: managedContext)
                    album.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                    album.items = NSSet(array: [item1, item2, item4])

                    try! managedContext.save()

                    result = service.updateAlbum(having: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!,
                                                 byReorderingClipsHaving: [
                                                     UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!,
                                                     UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!,
                                                     UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!,
                                                     UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E54")!,
                                                 ])
                    try! managedContext.save()
                }
                it("エラーとなる") {
                    guard case .failure(.invalidParameter) = result else {
                        fail()
                        return
                    }
                }
            }
            context("並び替え対象のクリップが全て存在する") {
                context("並び替える") {
                    beforeEach {
                        let clip1 = Persistence.Clip(context: managedContext)
                        clip1.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                        let clip2 = Persistence.Clip(context: managedContext)
                        clip2.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")
                        let clip3 = Persistence.Clip(context: managedContext)
                        clip3.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")
                        let clip4 = Persistence.Clip(context: managedContext)
                        clip4.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E54")

                        let item1 = AlbumItem(context: managedContext)
                        item1.clip = clip1
                        item1.index = 1
                        let item2 = AlbumItem(context: managedContext)
                        item2.clip = clip2
                        item2.index = 2
                        let item3 = AlbumItem(context: managedContext)
                        item3.clip = clip3
                        item3.index = 3
                        let item4 = AlbumItem(context: managedContext)
                        item4.clip = clip4
                        item4.index = 4

                        let album = Album(context: managedContext)
                        album.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                        album.items = NSSet(array: [item1, item2, item3, item4])

                        try! managedContext.save()

                        result = service.updateAlbum(having: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!,
                                                     byReorderingClipsHaving: [
                                                         UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!,
                                                         UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!,
                                                         UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!,
                                                         UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E54")!,
                                                     ])
                        try! managedContext.save()
                    }
                    it("並び替えた順にindexが更新される") {
                        guard case .success = result else {
                            fail()
                            return
                        }
                        let request: NSFetchRequest<Persistence.Album> = Album.fetchRequest()
                        request.predicate = NSPredicate(format: "id == %@",
                                                        UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")! as CVarArg)
                        let album = try! managedContext.fetch(request).first!
                        expect(album.items?.allObjects).to(haveCount(4))

                        guard let item1 = album.items?
                            .allObjects
                            .compactMap({ $0 as? AlbumItem })
                            .first(where: { $0.clip?.id == UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")! })
                        else {
                            fail()
                            return
                        }
                        expect(item1.index).to(equal(1))

                        guard let item2 = album.items?
                            .allObjects
                            .compactMap({ $0 as? AlbumItem })
                            .first(where: { $0.clip?.id == UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")! })
                        else {
                            fail()
                            return
                        }
                        expect(item2.index).to(equal(3))

                        guard let item3 = album.items?
                            .allObjects
                            .compactMap({ $0 as? AlbumItem })
                            .first(where: { $0.clip?.id == UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")! })
                        else {
                            fail()
                            return
                        }
                        expect(item3.index).to(equal(2))

                        guard let item4 = album.items?
                            .allObjects
                            .compactMap({ $0 as? AlbumItem })
                            .first(where: { $0.clip?.id == UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E54")! })
                        else {
                            fail()
                            return
                        }
                        expect(item4.index).to(equal(4))
                    }
                }
            }
        }

        describe("deleteClips(having:)") {
            beforeEach {
                let clip = Persistence.Clip(context: managedContext)
                clip.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                clip.createdDate = Date(timeIntervalSince1970: 0)
                clip.updatedDate = Date(timeIntervalSince1970: 0)

                let item1 = Item(context: managedContext)
                item1.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                let item2 = Item(context: managedContext)
                item2.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")

                clip.clipItems = NSSet(array: [item1, item2])

                let albumItem = AlbumItem(context: managedContext)
                albumItem.clip = clip
                albumItem.index = 1

                let album = Album(context: managedContext)
                album.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                album.items = NSSet(array: [albumItem])

                try! managedContext.save()

                _ = service.deleteClips(having: [UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!])

                try! managedContext.save()
            }
            it("Clipが削除される") {
                let request: NSFetchRequest<Persistence.Clip> = Clip.fetchRequest()
                let clips = try! managedContext.fetch(request)
                expect(clips).to(haveCount(0))
            }
            it("ClipItemが削除される") {
                let request: NSFetchRequest<Item> = Item.fetchRequest()
                let items = try! managedContext.fetch(request)
                expect(items).to(haveCount(0))
            }
            it("AlbumItemが削除される") {
                let request: NSFetchRequest<AlbumItem> = AlbumItem.fetchRequest()
                let items = try! managedContext.fetch(request)
                expect(items).to(haveCount(0))
            }
            it("Albumは削除されない") {
                let request: NSFetchRequest<Persistence.Album> = Album.fetchRequest()
                let albums = try! managedContext.fetch(request)
                expect(albums).to(haveCount(1))
                expect(albums.first?.items).to(haveCount(0))
            }
        }

        describe("deleteClipItem(having:)") {
            beforeEach {
                let clip = Persistence.Clip(context: managedContext)
                clip.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                clip.imagesSize = 12 + 34 + 56 + 78

                let item1 = Item(context: managedContext)
                item1.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                item1.clipId = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                item1.imageId = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                item1.createdDate = Date(timeIntervalSince1970: 0)
                item1.updatedDate = Date(timeIntervalSince1970: 0)
                item1.imageSize = 12
                item1.clip = clip
                item1.index = 1
                let item2 = Item(context: managedContext)
                item2.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")
                item2.clipId = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                item2.imageId = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                item2.createdDate = Date(timeIntervalSince1970: 0)
                item2.updatedDate = Date(timeIntervalSince1970: 0)
                item2.clip = clip
                item2.imageSize = 34
                item2.index = 2
                let item3 = Item(context: managedContext)
                item3.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")
                item3.clipId = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                item3.imageId = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                item3.createdDate = Date(timeIntervalSince1970: 0)
                item3.updatedDate = Date(timeIntervalSince1970: 0)
                item3.clip = clip
                item3.imageSize = 56
                item3.index = 3
                let item4 = Item(context: managedContext)
                item4.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E54")
                item4.clipId = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                item4.imageId = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                item4.createdDate = Date(timeIntervalSince1970: 0)
                item4.updatedDate = Date(timeIntervalSince1970: 0)
                item4.clip = clip
                item4.imageSize = 78
                item4.index = 4

                clip.clipItems = NSSet(array: [item1, item2, item3, item4])

                try! managedContext.save()

                _ = service.deleteClipItem(having: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!)
                _ = service.deleteClipItem(having: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!)

                try! managedContext.save()
            }
            it("ClipItemが削除され、indexが更新される") {
                let request: NSFetchRequest<Persistence.Clip> = Clip.fetchRequest()
                let clips = try! managedContext.fetch(request)
                expect(clips).to(haveCount(1))
                let clip = clips.first!
                expect(clip.imagesSize).to(equal(34 + 78))
                expect(clip.clipItems?.allObjects).to(haveCount(2))

                guard let item2 = clip.clipItems?
                    .allObjects
                    .compactMap({ $0 as? Item })
                    .first(where: { $0.id == UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")! })
                else {
                    fail()
                    return
                }
                expect(item2.index).to(equal(1))

                guard let item4 = clip.clipItems?
                    .allObjects
                    .compactMap({ $0 as? Item })
                    .first(where: { $0.id == UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E54")! })
                else {
                    fail()
                    return
                }
                expect(item4.index).to(equal(2))
            }
        }

        describe("deleteAlbum(having:)") {
            context("削除対象のアルバムが存在する") {
                beforeEach {
                    let clip1 = Persistence.Clip(context: managedContext)
                    clip1.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                    let clip2 = Persistence.Clip(context: managedContext)
                    clip2.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")
                    let clip3 = Persistence.Clip(context: managedContext)
                    clip3.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")

                    let item1 = AlbumItem(context: managedContext)
                    item1.clip = clip1
                    item1.index = 1
                    let item2 = AlbumItem(context: managedContext)
                    item2.clip = clip2
                    item2.index = 2
                    let item3 = AlbumItem(context: managedContext)
                    item3.clip = clip3
                    item3.index = 3

                    let album = Album(context: managedContext)
                    album.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                    album.title = "hoge"
                    album.createdDate = Date(timeIntervalSince1970: 0)
                    album.updatedDate = Date(timeIntervalSince1970: 0)
                    album.items = NSSet(array: [item1, item2, item3])

                    try! managedContext.save()

                    _ = service.deleteAlbum(having: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!)
                    try! managedContext.save()
                }
                it("Albumが削除される") {
                    let request: NSFetchRequest<Persistence.Album> = Album.fetchRequest()
                    let items = try! managedContext.fetch(request)
                    expect(items).to(haveCount(0))
                }
                it("AlbumItemが削除される") {
                    let request: NSFetchRequest<AlbumItem> = AlbumItem.fetchRequest()
                    let items = try! managedContext.fetch(request)
                    expect(items).to(haveCount(0))
                }
                it("Clipは削除されない") {
                    let request: NSFetchRequest<Persistence.Clip> = Clip.fetchRequest()
                    let items = try! managedContext.fetch(request)
                    expect(items).to(haveCount(3))
                }
            }
        }

        describe("deduplicateTag(for:)") {
            var results: [Domain.Tag.Identity]!

            context("重複したタグが存在しない") {
                beforeEach {
                    let tag1 = Persistence.Tag(context: managedContext)
                    tag1.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                    tag1.name = "tag1"
                    let tag2 = Persistence.Tag(context: managedContext)
                    tag2.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")
                    tag2.name = "tag2"
                    let clip = Persistence.Clip(context: managedContext)
                    clip.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                    clip.tags = [tag1, tag2]
                    try! managedContext.save()

                    results = service.deduplicateTag(for: tag1.objectID)
                    try! managedContext.save()
                }
                it("空が返ってくる") {
                    expect(results).to(beEmpty())
                }
                it("Tagは削除されない") {
                    let request: NSFetchRequest<Persistence.Tag> = Tag.fetchRequest()
                    let tags = try! managedContext.fetch(request)
                    expect(tags).to(haveCount(2))
                }
                it("Clipに紐づいたTagは削除されない") {
                    let request: NSFetchRequest<Persistence.Clip> = Clip.fetchRequest()
                    let clips = try! managedContext.fetch(request)
                    expect(clips).to(haveCount(1))
                    guard let tags = (clips.first?.tags?.allObjects as? [Persistence.Tag])?.sorted(by: { $0.name! < $1.name! }) else {
                        fail("クリップにタグが存在しない")
                        return
                    }
                    expect(tags).to(haveCount(2))
                }
            }

            context("重複したタグが存在する") {
                beforeEach {
                    let tag1 = Persistence.Tag(context: managedContext)
                    tag1.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                    tag1.name = "duplicated"
                    let tag2 = Persistence.Tag(context: managedContext)
                    tag2.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")
                    tag2.name = "tag1"
                    let tag3 = Persistence.Tag(context: managedContext)
                    tag3.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")
                    tag3.name = "duplicated"
                    let tag4 = Persistence.Tag(context: managedContext)
                    tag4.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E54")
                    tag4.name = "tag2"
                    let tag5 = Persistence.Tag(context: managedContext)
                    tag5.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E55")
                    tag5.name = "duplicated"

                    let clip1 = Persistence.Clip(context: managedContext)
                    clip1.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                    clip1.tags = [tag1, tag2, tag3]
                    let clip2 = Persistence.Clip(context: managedContext)
                    clip2.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")
                    clip2.tags = [tag3, tag4, tag5]

                    try! managedContext.save()

                    results = service.deduplicateTag(for: tag1.objectID)
                    try! managedContext.save()
                }
                it("重複したタグのIDが返ってくる") {
                    expect(results).to(equal([
                        UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53"),
                        UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E55")
                    ]))
                }
                it("重複したタグが削除される") {
                    let request: NSFetchRequest<Persistence.Tag> = Tag.fetchRequest()
                    let tags = (try! managedContext.fetch(request))
                        .sorted(by: { $0.id!.uuidString < $1.id!.uuidString })

                    expect(tags).to(haveCount(3))
                    guard tags.count == 3 else { return }

                    expect(tags[0].id).to(equal(UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")))
                    expect(tags[0].name).to(equal("duplicated"))
                    expect(tags[1].id).to(equal(UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")))
                    expect(tags[1].name).to(equal("tag1"))
                    expect(tags[2].id).to(equal(UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E54")))
                    expect(tags[2].name).to(equal("tag2"))
                }
                it("Clipに紐づいた重複したタグが削除され、優先されたタグに差し替えられる") {
                    let request: NSFetchRequest<Persistence.Clip> = Clip.fetchRequest()
                    let clips = (try! managedContext.fetch(request)).sorted(by: { $0.id!.uuidString < $1.id!.uuidString })
                    expect(clips).to(haveCount(2))
                    guard clips.count == 2 else { return }

                    expect(clips[0].id).to(equal(UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")))
                    let clip1Tags = clips[0].tags?.allObjects
                        .compactMap({ $0 as? Persistence.Tag })
                        .sorted(by: { $0.id!.uuidString < $1.id!.uuidString })
                    expect(clip1Tags).to(haveCount(2))
                    guard clip1Tags?.count == 2 else { return }
                    expect(clip1Tags?[0].id).to(equal(UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")))
                    expect(clip1Tags?[0].name).to(equal("duplicated"))
                    expect(clip1Tags?[1].id).to(equal(UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")))
                    expect(clip1Tags?[1].name).to(equal("tag1"))

                    expect(clips[1].id).to(equal(UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")))
                    let clip2Tags = clips[1].tags?.allObjects
                        .compactMap({ $0 as? Persistence.Tag })
                        .sorted(by: { $0.id!.uuidString < $1.id!.uuidString })
                    expect(clip2Tags).to(haveCount(2))
                    guard clip2Tags?.count == 2 else { return }
                    expect(clip2Tags?[0].id).to(equal(UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")))
                    expect(clip2Tags?[0].name).to(equal("duplicated"))
                    expect(clip2Tags?[1].id).to(equal(UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E54")))
                    expect(clip2Tags?[1].name).to(equal("tag2"))
                }
            }
        }
    }
}
