//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import CoreData
import enum Domain.ClipStorageError

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

        describe("updateAlbum(having:byAddingClipsHaving:)") {
            var result: Result<Void, ClipStorageError>!
            context("追加対象のクリップが追加済み") {
                beforeEach {
                    let clip1 = NSEntityDescription.insertNewObject(forEntityName: "Clip", into: managedContext) as! Clip
                    clip1.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                    let clip2 = NSEntityDescription.insertNewObject(forEntityName: "Clip", into: managedContext) as! Clip
                    clip2.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")

                    let item1 = NSEntityDescription.insertNewObject(forEntityName: "AlbumItem", into: managedContext) as! AlbumItem
                    item1.clip = clip1
                    item1.index = 1
                    let item2 = NSEntityDescription.insertNewObject(forEntityName: "AlbumItem", into: managedContext) as! AlbumItem
                    item2.clip = clip2
                    item2.index = 2

                    let album = NSEntityDescription.insertNewObject(forEntityName: "Album", into: managedContext) as! Album
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
                        let clip1 = NSEntityDescription.insertNewObject(forEntityName: "Clip", into: managedContext) as! Clip
                        clip1.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                        let clip2 = NSEntityDescription.insertNewObject(forEntityName: "Clip", into: managedContext) as! Clip
                        clip2.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")

                        let album = NSEntityDescription.insertNewObject(forEntityName: "Album", into: managedContext) as! Album
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
                        let request = NSFetchRequest<Album>(entityName: "Album")
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
                        let clip1 = NSEntityDescription.insertNewObject(forEntityName: "Clip", into: managedContext) as! Clip
                        clip1.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                        let clip2 = NSEntityDescription.insertNewObject(forEntityName: "Clip", into: managedContext) as! Clip
                        clip2.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")
                        let clip3 = NSEntityDescription.insertNewObject(forEntityName: "Clip", into: managedContext) as! Clip
                        clip3.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")
                        let clip4 = NSEntityDescription.insertNewObject(forEntityName: "Clip", into: managedContext) as! Clip
                        clip4.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E54")

                        let item1 = NSEntityDescription.insertNewObject(forEntityName: "AlbumItem", into: managedContext) as! AlbumItem
                        item1.clip = clip1
                        item1.index = 1
                        let item2 = NSEntityDescription.insertNewObject(forEntityName: "AlbumItem", into: managedContext) as! AlbumItem
                        item2.clip = clip2
                        item2.index = 2

                        let album = NSEntityDescription.insertNewObject(forEntityName: "Album", into: managedContext) as! Album
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
                        let request = NSFetchRequest<Album>(entityName: "Album")
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
                    let clip1 = NSEntityDescription.insertNewObject(forEntityName: "Clip", into: managedContext) as! Clip
                    clip1.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                    let clip2 = NSEntityDescription.insertNewObject(forEntityName: "Clip", into: managedContext) as! Clip
                    clip2.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")
                    let clip3 = NSEntityDescription.insertNewObject(forEntityName: "Clip", into: managedContext) as! Clip
                    clip3.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")
                    let clip4 = NSEntityDescription.insertNewObject(forEntityName: "Clip", into: managedContext) as! Clip
                    clip4.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E54")

                    let item1 = NSEntityDescription.insertNewObject(forEntityName: "AlbumItem", into: managedContext) as! AlbumItem
                    item1.clip = clip1
                    item1.index = 1
                    let item2 = NSEntityDescription.insertNewObject(forEntityName: "AlbumItem", into: managedContext) as! AlbumItem
                    item2.clip = clip2
                    item2.index = 2
                    let item3 = NSEntityDescription.insertNewObject(forEntityName: "AlbumItem", into: managedContext) as! AlbumItem
                    item3.clip = clip3
                    item3.index = 3
                    let item4 = NSEntityDescription.insertNewObject(forEntityName: "AlbumItem", into: managedContext) as! AlbumItem
                    item4.clip = clip4
                    item4.index = 4

                    let album = NSEntityDescription.insertNewObject(forEntityName: "Album", into: managedContext) as! Album
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
                        let clip1 = NSEntityDescription.insertNewObject(forEntityName: "Clip", into: managedContext) as! Clip
                        clip1.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                        let clip2 = NSEntityDescription.insertNewObject(forEntityName: "Clip", into: managedContext) as! Clip
                        clip2.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")
                        let clip3 = NSEntityDescription.insertNewObject(forEntityName: "Clip", into: managedContext) as! Clip
                        clip3.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")
                        let clip4 = NSEntityDescription.insertNewObject(forEntityName: "Clip", into: managedContext) as! Clip
                        clip4.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E54")

                        let item1 = NSEntityDescription.insertNewObject(forEntityName: "AlbumItem", into: managedContext) as! AlbumItem
                        item1.clip = clip1
                        item1.index = 1
                        let item2 = NSEntityDescription.insertNewObject(forEntityName: "AlbumItem", into: managedContext) as! AlbumItem
                        item2.clip = clip2
                        item2.index = 2
                        let item3 = NSEntityDescription.insertNewObject(forEntityName: "AlbumItem", into: managedContext) as! AlbumItem
                        item3.clip = clip3
                        item3.index = 3
                        let item4 = NSEntityDescription.insertNewObject(forEntityName: "AlbumItem", into: managedContext) as! AlbumItem
                        item4.clip = clip4
                        item4.index = 4

                        let album = NSEntityDescription.insertNewObject(forEntityName: "Album", into: managedContext) as! Album
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
                        let request = NSFetchRequest<Album>(entityName: "Album")
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
                        let request = NSFetchRequest<AlbumItem>(entityName: "AlbumItem")
                        let items = try! managedContext.fetch(request)
                        expect(items).to(haveCount(2))
                    }
                    it("Clipは削除されない") {
                        let request = NSFetchRequest<Clip>(entityName: "Clip")
                        let clips = try! managedContext.fetch(request)
                        expect(clips).to(haveCount(4))
                    }
                }
            }
        }
    }
}
