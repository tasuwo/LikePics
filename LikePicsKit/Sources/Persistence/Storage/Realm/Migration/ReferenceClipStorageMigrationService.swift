//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import RealmSwift

enum ReferenceClipStorageMigrationService {
    static let migrationBlock: MigrationBlock = { migration, oldSchemaVersion in
        if oldSchemaVersion < 1 {
            Self.migrationToV1(migration)
        }
    }

    private static func migrationToV1(_ migration: Migration) {
        migration.enumerateObjects(ofType: ReferenceTagObject.className()) { _, newObject in
            // swiftlint:disable:next force_unwrapping
            newObject!["isHidden"] = false
        }
    }
}
