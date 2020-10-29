//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import RealmSwift

public class TemporaryClipStorage {
    public enum StorageConfiguration {
        static let realmFileName = "clips.realm"

        public static func makeConfiguration() -> Realm.Configuration {
            var configuration = Realm.Configuration(
                schemaVersion: 0,
                migrationBlock: ClipStorageMigrationService.migrationBlock,
                deleteRealmIfMigrationNeeded: false
            )

            if let appGroupIdentifier = Constants.appGroupIdentifier,
                let directory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
            {
                configuration.fileURL = directory.appendingPathComponent(self.realmFileName)
            } else {
                fatalError("Unable to resolve realm file url.")
            }

            return configuration
        }
    }
}
