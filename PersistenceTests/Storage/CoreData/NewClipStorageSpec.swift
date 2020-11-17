//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import CoreData

import Nimble
import Quick

@testable import Persistence

class NewClipStorageSpec: QuickSpec {
    func coreDataStack() -> NSPersistentContainer {
        let bundle = Bundle(for: PersistentContainerLoader.Class.self)
        guard let url = bundle.url(forResource: "Model", withExtension: "momd"),
            let model = NSManagedObjectModel(contentsOf: url)
        else {
            fatalError("Unable to load Core Data Model")
        }
        let container = NSPersistentContainer(name: "Model", managedObjectModel: model)

        let persistentStoreDescription = NSPersistentStoreDescription()
        persistentStoreDescription.type = NSInMemoryStoreType
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
        var service: NewClipStorage!

        beforeEach {
            container = self.coreDataStack()
            managedContext = container.newBackgroundContext()
            service = NewClipStorage(context: managedContext)
        }

        describe("updateClips(having:byAddingTagsHaving:)") {
            context("追加対象のタグが全て存在") {
                context("全てのタグが未追加") {
                    beforeEach {
                        let tag1 = NSEntityDescription.insertNewObject(forEntityName: "Tag", into: managedContext) as! Tag
                        tag1.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                        tag1.name = "hoge"
                        let tag2 = NSEntityDescription.insertNewObject(forEntityName: "Tag", into: managedContext) as! Tag
                        tag2.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")
                        tag2.name = "fuga"
                        let clip = NSEntityDescription.insertNewObject(forEntityName: "Clip", into: managedContext) as! Clip
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
                        let request = NSFetchRequest<Clip>(entityName: "Clip")
                        request.predicate = NSPredicate(format: "id == %@",
                                                        UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")! as CVarArg)
                        let clip = try! managedContext.fetch(request).first!
                        let tags = clip.tags?
                            .allObjects
                            .compactMap { $0 as? Tag }
                        expect(tags).to(haveCount(2))
                        expect(tags?.first(where: { $0.name == "hoge" })).notTo(beNil())
                        expect(tags?.first(where: { $0.name == "fuga" })).notTo(beNil())
                        expect(clip.updatedDate).notTo(equal(Date(timeIntervalSince1970: 0)))
                    }
                }
                context("一部タグが追加済み") {
                    beforeEach {
                        let tag1 = NSEntityDescription.insertNewObject(forEntityName: "Tag", into: managedContext) as! Tag
                        tag1.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                        tag1.name = "hoge"
                        let tag2 = NSEntityDescription.insertNewObject(forEntityName: "Tag", into: managedContext) as! Tag
                        tag2.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")
                        tag2.name = "fuga"
                        let clip = NSEntityDescription.insertNewObject(forEntityName: "Clip", into: managedContext) as! Clip
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
                        let request = NSFetchRequest<Clip>(entityName: "Clip")
                        request.predicate = NSPredicate(format: "id == %@",
                                                        UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")! as CVarArg)
                        let clip = try! managedContext.fetch(request).first!
                        let tags = clip.tags?
                            .allObjects
                            .compactMap { $0 as? Tag }
                        expect(tags).to(haveCount(2))
                        expect(tags?.first(where: { $0.name == "hoge" })).notTo(beNil())
                        expect(tags?.first(where: { $0.name == "fuga" })).notTo(beNil())
                        expect(clip.updatedDate).notTo(equal(Date(timeIntervalSince1970: 0)))
                    }
                }
                context("全タグが追加済み") {
                    beforeEach {
                        let tag1 = NSEntityDescription.insertNewObject(forEntityName: "Tag", into: managedContext) as! Tag
                        tag1.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                        tag1.name = "hoge"
                        let tag2 = NSEntityDescription.insertNewObject(forEntityName: "Tag", into: managedContext) as! Tag
                        tag2.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")
                        tag2.name = "fuga"
                        let clip = NSEntityDescription.insertNewObject(forEntityName: "Clip", into: managedContext) as! Clip
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
                        let request = NSFetchRequest<Clip>(entityName: "Clip")
                        request.predicate = NSPredicate(format: "id == %@",
                                                        UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")! as CVarArg)
                        let clip = try! managedContext.fetch(request).first!
                        let tags = clip.tags?
                            .allObjects
                            .compactMap { $0 as? Tag }
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
                        let tag1 = NSEntityDescription.insertNewObject(forEntityName: "Tag", into: managedContext) as! Tag
                        tag1.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                        tag1.name = "hoge"
                        let tag2 = NSEntityDescription.insertNewObject(forEntityName: "Tag", into: managedContext) as! Tag
                        tag2.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")
                        tag2.name = "fuga"
                        let clip = NSEntityDescription.insertNewObject(forEntityName: "Clip", into: managedContext) as! Clip
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
                        let request = NSFetchRequest<Clip>(entityName: "Clip")
                        request.predicate = NSPredicate(format: "id == %@",
                                                        UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")! as CVarArg)
                        let clip = try! managedContext.fetch(request).first!
                        let tags = clip.tags?
                            .allObjects
                            .compactMap { $0 as? Tag }
                        expect(tags).to(haveCount(0))
                        expect(clip.updatedDate).notTo(equal(Date(timeIntervalSince1970: 0)))
                    }
                }
                context("一部タグが追加済み") {
                    beforeEach {
                        let tag1 = NSEntityDescription.insertNewObject(forEntityName: "Tag", into: managedContext) as! Tag
                        tag1.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                        tag1.name = "hoge"
                        let tag2 = NSEntityDescription.insertNewObject(forEntityName: "Tag", into: managedContext) as! Tag
                        tag2.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")
                        tag2.name = "fuga"
                        let clip = NSEntityDescription.insertNewObject(forEntityName: "Clip", into: managedContext) as! Clip
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
                        let request = NSFetchRequest<Clip>(entityName: "Clip")
                        request.predicate = NSPredicate(format: "id == %@",
                                                        UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")! as CVarArg)
                        let clip = try! managedContext.fetch(request).first!
                        let tags = clip.tags?
                            .allObjects
                            .compactMap { $0 as? Tag }
                        expect(tags).to(haveCount(0))
                        expect(clip.updatedDate).notTo(equal(Date(timeIntervalSince1970: 0)))
                    }
                }
                context("全てのタグが未追加") {
                    beforeEach {
                        let tag1 = NSEntityDescription.insertNewObject(forEntityName: "Tag", into: managedContext) as! Tag
                        tag1.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                        tag1.name = "hoge"
                        let tag2 = NSEntityDescription.insertNewObject(forEntityName: "Tag", into: managedContext) as! Tag
                        tag2.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")
                        tag2.name = "fuga"
                        let clip = NSEntityDescription.insertNewObject(forEntityName: "Clip", into: managedContext) as! Clip
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
                        let request = NSFetchRequest<Clip>(entityName: "Clip")
                        request.predicate = NSPredicate(format: "id == %@",
                                                        UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")! as CVarArg)
                        let clip = try! managedContext.fetch(request).first!
                        let tags = clip.tags?
                            .allObjects
                            .compactMap { $0 as? Tag }
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
                        let tag1 = NSEntityDescription.insertNewObject(forEntityName: "Tag", into: managedContext) as! Tag
                        tag1.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                        tag1.name = "hoge"
                        let tag2 = NSEntityDescription.insertNewObject(forEntityName: "Tag", into: managedContext) as! Tag
                        tag2.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")
                        tag2.name = "fuga"
                        let clip = NSEntityDescription.insertNewObject(forEntityName: "Clip", into: managedContext) as! Clip
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
                        let request = NSFetchRequest<Clip>(entityName: "Clip")
                        request.predicate = NSPredicate(format: "id == %@",
                                                        UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")! as CVarArg)
                        let clip = try! managedContext.fetch(request).first!
                        let tags = clip.tags?
                            .allObjects
                            .compactMap { $0 as? Tag }
                        expect(tags?.first(where: { $0.name == "hoge" })).notTo(beNil())
                        expect(tags?.first(where: { $0.name == "fuga" })).notTo(beNil())
                        expect(clip.updatedDate).notTo(equal(Date(timeIntervalSince1970: 0)))
                    }
                }
                context("一部タグが追加済み") {
                    beforeEach {
                        let tag1 = NSEntityDescription.insertNewObject(forEntityName: "Tag", into: managedContext) as! Tag
                        tag1.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                        tag1.name = "hoge"
                        let tag2 = NSEntityDescription.insertNewObject(forEntityName: "Tag", into: managedContext) as! Tag
                        tag2.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")
                        tag2.name = "fuga"
                        let clip = NSEntityDescription.insertNewObject(forEntityName: "Clip", into: managedContext) as! Clip
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
                        let request = NSFetchRequest<Clip>(entityName: "Clip")
                        request.predicate = NSPredicate(format: "id == %@",
                                                        UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")! as CVarArg)
                        let clip = try! managedContext.fetch(request).first!
                        let tags = clip.tags?
                            .allObjects
                            .compactMap { $0 as? Tag }
                        expect(tags?.first(where: { $0.name == "hoge" })).notTo(beNil())
                        expect(tags?.first(where: { $0.name == "fuga" })).notTo(beNil())
                        expect(clip.updatedDate).notTo(equal(Date(timeIntervalSince1970: 0)))
                    }
                }
                context("全てのタグが未追加") {
                    beforeEach {
                        let tag1 = NSEntityDescription.insertNewObject(forEntityName: "Tag", into: managedContext) as! Tag
                        tag1.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                        tag1.name = "hoge"
                        let tag2 = NSEntityDescription.insertNewObject(forEntityName: "Tag", into: managedContext) as! Tag
                        tag2.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")
                        tag2.name = "fuga"
                        let clip = NSEntityDescription.insertNewObject(forEntityName: "Clip", into: managedContext) as! Clip
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
                        let request = NSFetchRequest<Clip>(entityName: "Clip")
                        request.predicate = NSPredicate(format: "id == %@",
                                                        UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")! as CVarArg)
                        let clip = try! managedContext.fetch(request).first!
                        let tags = clip.tags?
                            .allObjects
                            .compactMap { $0 as? Tag }
                        expect(tags?.first(where: { $0.name == "hoge" })).notTo(beNil())
                        expect(tags?.first(where: { $0.name == "fuga" })).notTo(beNil())
                        expect(clip.updatedDate).notTo(equal(Date(timeIntervalSince1970: 0)))
                    }
                }
            }
        }
    }
}
