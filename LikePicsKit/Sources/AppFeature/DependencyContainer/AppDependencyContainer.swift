//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import CompositeKit
import CoreData
import Domain
import Environment
import LikePicsCore
import LikePicsUIKit
import Persistence
import Smoothie
import UIKit

// swiftlint:disable identifier_name

class AppDependencyContainer {
    // MARK: - Properties

    // MARK: Image Loader

    let clipDiskCache: DiskCache
    let clipThumbnailPipeline: Pipeline
    let albumThumbnailPipeline: Pipeline
    let clipItemThumbnailPipeline: Pipeline
    let temporaryThumbnailPipeline: Pipeline
    let previewPipeline: Pipeline
    let previewPrefetcher: PreviewPrefetcher

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
    let _clipQueryService: ClipQueryCacheService<ClipQueryService>
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
    private let _cloudStackLoader: CloudStackLoader

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

    init() throws {
        self.logger = RootLogger(loggers: [
            ConsoleLogger(scopes: [.default, .transition])
        ])

        // MARK: Storage

        self.tmpImageStorage = try TemporaryImageStorage(configuration: .resolve(for: Bundle.main, kind: .group))
        self.tmpClipStorage = try TemporaryClipStorage(config: .resolve(for: Bundle.main, kind: .group), logger: self.logger)
        self.referenceClipStorage = try ReferenceClipStorage(config: .resolve(for: Bundle.main), logger: self.logger)

        // MARK: CoreData

        self.monitor = ICloudSyncMonitor(logger: self.logger)

        let userSettingsStorage = UserSettingsStorage.shared
        let cloudUsageContextStorage = CloudUsageContextStorage()
        self._userSettingStorage = userSettingsStorage
        self.cloudUsageContextStorage = cloudUsageContextStorage
        self._cloudAvailabilityService = CloudAvailabilityService(cloudUsageContextStorage: CloudUsageContextStorage(),
                                                                  cloudAccountService: CloudAccountService())

        self.coreDataStack = CoreDataStack(isICloudSyncEnabled: self._userSettingStorage.readEnabledICloudSync(),
                                           logger: logger)
        self._cloudStackLoader = CloudStackLoader(userSettingsStorage: self._userSettingStorage,
                                                  cloudAvailabilityService: self._cloudAvailabilityService,
                                                  cloudStack: self.coreDataStack)

        self.imageQueryContext = self.coreDataStack.newBackgroundContext(on: self.imageQueryQueue)
        self.commandContext = self.coreDataStack.newBackgroundContext(on: self.clipCommandQueue)
        // Note: clipStorage, imageStorage は、同一トランザクションとして書き込みを行うことが多いため、
        //       同一Contextとする
        self.clipStorage = ClipStorage(context: self.commandContext, logger: logger)
        self.imageStorage = ImageStorage(context: self.commandContext)
        self._clipQueryService = ClipQueryCacheService(ClipQueryService(context: self.coreDataStack.viewContext))
        self._imageQueryService = ImageQueryService(context: self.imageQueryContext, logger: logger)

        self._clipSearchHistoryService = Persistence.ClipSearchHistoryService()
        self._clipSearchSettingService = Persistence.ClipSearchSettingService()

        // MARK: Image Loader

        Self.sweepLegacyThumbnailCachesIfExists()

        let memoryCache = MemoryCache(config: .default)

        // Clip

        var clipCacheConfig = Pipeline.Configuration()
        let clipCacheDirectory = Self.resolveCacheDirectoryUrl(name: "clip-thumbnails")
        self.clipDiskCache = try DiskCache(path: clipCacheDirectory,
                                           config: .init(sizeLimit: 1024 * 1024 * 1024,
                                                         countLimit: Int.max,
                                                         dateLimit: 30))
        clipCacheConfig.diskCache = self.clipDiskCache
        clipCacheConfig.compressionRatio = 0.5
        clipCacheConfig.memoryCache = memoryCache
        self.clipThumbnailPipeline = .init(config: clipCacheConfig)

        // Album

        var albumCacheConfig = Pipeline.Configuration()
        albumCacheConfig.compressionRatio = 0.5
        let albumCacheDirectory = Self.resolveCacheDirectoryUrl(name: "album-thumbnails")
        let albumDiskCache = try DiskCache(path: albumCacheDirectory,
                                           config: .init(sizeLimit: 1024 * 1024 * 512,
                                                         countLimit: 1000,
                                                         dateLimit: 30))
        albumCacheConfig.diskCache = albumDiskCache
        albumCacheConfig.memoryCache = memoryCache
        self.albumThumbnailPipeline = Pipeline(config: albumCacheConfig)

        // Clip Item

        var clipItemCacheConfig = Pipeline.Configuration()
        let clipItemCacheDirectory = Self.resolveCacheDirectoryUrl(name: "clip-item-thumbnails")
        let clipItemDiskCache = try DiskCache(path: clipItemCacheDirectory,
                                              config: .init(sizeLimit: 1024 * 1024 * 512,
                                                            countLimit: 100,
                                                            dateLimit: 30))
        clipItemCacheConfig.diskCache = clipItemDiskCache
        clipItemCacheConfig.memoryCache = memoryCache
        self.clipItemThumbnailPipeline = Pipeline(config: clipItemCacheConfig)

        // Temporary

        var temporaryCacheConfig = Pipeline.Configuration()
        temporaryCacheConfig.diskCache = nil
        temporaryCacheConfig.memoryCache = memoryCache
        self.temporaryThumbnailPipeline = Pipeline(config: temporaryCacheConfig)

        // Preview

        var previewCacheConfig = Pipeline.Configuration()
        previewCacheConfig.dataCachingQueue.maxConcurrentOperationCount = 1
        previewCacheConfig.downsamplingQueue.maxConcurrentOperationCount = 1
        previewCacheConfig.imageDecompressingQueue.maxConcurrentOperationCount = 1
        previewCacheConfig.diskCache = nil
        previewCacheConfig.memoryCache = memoryCache
        self.previewPipeline = Pipeline(config: previewCacheConfig)

        self.previewPrefetcher = PreviewPrefetcher(pipeline: clipThumbnailPipeline,
                                                   imageQueryService: _imageQueryService,
                                                   scale: UIScreen.main.scale)

        // MARK: Service

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
        self.cloudStackLoader.startObserveCloudAvailability()
    }

    // MARK: - Methods

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

extension AppDependencyContainer: CoreDataStackObserver {
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

        self._clipQueryService.internalService.context = self.coreDataStack.viewContext
        self._imageQueryService.context = newImageQueryContext
    }
}

extension ClipCommandService: ClipStorable {}

extension AppDependencyContainer: HasTemporariesPersistService {
    var temporariesPersistService: TemporariesPersistServiceProtocol { _temporariesPersistService }
}

extension AppDependencyContainer: HasIntegrityValidationService {
    var integrityValidationService: ClipReferencesIntegrityValidationServiceProtocol { _integrityValidationService }
}

extension AppDependencyContainer: HasCloudStackLoader {
    var cloudStackLoader: CloudStackLoader { _cloudStackLoader }
}
