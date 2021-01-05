//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import CoreData
import Domain
import Persistence
import Smoothie
import TBoxCore
import UIKit

class DependencyContainer {
    // MARK: - Properties

    // MARK: Image Loader

    let clipDiskCache: DiskCache
    let clipThumbnailLoader: ThumbnailLoader
    let albumThumbnailLoader: ThumbnailLoader
    let temporaryThumbnailLoader: ThumbnailLoader

    // MARK: Storage

    let clipStorage: ClipStorage
    let tmpClipStorage: TemporaryClipStorageProtocol
    let referenceClipStorage: ReferenceClipStorageProtocol
    let imageStorage: ImageStorage
    let tmpImageStorage: TemporaryImageStorageProtocol
    let userSettingsStorage: UserSettingsStorageProtocol
    let cloudUsageContextStorage: CloudUsageContextStorageProtocol

    // MARK: Service

    let clipCommandService: ClipCommandService
    let clipQueryService: ClipQueryService
    let imageQueryService: ImageQueryService
    let integrityValidationService: ClipReferencesIntegrityValidationService
    let persistService: TemporariesPersistServiceProtocol
    let cloudChangeDetecter: CloudKitChangeDetecter

    // MARK: Core Data

    let coreDataStack: CoreDataStack
    let cloudAvailabilityObserver: CloudAvailabilityObserver
    var imageQueryContext: NSManagedObjectContext
    var commandContext: NSManagedObjectContext

    let monitor: ICloudSyncMonitor

    // MARK: Queue

    let clipCommandQueue = DispatchQueue(label: "net.tasuwo.TBox.ClipCommand")
    let imageQueryQueue = DispatchQueue(label: "net.tasuwo.TBox.ImageQuery")

    // MARK: Logger

    let logger: TBoxLoggable

    // MARK: - Lifecycle

    init(configuration: DependencyContainerConfiguration, cloudAvailabilityObserver: CloudAvailabilityObserver) throws {
        self.tmpImageStorage = try TemporaryImageStorage(configuration: .resolve(for: Bundle.main, kind: .group))
        self.logger = RootLogger.shared
        self.tmpClipStorage = try TemporaryClipStorage(config: .resolve(for: Bundle.main, kind: .group), logger: self.logger)
        self.referenceClipStorage = try ReferenceClipStorage(config: .resolve(for: Bundle.main), logger: self.logger)

        self.monitor = ICloudSyncMonitor(logger: self.logger)

        let userSettingsStorage = UserSettingsStorage()
        let cloudUsageContextStorage = CloudUsageContextStorage()
        self.userSettingsStorage = userSettingsStorage
        self.cloudUsageContextStorage = cloudUsageContextStorage
        self.cloudAvailabilityObserver = cloudAvailabilityObserver

        self.coreDataStack = CoreDataStack(isICloudSyncEnabled: configuration.isCloudSyncEnabled)

        self.imageQueryContext = self.coreDataStack.newBackgroundContext(on: self.imageQueryQueue)
        self.commandContext = self.coreDataStack.newBackgroundContext(on: self.clipCommandQueue)
        self.clipStorage = ClipStorage(context: self.commandContext)
        self.imageStorage = ImageStorage(context: self.commandContext)
        self.clipQueryService = ClipQueryService(context: self.coreDataStack.viewContext)
        self.imageQueryService = ImageQueryService(context: self.imageQueryContext)

        Self.sweepLegacyThumbnailCachesIfExists()

        let defaultCostLimit = Int(MemoryCache.Configuration.defaultCostLimit())

        var clipCacheConfig = ThumbnailLoadPipeline.Configuration(dataLoader: self.imageQueryService)
        let clipCacheDirectory = Self.resolveCacheDirectoryUrl(name: "clip-thumbnails")
        self.clipDiskCache = try DiskCache(path: clipCacheDirectory,
                                           config: .init(sizeLimit: 1024 * 1024 * 1024, countLimit: Int.max))
        clipCacheConfig.diskCache = self.clipDiskCache
        clipCacheConfig.memoryCache = MemoryCache(config: .init(costLimit: defaultCostLimit, countLimit: Int.max))
        self.clipThumbnailLoader = ThumbnailLoader(pipeline: .init(config: clipCacheConfig))

        var albumCacheConfig = ThumbnailLoadPipeline.Configuration(dataLoader: self.imageQueryService)
        let albumCacheDirectory = Self.resolveCacheDirectoryUrl(name: "album-thumbnails")
        let albumDiskCache = try DiskCache(path: albumCacheDirectory,
                                           config: .init(sizeLimit: 1024 * 1024 * 512, countLimit: 1000))
        albumCacheConfig.diskCache = albumDiskCache
        albumCacheConfig.memoryCache = MemoryCache(config: .init(costLimit: defaultCostLimit / 4, countLimit: Int.max))
        self.albumThumbnailLoader = ThumbnailLoader(pipeline: .init(config: albumCacheConfig))

        var temporaryCacheConfig = ThumbnailLoadPipeline.Configuration(dataLoader: self.imageQueryService)
        temporaryCacheConfig.diskCache = nil
        temporaryCacheConfig.memoryCache = MemoryCache(config: .init(costLimit: defaultCostLimit / 4, countLimit: 50))
        self.temporaryThumbnailLoader = ThumbnailLoader(pipeline: .init(config: temporaryCacheConfig))

        self.clipCommandService = ClipCommandService(clipStorage: self.clipStorage,
                                                     referenceClipStorage: referenceClipStorage,
                                                     imageStorage: self.imageStorage,
                                                     diskCache: self.clipDiskCache,
                                                     logger: self.logger,
                                                     queue: self.clipCommandQueue)
        self.integrityValidationService = ClipReferencesIntegrityValidationService(clipStorage: self.clipStorage,
                                                                                   referenceClipStorage: self.referenceClipStorage,
                                                                                   logger: self.logger,
                                                                                   queue: self.clipCommandQueue)
        self.persistService = TemporariesPersistService(temporaryClipStorage: self.tmpClipStorage,
                                                        temporaryImageStorage: self.tmpImageStorage,
                                                        clipStorage: self.clipStorage,
                                                        referenceClipStorage: self.referenceClipStorage,
                                                        imageStorage: self.imageStorage,
                                                        logger: self.logger,
                                                        queue: self.clipCommandQueue)

        self.cloudChangeDetecter = CloudKitChangeDetecter()

        self.coreDataStack.dependency = self
        self.cloudChangeDetecter.set(self.integrityValidationService)
        self.cloudChangeDetecter.startObserve(self.coreDataStack)
    }

