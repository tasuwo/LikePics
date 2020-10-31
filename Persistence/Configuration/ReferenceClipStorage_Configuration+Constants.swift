//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import RealmSwift

extension ReferenceClipStorage.Configuration {
    public static var group: ReferenceClipStorage.Configuration {
        let realmFileName = "reference-clips.realm"

        var configuration = Realm.Configuration(
            schemaVersion: 0,
            migrationBlock: ReferenceClipStorageMigrationService.migrationBlock,
            deleteRealmIfMigrationNeeded: false,
            objectTypes: [
                ReferenceClipObject.self,
                ReferenceTagObject.self
            ]
        )

        if let directory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Constants.appGroupIdentifier) {
            configuration.fileURL = directory
                .appendingPathComponent(Constants.bundleIdentifier, isDirectory: true)
                .appendingPathComponent(realmFileName)
        } else {
            fatalError("Unable to resolve realm file url.")
        }

        return .init(realmConfiguration: configuration)
    }
}
