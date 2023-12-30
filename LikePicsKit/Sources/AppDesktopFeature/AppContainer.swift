//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import CloudKit
import Combine
import CoreData
import Domain
import Foundation
import Persistence
import PersistentStack
import Smoothie

public final class AppContainer: ObservableObject {
    // MARK: - Properties

    @Published private(set) var viewContext: NSManagedObjectContext

    // MARK: Image Loader

    let clipThumbnailProcessingQueue: ImageProcessingQueue
    let albumThumbnailProcessingQueue: ImageProcessingQueue
    private let clipDiskCache: DiskCache
    private let albumDiskCache: DiskCache

    // MARK: Service

    let imageQueryService: ImageQueryService

    // MARK: Core Data

    private let persistentStack: PersistentStack
    private let persistentStackLoader: PersistentStackLoader
    private let persistentStackMonitor: PersistentStackMonitor
    private var persistentStackLoading: Task<Void, Never>?
    private var persistentStackReloading: Task<Void, Never>?
    private var persistentStackEventsObserving: Set<AnyCancellable> = .init()
    private var imageQueryContext: NSManagedObjectContext
    private var cloudAvailabilityObservationTask: Task<Void, Never>?

    let cloudAvailability: CloudSyncAvailability

    // MARK: Queue

    private let imageQueryQueue = DispatchQueue(label: "net.tasuwo.TBox.ImageQuery")

    // MARK: Bundle

    public let appBundle: Bundle

    public init(appBundle: Bundle) throws {
        self.appBundle = appBundle
        let isCloudSyncEnabled = UserDefaults.standard.bool(forKey: AppStorageKeys.CloudSync.key)

        // MARK: CoreData

        var persistentStackConf = PersistentStack.Configuration(author: "app",
                                                                persistentContainerName: "Model",
                                                                managedObjectModelUrl: ManagedObjectModelUrl)
        persistentStackConf.persistentHistoryTokenSaveDirectory = NSPersistentContainer
            .defaultDirectoryURL()
            .appendingPathComponent("TBox", isDirectory: true)
        persistentStackConf.persistentHistoryTokenFileName = "token.data"
        persistentStackConf.shouldLoadPersistentContainerAtInitialized = true
        self.persistentStack = PersistentStack(configuration: persistentStackConf, isCloudKitSyncEnabled: isCloudSyncEnabled)
        self.viewContext = persistentStack.viewContext

        self.persistentStackLoader = PersistentStackLoader(persistentStack: persistentStack,
                                                           settingStorage: CloudSyncSettingStorage())
        self.persistentStackMonitor = PersistentStackMonitor()

        self.imageQueryContext = self.persistentStack.newBackgroundContext(on: self.imageQueryQueue)
        self.imageQueryService = ImageQueryService(context: self.imageQueryContext)

        self.cloudAvailability = .init()
        self.cloudAvailability.isAvailable = persistentStackLoader.isCloudKitSyncAvailable

        // MARK: Image Loader

        let memoryCache = MemoryCache(config: .default)

        // Clip

        var clipCacheConfig = ImageProcessingQueue.Configuration()
        let clipCacheDirectory = Self.resolveCacheDirectoryUrl(name: "clip-thumbnails", appBundle: appBundle)
        self.clipDiskCache = try DiskCache(path: clipCacheDirectory,
                                           config: .init(sizeLimit: 1024 * 1024 * 1024,
                                                         countLimit: Int.max,
                                                         dateLimit: 30))
        clipCacheConfig.diskCache = self.clipDiskCache
        clipCacheConfig.memoryCache = memoryCache
        self.clipThumbnailProcessingQueue = .init(config: clipCacheConfig)

        // Album

        var albumCacheConfig = ImageProcessingQueue.Configuration()
        let albumCacheDirectory = Self.resolveCacheDirectoryUrl(name: "album-thumbnails", appBundle: appBundle)
        albumDiskCache = try DiskCache(path: albumCacheDirectory,
                                       config: .init(sizeLimit: 1024 * 1024 * 512,
                                                     countLimit: 1000,
                                                     dateLimit: 30))
        albumCacheConfig.diskCache = albumDiskCache
        albumCacheConfig.memoryCache = memoryCache
        self.albumThumbnailProcessingQueue = ImageProcessingQueue(config: albumCacheConfig)

        // MARK: Observation

        cloudAvailabilityObservationTask = Task { @MainActor [persistentStackLoader, cloudAvailability] in
            for await isAvailable in persistentStackLoader.isCloudKitSyncAvailables() {
                cloudAvailability.isAvailable = isAvailable
            }
        }

        persistentStackReloading = Task { @MainActor [persistentStack, imageQueryQueue, weak self] in
            for await _ in persistentStack.reloaded.values {
                self?.viewContext = persistentStack.viewContext

                let newImageQueryContext = persistentStack.newBackgroundContext(on: imageQueryQueue)
                self?.imageQueryContext = newImageQueryContext

                self?.imageQueryService.context = newImageQueryContext
            }
        }

        // TODO: RemoteChangeMergeHandler

        persistentStackMonitor.startMonitoring()

        persistentStackLoading = self.persistentStackLoader.run()
    }

    deinit {
        persistentStackReloading?.cancel()
        cloudAvailabilityObservationTask?.cancel()
    }

    private static func resolveCacheDirectoryUrl(name: String, appBundle: Bundle) -> URL {
        guard let bundleIdentifier = appBundle.bundleIdentifier else {
            fatalError("Failed to resolve bundle identifier")
        }

        let targetUrl: URL = {
            let directoryName: String = name
            if let directory = try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true) {
                return directory
                    .appendingPathComponent(bundleIdentifier, isDirectory: true)
                    .appendingPathComponent(directoryName, isDirectory: true)
            } else {
                fatalError("Failed to resolve directory url for image cache.")
            }
        }()

        return targetUrl
    }
}
