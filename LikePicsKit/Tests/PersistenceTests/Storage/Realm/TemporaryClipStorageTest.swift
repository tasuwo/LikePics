//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import Domain
import RealmSwift
import XCTest

@testable import Persistence
@testable import TestHelper

class TemporaryClipStorageTest: XCTestCase {
    lazy var configuration = Realm.Configuration(inMemoryIdentifier: self.name, schemaVersion: 8)
    lazy var realm = try! Realm(configuration: configuration)

    var clipStorage: TemporaryClipStorage!

    override func setUp() {
        clipStorage = try! TemporaryClipStorage(config: .init(realmConfiguration: configuration))
        try! realm.write {
            realm.deleteAll()
        }
    }

    func test_createClip() {
        try! clipStorage.beginTransaction()
        let result = clipStorage.create(
            clip: ClipRecipe.makeDefault(
                id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!,
                description: "my description",
                items: [
                    ClipItemRecipe.makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!, imageFileName: "hoge1"),
                    ClipItemRecipe.makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!, imageFileName: "hoge2"),
                    ClipItemRecipe.makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!, imageFileName: "hoge3"),
                ],
                tagIds: [],
                isHidden: false,
                registeredDate: Date(timeIntervalSince1970: 0),
                updatedDate: Date(timeIntervalSince1970: 1000)
            )
        )
        try! clipStorage.commitTransaction()

        switch result {
        case .failure:
            XCTFail("Realm DB の更新に失敗した")

        default:
            break
        }

        let clips = realm.objects(ClipObject.self)
        XCTAssertEqual(clips.count, 1)
        XCTAssertEqual(clips.first?.id, "E621E1F8-C36C-495A-93FC-0C247A3E6E51")
        XCTAssertEqual(clips.first?.descriptionText, "my description")
        XCTAssertFalse(clips.first!.isHidden)
        XCTAssertEqual(clips.first?.items.count, 3)
        XCTAssertEqual(clips.first?.tagIds.count, 0)
        XCTAssertEqual(clips.first?.registeredAt, Date(timeIntervalSince1970: 0))
        XCTAssertEqual(clips.first?.updatedAt, Date(timeIntervalSince1970: 1000))
    }

    // TODO:
}
