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

        describe("updateAlbum(having:byReorderingClipsHaving:)") {
            var result: Result<Void, ClipStorageError>!
            context("並び替え対象のクリップが足りない") {
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
                        let request = NSFetchRequest<Album>(entityName: "Album")
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
                let clip = NSEntityDescription.insertNewObject(forEntityName: "Clip", into: managedContext) as! Clip
                clip.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                clip.createdDate = Date(timeIntervalSince1970: 0)
                clip.updatedDate = Date(timeIntervalSince1970: 0)

                let item1 = NSEntityDescription.insertNewObject(forEntityName: "ClipItem", into: managedContext) as! Item
                item1.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                let item2 = NSEntityDescription.insertNewObject(forEntityName: "ClipItem", into: managedContext) as! Item
                item2.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")

                clip.clipItems = NSSet(array: [item1, item2])

                let albumItem = NSEntityDescription.insertNewObject(forEntityName: "AlbumItem", into: managedContext) as! AlbumItem
                albumItem.clip = clip
                albumItem.index = 1

                let album = NSEntityDescription.insertNewObject(forEntityName: "Album", into: managedContext) as! Album
                album.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                album.items = NSSet(array: [albumItem])

                try! managedContext.save()

                _ = service.deleteClips(having: [UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!])

                try! managedContext.save()
            }
            it("Clipが削除される") {
                let request = NSFetchRequest<Clip>(entityName: "Clip")
                let clips = try! managedContext.fetch(request)
                expect(clips).to(haveCount(0))
            }
            it("ClipItemが削除される") {
                let request = NSFetchRequest<Item>(entityName: "ClipItem")
                let items = try! managedContext.fetch(request)
                expect(items).to(haveCount(0))
            }
            it("AlbumItemが削除される") {
                let request = NSFetchRequest<AlbumItem>(entityName: "AlbumItem")
                let items = try! managedContext.fetch(request)
                expect(items).to(haveCount(0))
            }
            it("Albumは削除されない") {
                let request = NSFetchRequest<Album>(entityName: "Album")
                let albums = try! managedContext.fetch(request)
                expect(albums).to(haveCount(1))
                expect(albums.first?.items).to(haveCount(0))
            }
        }

        describe("deleteClipItem(having:)") {
            beforeEach {
                let clip = NSEntityDescription.insertNewObject(forEntityName: "Clip", into: managedContext) as! Clip
                clip.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                clip.imagesSize = 12 + 34 + 56 + 78

                let item1 = NSEntityDescription.insertNewObject(forEntityName: "ClipItem", into: managedContext) as! Item
                item1.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                item1.clipId = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                item1.imageId = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                item1.createdDate = Date(timeIntervalSince1970: 0)
                item1.updatedDate = Date(timeIntervalSince1970: 0)
                item1.imageSize = 12
                item1.clip = clip
                item1.index = 1
                let item2 = NSEntityDescription.insertNewObject(forEntityName: "ClipItem", into: managedContext) as! Item
                item2.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")
                item2.clipId = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                item2.imageId = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                item2.createdDate = Date(timeIntervalSince1970: 0)
                item2.updatedDate = Date(timeIntervalSince1970: 0)
                item2.clip = clip
                item2.imageSize = 34
                item2.index = 2
                let item3 = NSEntityDescription.insertNewObject(forEntityName: "ClipItem", into: managedContext) as! Item
                item3.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")
                item3.clipId = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                item3.imageId = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                item3.createdDate = Date(timeIntervalSince1970: 0)
                item3.updatedDate = Date(timeIntervalSince1970: 0)
                item3.clip = clip
                item3.imageSize = 56
                item3.index = 3
                let item4 = NSEntityDescription.insertNewObject(forEntityName: "ClipItem", into: managedContext) as! Item
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
                let request = NSFetchRequest<Clip>(entityName: "Clip")
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
                    let clip1 = NSEntityDescription.insertNewObject(forEntityName: "Clip", into: managedContext) as! Clip
                    clip1.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
                    let clip2 = NSEntityDescription.insertNewObject(forEntityName: "Clip", into: managedContext) as! Clip
                    clip2.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")
                    let clip3 = NSEntityDescription.insertNewObject(forEntityName: "Clip", into: managedContext) as! Clip
                    clip3.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")

                    let item1 = NSEntityDescription.insertNewObject(forEntityName: "AlbumItem", into: managedContext) as! AlbumItem
                    item1.clip = clip1
                    item1.index = 1
                    let item2 = NSEntityDescription.insertNewObject(forEntityName: "AlbumItem", into: managedContext) as! AlbumItem
                    item2.clip = clip2
                    item2.index = 2
                    let item3 = NSEntityDescription.insertNewObject(forEntityName: "AlbumItem", into: managedContext) as! AlbumItem
                    item3.clip = clip3
                    item3.index = 3

                    let album = NSEntityDescription.insertNewObject(forEntityName: "Album", into: managedContext) as! Album
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
                    let request = NSFetchRequest<Album>(entityName: "Album")
                    let items = try! managedContext.fetch(request)
                    expect(items).to(haveCount(0))
                }
                it("AlbumItemが削除される") {
                    let request = NSFetchRequest<AlbumItem>(entityName: "AlbumItem")
                    let items = try! managedContext.fetch(request)
                    expect(items).to(haveCount(0))
                }
                it("Clipは削除されない") {
                    let request = NSFetchRequest<Clip>(entityName: "Clip")
                    let items = try! managedContext.fetch(request)
                    expect(items).to(haveCount(3))
                }
            }
        }
    }
}
