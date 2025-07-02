//
//  Copyright ©︎ 2024 Tasuku Tozawa. All rights reserved.
//

import Combine
import CoreData
import Foundation
import Persistence
import PersistentStack

public final class Container: ObservableObject {
    private(set) var viewContext: NSManagedObjectContext
    private let persistentStack: PersistentStack

    public init(bundleIdentifier: String) {
        let appGroupIdentifier = "group.\(bundleIdentifier)"
        UserDefaults.appGroup = UserDefaults(suiteName: appGroupIdentifier)!

        // MARK: CoreData

        var persistentStackConf = PersistentStack.Configuration(
            author: "share-extension",
            persistentContainerName: "Model",
            managedObjectModelUrl: ManagedObjectModelUrl
        )
        persistentStackConf.persistentContainerUrl = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)!
            .appending(path: "likepics.sqlite", directoryHint: .notDirectory)
        persistentStackConf.persistentHistoryTokenSaveDirectory =
            NSPersistentContainer
            .defaultDirectoryURL()
            .appendingPathComponent("LikePics", isDirectory: true)
        persistentStackConf.persistentHistoryTokenFileName = "share-extension-token.data"
        persistentStackConf.shouldLoadPersistentContainerAtInitialized = true
        self.persistentStack = PersistentStack(configuration: persistentStackConf, isCloudKitSyncEnabled: false)
        self.viewContext = persistentStack.viewContext

        // TODO: RemoteChangeMergeHandler
    }
}
