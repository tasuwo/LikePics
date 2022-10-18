//
//  Copyright ©︎ 2022 Tasuku Tozawa. All rights reserved.
//

import Common
import CoreData
import Domain
@testable import Persistence
@testable import TestHelper
import XCTest

class ClipStorageTest: XCTestCase {
    var container: NSPersistentContainer!
    var managedContext: NSManagedObjectContext!
    var service: ClipStorage!
    var currentDate: Date!

    override func setUp() {
        container = setUp_CoreDataStack()
        managedContext = container.newBackgroundContext()
        service = ClipStorage(context: managedContext)
        currentDate = Date()
    }

    func setUp_CoreDataStack() -> NSPersistentContainer {
        let model = NSManagedObjectModel(contentsOf: ManagedObjectModelUrl)!
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

    func test_createClip_overwriteがtrueであり_同一IDの既存のクリップが存在しない場合() {
        // TODO:
    }

    func test_createClip_overwriteがtrueであり_同一IDの既存のクリップが存在する場合_正常に保存でき古いClipItem群は削除される() {
        // TODO:
    }

    func test_createClip_overwriteがfalseであり_同一IDの既存のクリップが存在しない場合() {
        // TODO:
    }

    func test_createClip_overwriteがfalseであり_同一IDの既存のクリップが存在する場合_エラーとなる() {
        // TODO:
    }

    func test_createClip_IDが同一のタグが存在する場合_既存のタグを付与したクリップが保存され新規タグは作成されない() {
        let tag = Persistence.Tag(context: managedContext)
        tag.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
        tag.name = "hoge"
        try! managedContext.save()

        _ = service.create(clip: .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!,
                                              tagIds: [UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!]))

        let request1: NSFetchRequest<Persistence.Clip> = Clip.fetchRequest()
        request1.predicate = NSPredicate(format: "id == %@", UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")! as CVarArg)
        let clip = try! managedContext.fetch(request1).first!
        let tags1 = clip.tags?.allObjects.compactMap { $0 as? Persistence.Tag }
        XCTAssertEqual(tags1!.count, 1)
        XCTAssertEqual(tags1!.first!.id, UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!)
        XCTAssertEqual(tags1!.first!.name, "hoge")

        let request2: NSFetchRequest<Persistence.Tag> = Persistence.Tag.fetchRequest()
        let tags2 = try! managedContext.fetch(request2)
        XCTAssertEqual(tags2.count, 1)
    }

    func test_createClip_IDは異なるが名前が同一の既存タグが存在すつ場合_既存のタグを付与したクリップが保存され新規タグは作成されない() {
        let tag = Persistence.Tag(context: managedContext)
        tag.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E59")
        tag.name = "hoge"
        try! managedContext.save()

        _ = service.create(clip: .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!,
                                              tagIds: [UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!]))

        let request1: NSFetchRequest<Persistence.Clip> = Clip.fetchRequest()
        request1.predicate = NSPredicate(format: "id == %@", UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")! as CVarArg)
        let clip1 = try! managedContext.fetch(request1).first!
        let tags1 = clip1.tags?.allObjects.compactMap { $0 as? Persistence.Tag }
        XCTAssertEqual(tags1?.count, 0)

        let request2: NSFetchRequest<Persistence.Tag> = Persistence.Tag.fetchRequest()
        let tags2 = try! managedContext.fetch(request2)
        XCTAssertEqual(tags2.count, 1)
    }

    func test_createClip_IDや名前が同一の既存ダグが存在しない場合_タグの付与がスキップされ新規タグは作成されない() {
        let tag = Persistence.Tag(context: managedContext)
        tag.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E59")
        tag.name = "fuga"
        try! managedContext.save()

        _ = service.create(clip: .makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!,
                                              tagIds: [UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!]))

        let request1: NSFetchRequest<Persistence.Clip> = Clip.fetchRequest()
        request1.predicate = NSPredicate(format: "id == %@", UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")! as CVarArg)
        let clip1 = try! managedContext.fetch(request1).first!
        let tags1 = clip1.tags?.allObjects.compactMap { $0 as? Persistence.Tag }
        XCTAssertEqual(tags1?.count, 0)

        let request2: NSFetchRequest<Persistence.Tag> = Persistence.Tag.fetchRequest()
        let tags2 = try! managedContext.fetch(request2)
        XCTAssertEqual(tags2.count, 1)
    }

    func test_updateClipsHavingClipIdsByAddingTagsHavingTagIds_追加対象のタグが全て存在し_全てのタグが未追加の場合_追加でき更新される() {
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

        let request: NSFetchRequest<Persistence.Clip> = Clip.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@",
                                        UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")! as CVarArg)
        let fetchedClip = try! managedContext.fetch(request).first!
        let fetchedTags = fetchedClip.tags?
            .allObjects
            .compactMap { $0 as? Persistence.Tag }
        XCTAssertEqual(fetchedTags!.count, 2)
        XCTAssertNotNil(fetchedTags?.first(where: { $0.name == "hoge" }))
        XCTAssertNotNil(fetchedTags?.first(where: { $0.name == "fuga" }))
        XCTAssertNotEqual(fetchedClip.updatedDate, Date(timeIntervalSince1970: 0))
    }

    func test_updateClipsHavingClipIdsByAddingTagsHavingTagIds_追加対象のタグが全て存在し_一部タグが追加済みの場合_未追加のタグのみ追加され更新される() {
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

        let request: NSFetchRequest<Persistence.Clip> = Clip.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@",
                                        UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")! as CVarArg)
        let fetchedClip = try! managedContext.fetch(request).first!
        let fetchedTags = fetchedClip.tags?
            .allObjects
            .compactMap { $0 as? Persistence.Tag }
        XCTAssertEqual(fetchedTags?.count, 2)
        XCTAssertNotNil(fetchedTags?.first(where: { $0.name == "hoge" }))
        XCTAssertNotNil(fetchedTags?.first(where: { $0.name == "fuga" }))
        XCTAssertNotEqual(fetchedClip.updatedDate, Date(timeIntervalSince1970: 0))
    }

    func test_updateClipsHavingClipIdsByAddingTagsHavingTagIds_追加対象のタグが全て存在し_全タグが追加済み_更新されない() {
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

        let request: NSFetchRequest<Persistence.Clip> = Clip.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@",
                                        UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")! as CVarArg)
        let fetchedClip = try! managedContext.fetch(request).first!
        let fetchedTags = fetchedClip.tags?
            .allObjects
            .compactMap { $0 as? Persistence.Tag }
        XCTAssertEqual(fetchedTags?.count, 2)
        XCTAssertNotNil(fetchedTags?.first(where: { $0.name == "hoge" }))
        XCTAssertNotNil(fetchedTags?.first(where: { $0.name == "fuga" }))
        XCTAssertEqual(fetchedClip.updatedDate, Date(timeIntervalSince1970: 0))
    }

    func test_updateClipsHavingClipIdsByDeletingTagsHavingTagIds_削除対象のタグが全て存在し_全タグが追加済みの場合_タグが削除され更新される() {
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

        let request: NSFetchRequest<Persistence.Clip> = Clip.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@",
                                        UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")! as CVarArg)
        let fetchedClip = try! managedContext.fetch(request).first!
        let fetchedTags = fetchedClip.tags?
            .allObjects
            .compactMap { $0 as? Persistence.Tag }
        XCTAssertEqual(fetchedTags?.count, 0)
        XCTAssertNotEqual(fetchedClip.updatedDate, Date(timeIntervalSince1970: 0))
    }

    func test_updateClipsHavingClipIdsByDeletingTagsHavingTagIds_削除対象のタグが全て存在し_一部タグが追加済みの場合_追加済みのタグが削除され更新される() {
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

        let request: NSFetchRequest<Persistence.Clip> = Clip.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@",
                                        UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")! as CVarArg)
        let fetchedClip = try! managedContext.fetch(request).first!
        let fetchedTags = fetchedClip.tags?
            .allObjects
            .compactMap { $0 as? Persistence.Tag }
        XCTAssertEqual(fetchedTags?.count, 0)
        XCTAssertNotEqual(fetchedClip.updatedDate, Date(timeIntervalSince1970: 0))
    }

    func test_updateClipsHavingClipIdsByDeletingTagsHavingTagIds_削除対象のタグが全て存在し_全てのタグが未追加の場合_更新されない() {
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

        let request: NSFetchRequest<Persistence.Clip> = Clip.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@",
                                        UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")! as CVarArg)
        let fetchedClip = try! managedContext.fetch(request).first!
        let fetchedTags = fetchedClip.tags?
            .allObjects
            .compactMap { $0 as? Persistence.Tag }
        XCTAssertEqual(fetchedTags?.count, 0)
        XCTAssertEqual(fetchedClip.updatedDate, Date(timeIntervalSince1970: 0))
    }

    func test_updateClipsHavingClipIdsByReplacingTagsHavingTagIds_置換対象のタグが全て存在し_全てのタグが存在する場合_タグが置換される() {
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

        let request: NSFetchRequest<Persistence.Clip> = Clip.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@",
                                        UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")! as CVarArg)
        let fetchedClip = try! managedContext.fetch(request).first!
        let fetchedTags = fetchedClip.tags?
            .allObjects
            .compactMap { $0 as? Persistence.Tag }
        XCTAssertNotNil(fetchedTags?.first(where: { $0.name == "hoge" }))
        XCTAssertNotNil(fetchedTags?.first(where: { $0.name == "fuga" }))
        XCTAssertNotEqual(fetchedClip.updatedDate, Date(timeIntervalSince1970: 0))
    }

    func test_updateClipsHavingClipIdsByReplacingTagsHavingTagIds_置換対象のタグが全て存在し_一部タグが追加済みの場合_タグが置換される() {
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

        let request: NSFetchRequest<Persistence.Clip> = Clip.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@",
                                        UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")! as CVarArg)
        let fetchedClip = try! managedContext.fetch(request).first!
        let fetchedTags = fetchedClip.tags?
            .allObjects
            .compactMap { $0 as? Persistence.Tag }
        XCTAssertNotNil(fetchedTags?.first(where: { $0.name == "hoge" }))
        XCTAssertNotNil(fetchedTags?.first(where: { $0.name == "fuga" }))
        XCTAssertNotEqual(fetchedClip.updatedDate, Date(timeIntervalSince1970: 0))
    }

    func test_updateClipsHavingClipIdsByReplacingTagsHavingTagIds_置換対象のタグが全て存在し_全てのタグが未追加の場合_タグが置換される() {
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

        let request: NSFetchRequest<Persistence.Clip> = Clip.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@",
                                        UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")! as CVarArg)
        let fetchedClip = try! managedContext.fetch(request).first!
        let fetchedTags = fetchedClip.tags?
            .allObjects
            .compactMap { $0 as? Persistence.Tag }
        XCTAssertNotNil(fetchedTags?.first(where: { $0.name == "hoge" }))
        XCTAssertNotNil(fetchedTags?.first(where: { $0.name == "fuga" }))
        XCTAssertNotEqual(fetchedClip.updatedDate, Date(timeIntervalSince1970: 0))
    }

    func test_updateAlbumHavingAlbumIdByAddingClipsHavingClipIds_追加対象のクリップが全て追加済みの場合_エラーとなる() {
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

        let result = service.updateAlbum(having: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!,
                                         byAddingClipsHaving: [
                                             UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!,
                                             UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!
                                         ],
                                         at: currentDate)
        try! managedContext.save()

        XCTAssertEqual(result.failureValue, .duplicated)
    }

    func test_updateAlbumHavingAlbumIdByAddingClipsHavingClipIds_追加対象のクリップが一部追加済みの場合_未追加のクリップのみ追加できる() {
        let clip1 = Persistence.Clip(context: managedContext)
        clip1.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
        let clip2 = Persistence.Clip(context: managedContext)
        clip2.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")

        let item1 = AlbumItem(context: managedContext)
        item1.clip = clip1
        item1.index = 1

        let album = Album(context: managedContext)
        album.id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
        album.items = NSSet(array: [item1])

        try! managedContext.save()

        _ = service.updateAlbum(having: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!,
                                byAddingClipsHaving: [
                                    UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!,
                                    UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!
                                ],
                                at: currentDate)
        try! managedContext.save()

        let request: NSFetchRequest<Persistence.Album> = Album.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@",
                                        UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")! as CVarArg)
        let fetchedAlbum = try! managedContext.fetch(request).first!
        XCTAssertEqual(fetchedAlbum.items?.allObjects.count, 2)

        guard let item1 = fetchedAlbum.items?
            .allObjects
            .compactMap({ $0 as? AlbumItem })
            .first(where: { $0.clip?.id == UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")! })
        else {
            XCTFail()
            return
        }
        XCTAssertEqual(item1.index, 1)

        guard let item2 = fetchedAlbum.items?
            .allObjects
            .compactMap({ $0 as? AlbumItem })
            .first(where: { $0.clip?.id == UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")! })
        else {
            XCTFail()
            return
        }
        XCTAssertEqual(item2.index, 2)
    }

    func test_updateAlbumHavingAlbumIdByAddingClipsHavingClipIds_追加対象のクリップが一部追加済みの場合_追加対象のクリップが未追加で_初めて追加する場合_追加できる() {
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
                                ],
                                at: currentDate)
        try! managedContext.save()

        let request: NSFetchRequest<Persistence.Album> = Album.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@",
                                        UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")! as CVarArg)
        let fetchedAlbum = try! managedContext.fetch(request).first!
        XCTAssertEqual(fetchedAlbum.items?.allObjects.count, 2)

        guard let item1 = fetchedAlbum.items?
            .allObjects
            .compactMap({ $0 as? AlbumItem })
            .first(where: { $0.clip?.id == UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")! })
        else {
            XCTFail()
            return
        }
        XCTAssertEqual(item1.index, 1)

        guard let item2 = fetchedAlbum.items?
            .allObjects
            .compactMap({ $0 as? AlbumItem })
            .first(where: { $0.clip?.id == UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")! })
        else {
            XCTFail()
            return
        }
        XCTAssertEqual(item2.index, 2)
    }

    func test_updateAlbumHavingAlbumIdByAddingClipsHavingClipIds_追加対象のクリップが一部追加済みの場合_追加対象のクリップが未追加で_追加済みクリップが存在する場合_追加できる() {
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
                                ],
                                at: currentDate)
        try! managedContext.save()

        let request: NSFetchRequest<Persistence.Album> = Album.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@",
                                        UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")! as CVarArg)
        let fetchedAlbum = try! managedContext.fetch(request).first!
        XCTAssertEqual(fetchedAlbum.items?.allObjects.count, 4)

        guard let item3 = fetchedAlbum.items?
            .allObjects
            .compactMap({ $0 as? AlbumItem })
            .first(where: { $0.clip?.id == UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E54")! })
        else {
            XCTFail()
            return
        }
        XCTAssertEqual(item3.index, 3)

        guard let item4 = fetchedAlbum.items?
            .allObjects
            .compactMap({ $0 as? AlbumItem })
            .first(where: { $0.clip?.id == UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")! })
        else {
            XCTFail()
            return
        }
        XCTAssertEqual(item4.index, 4)
    }

    func test_updateAlbumHavingAlbumIdByDeletingClipsHavingClipIds_削除対象のクリップが一部存在しない場合_エラーとなる() {
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

        let result = service.updateAlbum(having: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!,
                                         byDeletingClipsHaving: [
                                             UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!,
                                             UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!
                                         ],
                                         at: currentDate)
        try! managedContext.save()

        XCTAssertEqual(result.failureValue, .notFound)
    }

    func test_updateAlbumHavingAlbumIdByDeletingClipsHavingClipIds_削除対象のクリップが全て存在する場合_指定したクリップを削除する() {
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

        let result = service.updateAlbum(having: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!,
                                         byDeletingClipsHaving: [
                                             UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!,
                                             UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!
                                         ],
                                         at: currentDate)
        try! managedContext.save()

        guard case .success = result else {
            XCTFail()
            return
        }
        let request: NSFetchRequest<Persistence.Album> = Album.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@",
                                        UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")! as CVarArg)
        let fetchedAlbum = try! managedContext.fetch(request).first!
        XCTAssertEqual(fetchedAlbum.items?.allObjects.count, 2)

        guard let fetchedItem2 = fetchedAlbum.items?
            .allObjects
            .compactMap({ $0 as? AlbumItem })
            .first(where: { $0.clip?.id == UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")! })
        else {
            XCTFail()
            return
        }
        XCTAssertEqual(fetchedItem2.index, 1)

        guard let fetchedItem4 = fetchedAlbum.items?
            .allObjects
            .compactMap({ $0 as? AlbumItem })
            .first(where: { $0.clip?.id == UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E54")! })
        else {
            XCTFail()
            return
        }
        XCTAssertEqual(fetchedItem4.index, 2)

        let request2: NSFetchRequest<AlbumItem> = AlbumItem.fetchRequest()
        let itemsCount = try! managedContext.fetch(request2).count
        XCTAssertEqual(itemsCount, 2, "AlbumItemが削除されていない")

        let request3: NSFetchRequest<Persistence.Clip> = Clip.fetchRequest()
        let clipsCount = try! managedContext.fetch(request3).count
        XCTAssertEqual(clipsCount, 4, "Clipが削除されている")
    }

    func test_updateAlbumHavingAlbumIdByReorderingClipsHavingClipIds_並び替え対象のクリップ指定がアルバムのアイテム数より足りない場合_エラーとなる() {
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

        let result = service.updateAlbum(having: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!,
                                         byReorderingClipsHaving: [
                                             UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!,
                                             UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!,
                                             UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E54")!,
                                         ],
                                         at: currentDate)
        try! managedContext.save()

        XCTAssertEqual(result.failureValue, .invalidParameter)
    }

    func test_updateAlbumHavingAlbumIdByReorderingClipsHavingClipIds_並び替え対象のクリップが一部存在しない場合_エラーとなる() {
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

        let result = service.updateAlbum(having: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!,
                                         byReorderingClipsHaving: [
                                             UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!,
                                             UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!,
                                             UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!,
                                             UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E54")!,
                                         ],
                                         at: currentDate)
        try! managedContext.save()

        XCTAssertEqual(result.failureValue, .invalidParameter)
    }

    func test_updateAlbumHavingAlbumIdByReorderingClipsHavingClipIds_並び替え対象が全て存在する場合_並び替えた順にindexが更新される() {
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

        let result = service.updateAlbum(having: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!,
                                         byReorderingClipsHaving: [
                                             UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!,
                                             UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!,
                                             UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!,
                                             UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E54")!,
                                         ],
                                         at: currentDate)
        try! managedContext.save()

        guard case .success = result else {
            XCTFail()
            return
        }
        let request: NSFetchRequest<Persistence.Album> = Album.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@",
                                        UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")! as CVarArg)
        let fetchedAlbum = try! managedContext.fetch(request).first!
        XCTAssertEqual(fetchedAlbum.items?.allObjects.count, 4)

        guard let fetchedItem1 = fetchedAlbum.items?
            .allObjects
            .compactMap({ $0 as? AlbumItem })
            .first(where: { $0.clip?.id == UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")! })
        else {
            XCTFail()
            return
        }
        XCTAssertEqual(fetchedItem1.index, 1)

        guard let fetchedItem2 = fetchedAlbum.items?
            .allObjects
            .compactMap({ $0 as? AlbumItem })
            .first(where: { $0.clip?.id == UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")! })
        else {
            XCTFail()
            return
        }
        XCTAssertEqual(fetchedItem2.index, 3)

        guard let fetchedItem3 = fetchedAlbum.items?
            .allObjects
            .compactMap({ $0 as? AlbumItem })
            .first(where: { $0.clip?.id == UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")! })
        else {
            XCTFail()
            return
        }
        XCTAssertEqual(fetchedItem3.index, 2)

        guard let item4 = album.items?
            .allObjects
            .compactMap({ $0 as? AlbumItem })
            .first(where: { $0.clip?.id == UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E54")! })
        else {
            XCTFail()
            return
        }
        XCTAssertEqual(item4.index, 4)
    }

    func test_deleteClipsHavingClipIds_ClipとClipItemとAlubmItemが削除されAlbumは削除されない() {
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

        let request1: NSFetchRequest<Persistence.Clip> = Clip.fetchRequest()
        let fetchedClips = try! managedContext.fetch(request1)
        XCTAssertEqual(fetchedClips.count, 0)

        let request2: NSFetchRequest<Item> = Item.fetchRequest()
        let fetchedItems = try! managedContext.fetch(request2)
        XCTAssertEqual(fetchedItems.count, 0)

        let request3: NSFetchRequest<AlbumItem> = AlbumItem.fetchRequest()
        let fetchedAlbumItems = try! managedContext.fetch(request3)
        XCTAssertEqual(fetchedAlbumItems.count, 0)

        let request4: NSFetchRequest<Persistence.Album> = Album.fetchRequest()
        let fetchedAlbums = try! managedContext.fetch(request4)
        XCTAssertEqual(fetchedAlbums.count, 1)
        XCTAssertEqual(fetchedAlbums.first?.items?.count, 0)
    }

    func test_deleteClipItemsHavingClipItemIds_ClipItemが削除されindexが更新される() {
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

        let request: NSFetchRequest<Persistence.Clip> = Clip.fetchRequest()
        let fetchedClips = try! managedContext.fetch(request)
        XCTAssertEqual(fetchedClips.count, 1)
        let fetchedClip = fetchedClips.first!
        XCTAssertEqual(fetchedClip.imagesSize, 34 + 78)
        XCTAssertEqual(fetchedClip.clipItems?.allObjects.count, 2)

        guard let fetchedItem2 = fetchedClip.clipItems?
            .allObjects
            .compactMap({ $0 as? Item })
            .first(where: { $0.id == UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")! })
        else {
            XCTFail()
            return
        }
        XCTAssertEqual(fetchedItem2.index, 1)

        guard let fetchedItem4 = fetchedClip.clipItems?
            .allObjects
            .compactMap({ $0 as? Item })
            .first(where: { $0.id == UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E54")! })
        else {
            XCTFail()
            return
        }
        XCTAssertEqual(fetchedItem4.index, 2)
    }

    func test_deleteAlbumHavingAlbumId_削除対象のアルバムが存在する場合_AlbumとAlbumItemが削除されClipは削除されない() {
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

        let request1: NSFetchRequest<Persistence.Album> = Album.fetchRequest()
        let fetchedItems = try! managedContext.fetch(request1)
        XCTAssertEqual(fetchedItems.count, 0)

        let request2: NSFetchRequest<AlbumItem> = AlbumItem.fetchRequest()
        let fetchedAlbumItems = try! managedContext.fetch(request2)
        XCTAssertEqual(fetchedAlbumItems.count, 0)

        let request3: NSFetchRequest<Persistence.Clip> = Clip.fetchRequest()
        let fetchedClips = try! managedContext.fetch(request3)
        XCTAssertEqual(fetchedClips.count, 3)
    }

    func test_deduplicateTagForObjectID_重複したタグが存在しない場合_空を返しTagは削除されない() {
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

        let results = service.deduplicateTag(for: tag1.objectID)
        try! managedContext.save()

        XCTAssertEqual(results.count, 0)

        let request1: NSFetchRequest<Persistence.Tag> = Tag.fetchRequest()
        let fetchedTags = try! managedContext.fetch(request1)
        XCTAssertEqual(fetchedTags.count, 2)

        let request2: NSFetchRequest<Persistence.Clip> = Clip.fetchRequest()
        let fetchedClips = try! managedContext.fetch(request2)
        XCTAssertEqual(fetchedClips.count, 1)
        guard let fetchedTags = (fetchedClips.first?.tags?.allObjects as? [Persistence.Tag])?.sorted(by: { $0.name! < $1.name! }) else {
            XCTFail("クリップにタグが存在しない")
            return
        }
        XCTAssertEqual(fetchedTags.count, 2)
    }

    func test_deduplicateTagForObjectID_重複したタグが存在する場合_重複したタグのIDを返しTagを削除する() {
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

        let results = service.deduplicateTag(for: tag1.objectID)
        try! managedContext.save()

        XCTAssertEqual(results, [
            UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!,
            UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E55")!
        ])

        let request1: NSFetchRequest<Persistence.Tag> = Tag.fetchRequest()
        let fetchedTags = (try! managedContext.fetch(request1))
            .sorted(by: { $0.id!.uuidString < $1.id!.uuidString })

        XCTAssertEqual(fetchedTags.count, 3)
        guard fetchedTags.count == 3 else { return }

        XCTAssertEqual(fetchedTags[0].id, UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51"))
        XCTAssertEqual(fetchedTags[0].name, "duplicated")
        XCTAssertEqual(fetchedTags[1].id, UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52"))
        XCTAssertEqual(fetchedTags[1].name, "tag1")
        XCTAssertEqual(fetchedTags[2].id, UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E54"))
        XCTAssertEqual(fetchedTags[2].name, "tag2")
    }
}
