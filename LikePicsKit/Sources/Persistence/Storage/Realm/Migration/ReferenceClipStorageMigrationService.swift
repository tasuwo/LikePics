//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import Foundation
import RealmSwift

// swiftlint:disable force_unwrapping force_cast

enum ReferenceClipStorageMigrationService {
    static let migrationBlock: MigrationBlock = { migration, oldSchemaVersion in
        if oldSchemaVersion < 1 {
            Self.migrationToV1(migration)
        }
        if oldSchemaVersion < 2 {
            Self.migrationToV2(migration)
        }
        if oldSchemaVersion < 3 {
            Self.migrationToV3(migration)
        }
    }

    private static func migrationToV1(_ migration: Migration) {
        migration.enumerateObjects(ofType: ReferenceTagObject.className()) { _, newObject in
            newObject!["isHidden"] = false
        }
    }

    private static func migrationToV2(_ migration: Migration) {
        migration.enumerateObjects(ofType: ReferenceTagObject.className()) { oldObject, newObject in
            let string = oldObject!["id"] as! String
            newObject!["id"] = UUID(uuidString: string)!
        }
    }

    private static func migrationToV3(_ migration: Migration) {
        migration.enumerateObjects(ofType: ReferenceTagObject.className()) { _, newObject in
            newObject!["clipCount"] = nil
        }
    }
}
