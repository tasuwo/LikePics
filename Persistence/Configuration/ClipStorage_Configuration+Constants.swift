//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import RealmSwift

extension ClipStorage.Configuration {
    public static var document: ClipStorage.Configuration {
        let realmFileName = "clips.realm"

        var configuration = Realm.Configuration(
            schemaVersion: 10,
            migrationBlock: ClipStorageMigrationService.migrationBlock,
            deleteRealmIfMigrationNeeded: false,
            objectTypes: [
                ClipObject.self,
                ClipItemObject.self,
                AlbumObject.self,
                TagObject.self
            ]
        )

        if let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            configuration.fileURL = directory
                .appendingPathComponent(Constants.bundleIdentifier, isDirectory: true)
                .appendingPathComponent(realmFileName)
        } else {
            fatalError("Unable to resolve realm file url.")
        }

        return .init(realmConfiguration: configuration)
    }

    public static var group: ClipStorage.Configuration {
        let realmFileName = "temporary-clips.realm"

        var configuration = Realm.Configuration(
            schemaVersion: 0,
            migrationBlock: ClipStorageMigrationService.migrationBlock,
            deleteRealmIfMigrationNeeded: false,
            objectTypes: [
                ClipObject.self,
                ClipItemObject.self,
                TagObject.self
            ]
        )

        guard let directory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Constants.appGroupIdentifier) else {
            fatalError("Failed to resolve images containing directory url.")
        }

        configuration.fileURL = directory
            .appendingPathComponent(Constants.bundleIdentifier, isDirectory: true)
            .appendingPathComponent(realmFileName)

        return .init(realmConfiguration: configuration)
    }
}
