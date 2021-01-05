//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import Domain
import Nimble
import Quick
import RealmSwift

@testable import Persistence
@testable import TestHelper

class TemporaryClipStorageSpec: QuickSpec {
    override func spec() {
        let configuration = Realm.Configuration(inMemoryIdentifier: self.name, schemaVersion: 8)
        let realm = try! Realm(configuration: configuration)

        var clipStorage: TemporaryClipStorage!

        beforeEach {
            clipStorage = try! TemporaryClipStorage(config: .init(realmConfiguration: configuration), logger: RootLogger.shared)
            try! realm.write {
                realm.deleteAll()
            }
        }

        // MARK: Create

        describe("create(clip:)") {
            var result: Result<Domain.Clip, ClipStorageError>!
            beforeEach {
                try! clipStorage.beginTransaction()
                result = clipStorage.create(
                    clip: Domain.Clip.makeDefault(
                        id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!,
                        description: "my description",
                        items: [
                            ClipItem.makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!, imageFileName: "hoge1"),
                            ClipItem.makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!, imageFileName: "hoge2"),
                            ClipItem.makeDefault(id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!, imageFileName: "hoge3"),
                        ],
                        tags: [],
                        isHidden: false,
                        registeredDate: Date(timeIntervalSince1970: 0),
                        updatedDate: Date(timeIntervalSince1970: 1000)
                    )
                )
                try! clipStorage.commitTransaction()
            }
            it("successが返る") {
                guard case let .failure(error) = result else {
                    expect(true).to(beTrue())
                    return
                }
                fail("Unexpected failed with \(error)")
            }
            it("ClipとClipItemがRealmに書き込まれている") {
                let clips = realm.objects(ClipObject.self)
                expect(clips).to(haveCount(1))
                expect(clips.first?.id).to(equal("E621E1F8-C36C-495A-93FC-0C247A3E6E51"))
                expect(clips.first?.descriptionText).to(equal("my description"))
                expect(clips.first?.isHidden).to(beFalse())
                expect(clips.first?.items).to(haveCount(3))
                expect(clips.first?.tags).to(haveCount(0))
                expect(clips.first?.registeredAt).to(equal(Date(timeIntervalSince1970: 0)))
                expect(clips.first?.updatedAt).to(equal(Date(timeIntervalSince1970: 1000)))
            }
        }

        // MARK: Delete

        // TODO:
    }
}
