//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import RealmSwift

extension LightweightClipStorage.Configuration {
    public static var main: LightweightClipStorage.Configuration {
        let realmFileName = "lightweight-clips.realm"

        var configuration = Realm.Configuration(
            schemaVersion: 0,
            migrationBlock: LightweightClipStorageMigrationService.migrationBlock,
            deleteRealmIfMigrationNeeded: false,
            objectTypes: [
                LightweightClipObject.self,
                LightweightTagObject.self
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
