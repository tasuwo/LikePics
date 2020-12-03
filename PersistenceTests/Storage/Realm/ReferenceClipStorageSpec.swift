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

        // TODO:
    }
}
