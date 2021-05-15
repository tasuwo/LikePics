//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import CoreData
import Domain
import Persistence
import Smoothie
import TBoxCore
import TBoxUIKit
import UIKit

// swiftlint:disable identifier_name

class DependencyContainer {
    // MARK: - Properties

    // MARK: Image Loader

    let clipDiskCache: DiskCache
    let clipThumbnailLoader: ThumbnailLoader
    let albumThumbnailLoader: ThumbnailLoader
    let temporaryThumbnailLoader: ThumbnailLoader
    let _previewLoader: PreviewLoader

    // MARK: Storage

    let clipStorage: ClipStorage
    let tmpClipStorage: TemporaryClipStorageProtocol
    let referenceClipStorage: ReferenceClipStorageProtocol
    let imageStorage: ImageStorage
    let tmpImageStorage: TemporaryImageStorageProtocol
    let _userSettingStorage: UserSettingsStorageProtocol
    let cloudUsageContextStorage: CloudUsageContextStorageProtocol

    // MARK: Service

    let _clipCommandService: ClipCommandService
    let _clipQueryService: ClipQueryService
    let _clipSearchHistoryService: Persistence.ClipSearchHistoryService
    let _clipSearchSettingService: Persistence.ClipSearchSettingService
    let _imageQueryService: ImageQueryService
    let _integrityValidationService: ClipReferencesIntegrityValidationService
    let _temporariesPersistService: TemporariesPersistService

    // MARK: Core Data

    let coreDataStack: CoreDataStack
    let _cloudAvailabilityService: CloudAvailabilityService
    private var imageQueryContext: NSManagedObjectContext
    private var commandContext: NSManagedObjectContext

    let monitor: ICloudSyncMonitor

    // MARK: Queue

    private let commandLock = NSRecursiveLock()
    /// - Attention: 排他制御には`commandLock`を利用する
    private let clipCommandQueue = DispatchQueue(label: "net.tasuwo.TBox.ClipCommand")
    /// - Attention: 排他制御には`commandLock`を利用する
    private let imageQueryQueue = DispatchQueue(label: "net.tasuwo.TBox.ImageQuery")

    // MARK: Lock

    let transitionLock = TransitionLock()

    // MARK: Logger

    let logger: Loggable

    // MARK: - Lifecycle