    // MARK: - Methods

    func makeCloudStackLoader() -> CloudStackLoader {
        return CloudStackLoader(userSettingsStorage: self.userSettingsStorage,
                                cloudAvailabilityStore: self.cloudAvailabilityObserver,
                                cloudStack: self.coreDataStack)
    }

    func makeClipIntegrityResolvingViewModel() -> ClipIntegrityResolvingViewModelType {
        return ClipIntegrityResolvingViewModel(persistService: self.persistService,
                                               integrityValidationService: self.integrityValidationService)
    }

    private static func sweepLegacyThumbnailCachesIfExists() {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
            fatalError("Failed to resolve bundle identifier")
        }

        let targetUrl: URL = {
            let directoryName: String = "thumbnails"
            if let directory = try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true) {
                return directory
                    .appendingPathComponent(bundleIdentifier, isDirectory: true)
                    .appendingPathComponent(directoryName, isDirectory: true)
            } else {
                fatalError("Failed to resolve directory url for image cache.")
            }
        }()

        if FileManager.default.fileExists(atPath: targetUrl.path) {
            try? FileManager.default.removeItem(at: targetUrl)
        }
    }

    private static func resolveCacheDirectoryUrl(name: String) -> URL {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
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

extension DependencyContainer: CoreDataStackDependency {
    // MARK: - CoreDataStackDependency

    func coreDataStack(_ coreDataStack: CoreDataStack, replaced container: NSPersistentCloudKitContainer) {
        let newImageQueryContext = coreDataStack.newBackgroundContext(on: self.imageQueryQueue)
        let newCommandContext = coreDataStack.newBackgroundContext(on: self.clipCommandQueue)

        self.imageQueryContext = newImageQueryContext
        self.commandContext = newCommandContext

        self.clipCommandQueue.sync {
            self.clipStorage.context = newCommandContext
            self.imageStorage.context = newCommandContext
        }

        self.clipQueryService.context = self.coreDataStack.viewContext
        self.imageQueryService.context = newImageQueryContext
    }
}

extension ClipCommandService: ClipStorable {}

extension CoreDataStack {
    func newBackgroundContext(on queue: DispatchQueue) -> NSManagedObjectContext {
        return queue.sync {
            let context = self.newBackgroundContext
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            context.transactionAuthor = CoreDataStack.transactionAuthor
            return context
        }
    }
}
