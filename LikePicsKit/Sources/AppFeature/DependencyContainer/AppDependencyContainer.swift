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

typealias AppDependencyContaining = HasPasteboard
    & HasClipCommandService
    & HasClipQueryService
    & HasClipSearchSettingService
    & HasClipSearchHistoryService
    & HasUserSettingStorage
    & HasImageQueryService
    & HasTransitionLock
    & HasCloudAvailabilityService
    & HasModalNotificationCenter
    & HasTemporariesPersistService
    & HasIntegrityValidationService
    & HasCloudStackLoader
    & HasTagCommandService
    & HasNop
    & HasLogger
    & HasClipStore
    & HasDiskCaches
    & HasImageLoaderSettings

class AppDependencyContainer {
    // MARK: - Properties

    // MARK: Image Loader

    private let _clipDiskCache: DiskCache
    private let _albumDiskCache: DiskCache
    private let _clipItemDiskCache: DiskCache
    private let _clipThumbnailPipeline: Pipeline
    private let _albumThumbnailPipeline: Pipeline
    private let _clipItemThumbnailPipeline: Pipeline
    private let _temporaryThumbnailPipeline: Pipeline
    private let _previewPipeline: Pipeline
    private let _previewPrefetcher: PreviewPrefetcher

    // MARK: Storage

    private let clipStorage: ClipStorage
    private let tmpClipStorage: TemporaryClipStorageProtocol
    private let referenceClipStorage: ReferenceClipStorageProtocol
    private let imageStorage: ImageStorage
    private let tmpImageStorage: TemporaryImageStorageProtocol
    private let _userSettingStorage: UserSettingsStorageProtocol
    private let cloudUsageContextStorage: CloudUsageContextStorageProtocol

    // MARK: Service

    private let _clipCommandService: ClipCommandService
    private let _clipQueryService: ClipQueryCacheService<ClipQueryService>
    private let _clipSearchHistoryService: Persistence.ClipSearchHistoryService
    private let _clipSearchSettingService: Persistence.ClipSearchSettingService
    private let _imageQueryService: ImageQueryService
    private let _integrityValidationService: ClipReferencesIntegrityValidationService
    private let _temporariesPersistService: TemporariesPersistService

    // MARK: Core Data

    private let coreDataStack: CoreDataStack
    private let _cloudAvailabilityService: CloudAvailabilityService
    private var imageQueryContext: NSManagedObjectContext
    private var commandContext: NSManagedObjectContext

    private let monitor: ICloudSyncMonitor
    private let _cloudStackLoader: CloudStackLoader

    // MARK: Queue

    private let commandLock = NSRecursiveLock()
    /// - Attention: 排他制御には`commandLock`を利用する
    private let clipCommandQueue = DispatchQueue(label: "net.tasuwo.TBox.ClipCommand")
    /// - Attention: 排他制御には`commandLock`を利用する
    private let imageQueryQueue = DispatchQueue(label: "net.tasuwo.TBox.ImageQuery")

    // MARK: Lock

    private let _transitionLock = TransitionLock()

    // MARK: Logger

    private let _logger: Loggable

    // MARK: - Lifecycle