    init(configuration: DependencyContainerConfiguration, cloudAvailabilityObserver: CloudAvailabilityService) throws {
        self.logger = RootLogger(loggers: [
            ConsoleLogger(scopes: [.default, .transition])
        ])

        self.tmpImageStorage = try TemporaryImageStorage(configuration: .resolve(for: Bundle.main, kind: .group))
        self.tmpClipStorage = try TemporaryClipStorage(config: .resolve(for: Bundle.main, kind: .group), logger: self.logger)
        self.referenceClipStorage = try ReferenceClipStorage(config: .resolve(for: Bundle.main), logger: self.logger)

        self.monitor = ICloudSyncMonitor(logger: self.logger)

        let userSettingsStorage = UserSettingsStorage()
        let cloudUsageContextStorage = CloudUsageContextStorage()
        self._userSettingStorage = userSettingsStorage
        self.cloudUsageContextStorage = cloudUsageContextStorage
        self._cloudAvailabilityService = cloudAvailabilityObserver

        self.coreDataStack = CoreDataStack(isICloudSyncEnabled: configuration.isCloudSyncEnabled, logger: logger)

        self.imageQueryContext = self.coreDataStack.newBackgroundContext(on: self.imageQueryQueue)
        self.commandContext = self.coreDataStack.newBackgroundContext(on: self.clipCommandQueue)
        // Note: clipStorage, imageStorage は、同一トランザクションとして書き込みを行うことが多いため、
        //       同一Contextとする
        self.clipStorage = ClipStorage(context: self.commandContext, logger: logger)
        self.imageStorage = ImageStorage(context: self.commandContext)
        self._clipQueryService = ClipQueryService(context: self.coreDataStack.viewContext)
        self._imageQueryService = ImageQueryService(context: self.imageQueryContext, logger: logger)

        self._clipSearchHistoryService = Persistence.ClipSearchHistoryService()
        self._clipSearchSettingService = Persistence.ClipSearchSettingService()

        Self.sweepLegacyThumbnailCachesIfExists()

        let defaultCostLimit = Int(MemoryCache.Configuration.defaultCostLimit())

        var clipCacheConfig = ThumbnailLoadQueue.Configuration(originalImageLoader: self._imageQueryService)
        let clipCacheDirectory = Self.resolveCacheDirectoryUrl(name: "clip-thumbnails")
        self.clipDiskCache = try DiskCache(path: clipCacheDirectory,
                                           config: .init(sizeLimit: 1024 * 1024 * 1024, countLimit: Int.max))
        clipCacheConfig.diskCache = self.clipDiskCache
        clipCacheConfig.compressionRatio = 0.5
        let clipMemoryCache = MemoryCache(config: .init(costLimit: defaultCostLimit * 3 / 5, countLimit: Int.max))
        clipCacheConfig.memoryCache = clipMemoryCache
        self.clipThumbnailLoader = ThumbnailLoader(queue: .init(config: clipCacheConfig))

        var albumCacheConfig = ThumbnailLoadQueue.Configuration(originalImageLoader: self._imageQueryService)
        albumCacheConfig.compressionRatio = 0.5
        let albumCacheDirectory = Self.resolveCacheDirectoryUrl(name: "album-thumbnails")
        let albumDiskCache = try DiskCache(path: albumCacheDirectory,
                                           config: .init(sizeLimit: 1024 * 1024 * 512, countLimit: 1000))
        albumCacheConfig.diskCache = albumDiskCache
        albumCacheConfig.memoryCache = MemoryCache(config: .init(costLimit: defaultCostLimit * 1 / 5, countLimit: Int.max))
        self.albumThumbnailLoader = ThumbnailLoader(queue: .init(config: albumCacheConfig))

        var temporaryCacheConfig = ThumbnailLoadQueue.Configuration(originalImageLoader: self._imageQueryService)
        temporaryCacheConfig.diskCache = nil
        temporaryCacheConfig.memoryCache = MemoryCache(config: .init(costLimit: defaultCostLimit * 1 / 5, countLimit: 50))
        self.temporaryThumbnailLoader = ThumbnailLoader(queue: .init(config: temporaryCacheConfig))

        let previewMemoryCache = MemoryCache(config: .init(costLimit: defaultCostLimit * 1 / 5, countLimit: 100))
        self._previewLoader = PreviewLoader(thumbnailCache: clipMemoryCache,
                                            thumbnailDiskCache: self.clipDiskCache,
                                            imageQueryService: self._imageQueryService,
                                            memoryCache: previewMemoryCache)

        self._clipCommandService = ClipCommandService(clipStorage: clipStorage,
                                                      referenceClipStorage: referenceClipStorage,
                                                      imageStorage: imageStorage,
                                                      diskCache: clipDiskCache,
                                                      // Note: ImageStorage, ClipStorage は同一 Context である前提
                                                      commandQueue: clipStorage,
                                                      lock: commandLock,
                                                      logger: logger)
        self._integrityValidationService = ClipReferencesIntegrityValidationService(clipStorage: clipStorage,
                                                                                    referenceClipStorage: referenceClipStorage,
                                                                                    // Note: ImageStorage, ClipStorage は同一 Context である前提
                                                                                    commandQueue: clipStorage,
                                                                                    lock: commandLock,
                                                                                    logger: logger)
        self._temporariesPersistService = TemporariesPersistService(temporaryClipStorage: tmpClipStorage,
                                                                    temporaryImageStorage: tmpImageStorage,
                                                                    clipStorage: clipStorage,
                                                                    referenceClipStorage: referenceClipStorage,
                                                                    imageStorage: imageStorage,
                                                                    // Note: ImageStorage, ClipStorage は同一 Context である前提
                                                                    commandQueue: clipStorage,
                                                                    lock: commandLock,
                                                                    logger: logger)

        self.coreDataStack.coreDataStackObserver = self
        self.coreDataStack.cloudStackObserver = _integrityValidationService
    }

    // MARK: - Methods

    func makeCloudStackLoader() -> CloudStackLoader {
        return CloudStackLoader(userSettingsStorage: self._userSettingStorage,
                                cloudAvailabilityService: self._cloudAvailabilityService,
                                cloudStack: self.coreDataStack)
    }

    func makeClipsIntegrityValidatorStore() -> Store<ClipsIntegrityValidatorState, ClipsIntegrityValidatorAction, ClipsIntegrityValidatorDependency> {
        return .init(initialState: ClipsIntegrityValidatorState(),
                     dependency: self,
                     reducer: ClipsIntegrityValidatorReducer())
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

extension DependencyContainer: CoreDataStackObserver {
    // MARK: - CoreDataStackObserver

    func coreDataStack(_ coreDataStack: CoreDataStack, reloaded container: NSPersistentCloudKitContainer) {
        let newImageQueryContext = coreDataStack.newBackgroundContext(on: self.imageQueryQueue)
        let newCommandContext = coreDataStack.newBackgroundContext(on: self.clipCommandQueue)

        self.imageQueryContext = newImageQueryContext
        self.commandContext = newCommandContext

        self.clipCommandQueue.sync {
            self.clipStorage.context = newCommandContext
            self.imageStorage.context = newCommandContext
        }

        self._clipQueryService.context = self.coreDataStack.viewContext
        self._imageQueryService.context = newImageQueryContext
    }
}

extension ClipCommandService: ClipStorable {}

extension DependencyContainer: HasTemporariesPersistService {
    var temporariesPersistService: TemporariesPersistServiceProtocol { _temporariesPersistService }
}

extension DependencyContainer: HasIntegrityValidationService {
    var integrityValidationService: ClipReferencesIntegrityValidationServiceProtocol { _integrityValidationService }
}
