//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Foundation
import RealmSwift

public extension ReferenceClipStorage.Configuration {
    static func resolve(for bundle: Bundle) -> ReferenceClipStorage.Configuration {
        let realmFileName = "reference-clips.realm"

        var configuration = Realm.Configuration(
            schemaVersion: 1,
            migrationBlock: ReferenceClipStorageMigrationService.migrationBlock,
            deleteRealmIfMigrationNeeded: false,
            objectTypes: [
                ReferenceTagObject.self
            ]
        )

        guard let bundleIdentifier = bundle.bundleIdentifier else {
            fatalError("Failed to resolve bundle identifier")
        }

        if let directory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.\(bundleIdentifier)") {
            configuration.fileURL = directory
                .appendingPathComponent(bundleIdentifier, isDirectory: true)
                .appendingPathComponent(realmFileName)
        } else {
            fatalError("Unable to resolve realm file url.")
        }

        return .init(realmConfiguration: configuration)
    }
}
