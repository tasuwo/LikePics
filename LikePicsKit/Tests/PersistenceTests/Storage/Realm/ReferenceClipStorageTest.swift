//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import Domain
import RealmSwift
import XCTest

@testable import Persistence
@testable import TestHelper

class ReferenceClipStorageTest: XCTestCase {
    lazy var configuration = Realm.Configuration(inMemoryIdentifier: self.name, schemaVersion: 8)
    lazy var realm = try! Realm(configuration: configuration)

    var storage: ReferenceClipStorage!

    override func setUp() {
        storage = try! ReferenceClipStorage(config: .init(realmConfiguration: configuration))
        try! realm.write {
            realm.deleteAll()
        }
    }

    // TODO:
}
