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

class ReferenceClipStorageSpec: QuickSpec {
    override func spec() {
        let configuration = Realm.Configuration(inMemoryIdentifier: self.name, schemaVersion: 8)
        let realm = try! Realm(configuration: configuration)

        var storage: ReferenceClipStorage!

        beforeEach {
            storage = try! ReferenceClipStorage(config: .init(realmConfiguration: configuration),
                                                logger: RootLogger.shared)
            try! realm.write {
                realm.deleteAll()
            }
        }

        describe("readAllDirtyClips()") {
            beforeEach {
                try! realm.write {
                    realm.add(ReferenceClipObject.makeDefault(id: "1", isDirty: true))
                    realm.add(ReferenceClipObject.makeDefault(id: "2", isDirty: false))
                    realm.add(ReferenceClipObject.makeDefault(id: "3", isDirty: true))
                    realm.add(ReferenceClipObject.makeDefault(id: "4", isDirty: false))
                    realm.add(ReferenceClipObject.makeDefault(id: "5", isDirty: true))
                }
            }
            it("Dirtyなオブジェクトのみが取得できる") {
                guard case let .success(clips) = storage.readAllDirtyClips() else {
                    fail("Unexpected failure")
                    return
                }
                expect(clips).to(equal([
                    .makeDefault(id: "1", isDirty: true),
                    .makeDefault(id: "3", isDirty: true),
                    .makeDefault(id: "5", isDirty: true),
                ]))
            }
        }

        describe("cleanAllClips()") {
            var result: Result<Void, ClipStorageError>!
            beforeEach {
                try! realm.write {
                    realm.add(ReferenceClipObject.makeDefault(id: "1", isDirty: true))
                    realm.add(ReferenceClipObject.makeDefault(id: "2", isDirty: false))
                    realm.add(ReferenceClipObject.makeDefault(id: "3", isDirty: true))
                    realm.add(ReferenceClipObject.makeDefault(id: "4", isDirty: false))
                    realm.add(ReferenceClipObject.makeDefault(id: "5", isDirty: true))
                }

                try! storage.beginTransaction()
                result = storage.cleanAllClips()
                try! storage.commitTransaction()
            }
            it("successが返る") {
                if case let .failure(error) = result {
                    fail("Unexpected failure: \(error.localizedDescription)")
                }
            }
            it("Dirtyフラグが全てfalseになる") {
                let clips = realm.objects(ReferenceClipObject.self).sorted(by: { $0.id < $1.id })
                expect(clips).to(haveCount(5))
                guard clips.count == 5 else { return }
                expect(clips[0].isDirty).to(beFalse())
                expect(clips[1].isDirty).to(beFalse())
                expect(clips[2].isDirty).to(beFalse())
                expect(clips[3].isDirty).to(beFalse())
                expect(clips[4].isDirty).to(beFalse())
            }
        }
    }
}