    init() throws {
        self._logger = RootLogger(loggers: [
            ConsoleLogger(scopes: [.default, .transition])
        ])

        // MARK: Storage

        self.tmpImageStorage = try TemporaryImageStorage(configuration: .resolve(for: Bundle.main, kind: .group))
        self.tmpClipStorage = try TemporaryClipStorage(config: .resolve(for: Bundle.main, kind: .group), logger: _logger)
        self.referenceClipStorage = try ReferenceClipStorage(config: .resolve(for: Bundle.main), logger: _logger)

        // MARK: CoreData

        self.monitor = ICloudSyncMonitor(logger: _logger)

        let userSettingsStorage = UserSettingsStorage.shared
        let cloudUsageContextStorage = CloudUsageContextStorage()
        self._userSettingStorage = userSettingsStorage
        self.cloudUsageContextStorage = cloudUsageContextStorage
        self._cloudAvailabilityService = CloudAvailabilityService(cloudUsageContextStorage: CloudUsageContextStorage(),
                                                                  cloudAccountService: CloudAccountService())

        self.coreDataStack = CoreDataStack(isICloudSyncEnabled: self._userSettingStorage.readEnabledICloudSync(),
                                           logger: _logger)
        self._cloudStackLoader = CloudStackLoader(userSettingsStorage: self._userSettingStorage,
                                                  cloudAvailabilityService: self._cloudAvailabilityService,
                                                  cloudStack: self.coreDataStack)

        self.imageQueryContext = self.coreDataStack.newBackgroundContext(on: self.imageQueryQueue)
        self.commandContext = self.coreDataStack.newBackgroundContext(on: self.clipCommandQueue)
        // Note: clipStorage, imageStorage は、同一トランザクションとして書き込みを行うことが多いため、
        //       同一Contextとする
        self.clipStorage = ClipStorage(context: self.commandContext, logger: _logger)
        self.imageStorage = ImageStorage(context: self.commandContext)
        self._clipQueryService = ClipQueryCacheService(ClipQueryService(context: self.coreDataStack.viewContext))
        self._imageQueryService = ImageQueryService(context: self.imageQueryContext, logger: _logger)

        self._clipSearchHistoryService = Persistence.ClipSearchHistoryService()
        self._clipSearchSettingService = Persistence.ClipSearchSettingService()

        // MARK: Image Loader

        Self.sweepLegacyThumbnailCachesIfExists()

        let memoryCache = MemoryCache(config: .default)

        // Clip

        var clipCacheConfig = Pipeline.Configuration()
        let clipCacheDirectory = Self.resolveCacheDirectoryUrl(name: "clip-thumbnails")
        self._clipDiskCache = try DiskCache(path: clipCacheDirectory,
                                            config: .init(sizeLimit: 1024 * 1024 * 1024,
                                                          countLimit: Int.max,
                                                          dateLimit: 30))
        clipCacheConfig.diskCache = self._clipDiskCache
        clipCacheConfig.compressionRatio = 0.5
        clipCacheConfig.memoryCache = memoryCache
        self._clipThumbnailPipeline = .init(config: clipCacheConfig)

        // Album

        var albumCacheConfig = Pipeline.Configuration()
        albumCacheConfig.compressionRatio = 0.5
        let albumCacheDirectory = Self.resolveCacheDirectoryUrl(name: "album-thumbnails")
        _albumDiskCache = try DiskCache(path: albumCacheDirectory,
                                        config: .init(sizeLimit: 1024 * 1024 * 512,
                                                      countLimit: 1000,
                                                      dateLimit: 30))
        albumCacheConfig.diskCache = _albumDiskCache
        albumCacheConfig.memoryCache = memoryCache
        self._albumThumbnailPipeline = Pipeline(config: albumCacheConfig)

        // Clip Item

        var clipItemCacheConfig = Pipeline.Configuration()
        let clipItemCacheDirectory = Self.resolveCacheDirectoryUrl(name: "clip-item-thumbnails")
        _clipItemDiskCache = try DiskCache(path: clipItemCacheDirectory,
                                           config: .init(sizeLimit: 1024 * 1024 * 512,
                                                         countLimit: 100,
                                                         dateLimit: 30))
        clipItemCacheConfig.diskCache = _clipItemDiskCache
        clipItemCacheConfig.memoryCache = memoryCache
        self._clipItemThumbnailPipeline = Pipeline(config: clipItemCacheConfig)

        // Temporary

        var temporaryCacheConfig = Pipeline.Configuration()
        temporaryCacheConfig.diskCache = nil
        temporaryCacheConfig.memoryCache = memoryCache
        self._temporaryThumbnailPipeline = Pipeline(config: temporaryCacheConfig)

        // Preview

        var previewCacheConfig = Pipeline.Configuration()
        previewCacheConfig.dataCachingQueue.maxConcurrentOperationCount = 1
        previewCacheConfig.downsamplingQueue.maxConcurrentOperationCount = 1
        previewCacheConfig.imageDecompressingQueue.maxConcurrentOperationCount = 1
        previewCacheConfig.diskCache = nil
        previewCacheConfig.memoryCache = memoryCache
        self._previewPipeline = Pipeline(config: previewCacheConfig)

        self._previewPrefetcher = PreviewPrefetcher(pipeline: _clipThumbnailPipeline,
                                                    imageQueryService: _imageQueryService,
                                                    scale: UIScreen.main.scale)

        // MARK: Service

        self._clipCommandService = ClipCommandService(clipStorage: clipStorage,
                                                      referenceClipStorage: referenceClipStorage,
                                                      imageStorage: imageStorage,
                                                      diskCache: _clipDiskCache,
                                                      // Note: ImageStorage, ClipStorage は同一 Context である前提
                                                      commandQueue: clipStorage,
                                                      lock: commandLock,
                                                      logger: _logger)
        self._integrityValidationService = ClipReferencesIntegrityValidationService(clipStorage: clipStorage,
                                                                                    referenceClipStorage: referenceClipStorage,
                                                                                    // Note: ImageStorage, ClipStorage は同一 Context である前提
                                                                                    commandQueue: clipStorage,
                                                                                    lock: commandLock,
                                                                                    logger: _logger)
        self._temporariesPersistService = TemporariesPersistService(temporaryClipStorage: tmpClipStorage,
                                                                    temporaryImageStorage: tmpImageStorage,
                                                                    clipStorage: clipStorage,
                                                                    referenceClipStorage: referenceClipStorage,
                                                                    imageStorage: imageStorage,
                                                                    // Note: ImageStorage, ClipStorage は同一 Context である前提
                                                                    commandQueue: clipStorage,
                                                                    lock: commandLock,
                                                                    logger: _logger)

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

// MARK: - Dependencies

extension AppDependencyContainer: HasPasteboard {
    var pasteboard: Pasteboard { UIPasteboard.general }
}

extension AppDependencyContainer: HasClipCommandService {
    var clipCommandService: ClipCommandServiceProtocol { _clipCommandService }
}

extension AppDependencyContainer: HasClipQueryService {
    var clipQueryService: ClipQueryServiceProtocol { _clipQueryService }
}

extension AppDependencyContainer: HasClipSearchSettingService {
    var clipSearchSettingService: Domain.ClipSearchSettingService { _clipSearchSettingService }
}

extension AppDependencyContainer: HasClipSearchHistoryService {
    var clipSearchHistoryService: Domain.ClipSearchHistoryService { _clipSearchHistoryService }
}

extension AppDependencyContainer: HasUserSettingStorage {
    var userSettingStorage: UserSettingsStorageProtocol { _userSettingStorage }
}

extension AppDependencyContainer: HasImageQueryService {
    var imageQueryService: ImageQueryServiceProtocol { _imageQueryService }
}

extension AppDependencyContainer: HasTransitionLock {
    var transitionLock: TransitionLock { _transitionLock }
}

extension AppDependencyContainer: HasCloudAvailabilityService {
    var cloudAvailabilityService: CloudAvailabilityServiceProtocol { _cloudAvailabilityService }
}

extension AppDependencyContainer: HasModalNotificationCenter {
    var modalNotificationCenter: ModalNotificationCenter { ModalNotificationCenter.default }
}

extension AppDependencyContainer: HasTemporariesPersistService {
    var temporariesPersistService: TemporariesPersistServiceProtocol { _temporariesPersistService }
}

extension AppDependencyContainer: HasIntegrityValidationService {
    var integrityValidationService: ClipReferencesIntegrityValidationServiceProtocol { _integrityValidationService }
}

extension AppDependencyContainer: HasCloudStackLoader {
    var cloudStackLoader: CloudStackLoader { _cloudStackLoader }
}

extension AppDependencyContainer: HasTagCommandService {
    var tagCommandService: TagCommandServiceProtocol { _clipCommandService }
}

extension AppDependencyContainer: HasNop {}

extension AppDependencyContainer: HasLogger {
    var logger: Loggable { _logger }
}

extension AppDependencyContainer: HasClipStore {
    var clipStore: ClipStorable { _clipCommandService }
}

extension AppDependencyContainer: HasDiskCaches {
    var clipDiskCache: DiskCaching { _clipDiskCache }
    var albumDiskCache: DiskCaching { _albumDiskCache }
    var clipItemDiskCache: DiskCaching { _clipDiskCache }
}

extension AppDependencyContainer: HasImageLoaderSettings {
    var clipThumbnailPipeline: Pipeline { _clipThumbnailPipeline }
    var albumThumbnailPipeline: Pipeline { _albumThumbnailPipeline }
    var clipItemThumbnailPipeline: Pipeline { _clipItemThumbnailPipeline }
    var temporaryThumbnailPipeline: Pipeline { _temporaryThumbnailPipeline }
    var previewPipeline: Pipeline { _previewPipeline }
    var previewPrefetcher: PreviewPrefetchable { _previewPrefetcher }
}
