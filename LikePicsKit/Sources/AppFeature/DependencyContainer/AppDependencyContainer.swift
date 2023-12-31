//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import ClipCreationFeature
import Combine
import Common
import CompositeKit
import CoreData
import Domain
import Environment
import LikePicsUIKit
import Persistence
import PersistentStack
import Smoothie
import UIKit

// swiftlint:disable identifier_name
// swiftlint:disable function_body_length

public typealias AppDependencyContaining = HasAlbumCommandService
    & HasAppBundle
    & HasClipCommandService
    & HasClipPreviewPlayConfigurationStorage
    & HasClipQueryService
    & HasClipSearchHistoryService
    & HasClipSearchSettingService
    & HasClipStore
    & HasCloudAvailabilityService
    & HasDiskCaches
    & HasImageLoaderSettings
    & HasImageQueryService
    & HasIntegrityValidationService
    & HasListingAlbumTitleQueryService
    & HasModalNotificationCenter
    & HasNop
    & HasPasteboard
    & HasPreviewPrefetcher
    & HasTagCommandService
    & HasTagQueryService
    & HasTemporariesPersistService
    & HasTransitionLock
    & HasUserSettingStorage

public class AppDependencyContainer {
    final class CloudSyncAvailabilityService: CloudAvailabilityServiceProtocol {
        let cloudSyncAvailability = CurrentValueSubject<Domain.CloudAvailability?, Never>(nil)
        public var availability: AnyPublisher<Domain.CloudAvailability?, Never> { cloudSyncAvailability.eraseToAnyPublisher() }
    }

    // MARK: - Properties

    // MARK: Image Loader

    private let _clipDiskCache: DiskCache
    private let _albumDiskCache: DiskCache
    private let _clipItemDiskCache: DiskCache
    private let _clipThumbnailProcessingQueue: ImageProcessingQueue
    private let _albumThumbnailProcessingQueue: ImageProcessingQueue
    private let _clipItemThumbnailProcessingQueue: ImageProcessingQueue
    private let _temporaryThumbnailProcessingQueue: ImageProcessingQueue
    private let _previewProcessingQueue: ImageProcessingQueue
    private let _previewPrefetcher: PreviewPrefetcher

    // MARK: Storage

    private let clipStorage: ClipStorage
    private let tmpClipStorage: TemporaryClipStorageProtocol
    private let referenceClipStorage: ReferenceClipStorageProtocol
    private let imageStorage: ImageStorage
    private let tmpImageStorage: TemporaryImageStorageProtocol
    private let _userSettingStorage: UserSettingsStorageProtocol
    private let _clipPreviewPlayConfigurationStorage: ClipPreviewPlayConfigurationStorageProtocol

    // MARK: Service

    private let _clipCommandService: ClipCommandService
    private let _clipQueryService: ClipQueryCacheService<ClipQueryService>
    private let _clipSearchHistoryService: Persistence.ClipSearchHistoryService
    private let _clipSearchSettingService: Persistence.ClipSearchSettingService
    private let _imageQueryService: ImageQueryService
    private let _integrityValidationService: ClipReferencesIntegrityValidationService
    private let _temporariesPersistService: TemporariesPersistService

    // MARK: Core Data

    private let persistentStack: PersistentStack
    private let persistentStackLoader: PersistentStackLoader
    private let persistentStackMonitor: PersistentStackMonitor
    private var persistentStackLoading: Task<Void, Never>?
    private var persistentStackReloading: AnyCancellable?
    private var persistentStackEventsObserving: Set<AnyCancellable> = .init()
    private let _cloudAvailabilityService = CloudSyncAvailabilityService()
    private var imageQueryContext: NSManagedObjectContext
    private var commandContext: NSManagedObjectContext

    private var cloudSyncAvailabilityTask: Task<Void, Never>?

    // MARK: Queue

    private let commandLock = NSRecursiveLock()
    /// - Attention: 排他制御には`commandLock`を利用する
    private let clipCommandQueue = DispatchQueue(label: "net.tasuwo.TBox.ClipCommand")
    /// - Attention: 排他制御には`commandLock`を利用する
    private let imageQueryQueue = DispatchQueue(label: "net.tasuwo.TBox.ImageQuery")

    // MARK: Lock

    private let _transitionLock = TransitionLock()

    // MARK: Bundle

    public let appBundle: Bundle

    // MARK: - Lifecycle

    public init(appBundle: Bundle) throws {
        self.appBundle = appBundle

        // MARK: Storage

        self.tmpImageStorage = try TemporaryImageStorage(configuration: .resolve(for: appBundle, kind: .group))
        self.tmpClipStorage = try TemporaryClipStorage(config: .resolve(for: appBundle, kind: .group))
        self.referenceClipStorage = try ReferenceClipStorage(config: .resolve(for: appBundle))

        // MARK: CoreData

        let userSettingsStorage = UserSettingsStorage(appBundle: appBundle)
        self._userSettingStorage = userSettingsStorage
        self._clipPreviewPlayConfigurationStorage = ClipPreviewPlayConfigurationStorage()

        var persistentStackConf = PersistentStack.Configuration(author: "app",
                                                                persistentContainerName: "Model",
                                                                managedObjectModelUrl: ManagedObjectModelUrl)
        persistentStackConf.persistentHistoryTokenSaveDirectory = NSPersistentContainer
            .defaultDirectoryURL()
            .appendingPathComponent("TBox", isDirectory: true)
        persistentStackConf.persistentHistoryTokenFileName = "token.data"
        persistentStackConf.shouldLoadPersistentContainerAtInitialized = true
        self.persistentStack = PersistentStack(configuration: persistentStackConf,
                                               isCloudKitSyncEnabled: self._userSettingStorage.readEnabledICloudSync())
        self.persistentStackLoader = PersistentStackLoader(persistentStack: persistentStack,
                                                           settingStorage: userSettingsStorage)
        self.persistentStackMonitor = PersistentStackMonitor()

        self.imageQueryContext = self.persistentStack.newBackgroundContext(on: self.imageQueryQueue)
        self.commandContext = self.persistentStack.newBackgroundContext(on: self.clipCommandQueue)
        // Note: clipStorage, imageStorage は、同一トランザクションとして書き込みを行うことが多いため、
        //       同一Contextとする
        self.clipStorage = ClipStorage(context: self.commandContext)
        self.imageStorage = ImageStorage(context: self.commandContext)
        self._clipQueryService = ClipQueryCacheService(ClipQueryService(context: self.persistentStack.viewContext))
        self._imageQueryService = ImageQueryService(context: self.imageQueryContext)

        self._clipSearchHistoryService = Persistence.ClipSearchHistoryService()
        self._clipSearchSettingService = Persistence.ClipSearchSettingService()

        // MARK: Image Loader

        Self.sweepLegacyThumbnailCachesIfExists(appBundle: appBundle)

        let memoryCache = MemoryCache(config: .default)

        // Clip

        var clipCacheConfig = ImageProcessingQueue.Configuration()
        let clipCacheDirectory = Self.resolveCacheDirectoryUrl(name: "clip-thumbnails", appBundle: appBundle)
        self._clipDiskCache = try DiskCache(path: clipCacheDirectory,
                                            config: .init(sizeLimit: 1024 * 1024 * 1024,
                                                          countLimit: Int.max,
                                                          dateLimit: 30))
        clipCacheConfig.diskCache = self._clipDiskCache
        clipCacheConfig.compressionRatio = 0.5
        clipCacheConfig.memoryCache = memoryCache
        self._clipThumbnailProcessingQueue = .init(config: clipCacheConfig)

        // Album

        var albumCacheConfig = ImageProcessingQueue.Configuration()
        albumCacheConfig.compressionRatio = 0.5
        let albumCacheDirectory = Self.resolveCacheDirectoryUrl(name: "album-thumbnails", appBundle: appBundle)
        _albumDiskCache = try DiskCache(path: albumCacheDirectory,
                                        config: .init(sizeLimit: 1024 * 1024 * 512,
                                                      countLimit: 1000,
                                                      dateLimit: 30))
        albumCacheConfig.diskCache = _albumDiskCache
        albumCacheConfig.memoryCache = memoryCache
        self._albumThumbnailProcessingQueue = ImageProcessingQueue(config: albumCacheConfig)

        // Clip Item

        var clipItemCacheConfig = ImageProcessingQueue.Configuration()
        let clipItemCacheDirectory = Self.resolveCacheDirectoryUrl(name: "clip-item-thumbnails", appBundle: appBundle)
        _clipItemDiskCache = try DiskCache(path: clipItemCacheDirectory,
                                           config: .init(sizeLimit: 1024 * 1024 * 512,
                                                         countLimit: 100,
                                                         dateLimit: 30))
        clipItemCacheConfig.diskCache = _clipItemDiskCache
        clipItemCacheConfig.memoryCache = memoryCache
        self._clipItemThumbnailProcessingQueue = ImageProcessingQueue(config: clipItemCacheConfig)

        // Temporary

        var temporaryCacheConfig = ImageProcessingQueue.Configuration()
        temporaryCacheConfig.diskCache = nil
        temporaryCacheConfig.memoryCache = memoryCache
        self._temporaryThumbnailProcessingQueue = ImageProcessingQueue(config: temporaryCacheConfig)

        // Preview

        var previewCacheConfig = ImageProcessingQueue.Configuration()
        previewCacheConfig.dataCachingQueue.maxConcurrentOperationCount = 1
        previewCacheConfig.downsamplingQueue.maxConcurrentOperationCount = 1
        previewCacheConfig.imageDecompressingQueue.maxConcurrentOperationCount = 1
        previewCacheConfig.diskCache = nil
        previewCacheConfig.memoryCache = memoryCache
        self._previewProcessingQueue = ImageProcessingQueue(config: previewCacheConfig)

        self._previewPrefetcher = PreviewPrefetcher(processingQueue: _previewProcessingQueue,
                                                    imageQueryService: _imageQueryService)

        // MARK: Service

        self._clipCommandService = ClipCommandService(clipStorage: clipStorage,
                                                      referenceClipStorage: referenceClipStorage,
                                                      imageStorage: imageStorage,
                                                      diskCache: _clipDiskCache,
                                                      // Note: ImageStorage, ClipStorage は同一 Context である前提
                                                      commandQueue: clipStorage,
                                                      lock: commandLock)
        self._integrityValidationService = ClipReferencesIntegrityValidationService(clipStorage: clipStorage,
                                                                                    referenceClipStorage: referenceClipStorage,
                                                                                    // Note: ImageStorage, ClipStorage は同一 Context である前提
                                                                                    commandQueue: clipStorage,
                                                                                    lock: commandLock)
        self._temporariesPersistService = TemporariesPersistService(temporaryClipStorage: tmpClipStorage,
                                                                    temporaryImageStorage: tmpImageStorage,
                                                                    clipStorage: clipStorage,
                                                                    referenceClipStorage: referenceClipStorage,
                                                                    imageStorage: imageStorage,
                                                                    // Note: ImageStorage, ClipStorage は同一 Context である前提
                                                                    commandQueue: clipStorage,
                                                                    lock: commandLock)

        persistentStackReloading = persistentStack
            .reloaded
            .sink { [weak self] in
                guard let self else { return }
                let newImageQueryContext = self.persistentStack.newBackgroundContext(on: self.imageQueryQueue)
                let newCommandContext = self.persistentStack.newBackgroundContext(on: self.clipCommandQueue)

                self.imageQueryContext = newImageQueryContext
                self.commandContext = newCommandContext

                self.clipCommandQueue.sync {
                    self.clipStorage.context = newCommandContext
                    self.imageStorage.context = newCommandContext
                }

                self._clipQueryService.internalService.context = self.persistentStack.viewContext
                self._imageQueryService.context = newImageQueryContext
            }

        persistentStack.registerRemoteChangeMergeHandler { [weak self] persistentStack, transactions in
            guard let self else { return }
            RemoteChangeMergeHandler(persistentStack, transactions, self._integrityValidationService)
        }

        persistentStackMonitor.startMonitoring()

        persistentStackLoading = self.persistentStackLoader.run()

        cloudSyncAvailabilityTask = Task { [_cloudAvailabilityService, persistentStackLoader] in
            for await isAvailable in persistentStackLoader.isCloudKitSyncAvailables() {
                _cloudAvailabilityService.cloudSyncAvailability.send(isAvailable.flatMap({ $0 ? .available : .unavailable }))
            }
        }
    }

    private static func sweepLegacyThumbnailCachesIfExists(appBundle: Bundle) {
        guard let bundleIdentifier = appBundle.bundleIdentifier else {
            fatalError("Failed to resolve bundle identifier")
        }

        let targetUrl: URL = {
            let directoryName = "thumbnails"
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

    deinit {
        cloudSyncAvailabilityTask?.cancel()
    }
}

extension ClipCommandService: ClipStorable {}

// MARK: - Dependencies

extension AppDependencyContainer: HasPasteboard {
    public var pasteboard: Pasteboard { UIPasteboard.general }
}

extension AppDependencyContainer: HasClipCommandService {
    public var clipCommandService: ClipCommandServiceProtocol { _clipCommandService }
}

extension AppDependencyContainer: HasClipQueryService {
    public var clipQueryService: ClipQueryServiceProtocol { _clipQueryService }
}

extension AppDependencyContainer: HasClipSearchSettingService {
    public var clipSearchSettingService: Domain.ClipSearchSettingService { _clipSearchSettingService }
}

extension AppDependencyContainer: HasClipSearchHistoryService {
    public var clipSearchHistoryService: Domain.ClipSearchHistoryService { _clipSearchHistoryService }
}

extension AppDependencyContainer: HasUserSettingStorage {
    public var userSettingStorage: UserSettingsStorageProtocol { _userSettingStorage }
}

extension AppDependencyContainer: HasImageQueryService {
    public var imageQueryService: ImageQueryServiceProtocol { _imageQueryService }
}

extension AppDependencyContainer: HasTransitionLock {
    public var transitionLock: TransitionLock { _transitionLock }
}

extension AppDependencyContainer: HasCloudAvailabilityService {
    public var cloudAvailabilityService: CloudAvailabilityServiceProtocol { _cloudAvailabilityService }
}

extension AppDependencyContainer: HasModalNotificationCenter {
    public var modalNotificationCenter: ModalNotificationCenter { ModalNotificationCenter.default }
}

extension AppDependencyContainer: HasTemporariesPersistService {
    public var temporariesPersistService: TemporariesPersistServiceProtocol { _temporariesPersistService }
}

extension AppDependencyContainer: HasIntegrityValidationService {
    public var integrityValidationService: ClipReferencesIntegrityValidationServiceProtocol { _integrityValidationService }
}

extension AppDependencyContainer: HasTagCommandService {
    public var tagCommandService: TagCommandServiceProtocol { _clipCommandService }
}

extension AppDependencyContainer: HasTagQueryService {
    public var tagQueryService: TagQueryServiceProtocol { _clipQueryService }
}

extension AppDependencyContainer: HasAlbumCommandService {
    public var albumCommandService: AlbumCommandServiceProtocol { _clipCommandService }
}

extension AppDependencyContainer: HasListingAlbumTitleQueryService {
    public var listingAlbumTitleQueryService: ListingAlbumTitleQueryServiceProtocol { _clipQueryService }
}

extension AppDependencyContainer: HasNop {}

extension AppDependencyContainer: HasClipStore {
    public var clipStore: ClipStorable { _clipCommandService }
}

extension AppDependencyContainer: HasDiskCaches {
    public var clipDiskCache: DiskCaching { _clipDiskCache }
    public var albumDiskCache: DiskCaching { _albumDiskCache }
    public var clipItemDiskCache: DiskCaching { _clipDiskCache }
}

extension AppDependencyContainer: HasImageLoaderSettings {
    public var clipThumbnailProcessingQueue: ImageProcessingQueue { _clipThumbnailProcessingQueue }
    public var albumThumbnailProcessingQueue: ImageProcessingQueue { _albumThumbnailProcessingQueue }
    public var clipItemThumbnailProcessingQueue: ImageProcessingQueue { _clipItemThumbnailProcessingQueue }
    public var temporaryThumbnailProcessingQueue: ImageProcessingQueue { _temporaryThumbnailProcessingQueue }
    public var previewProcessingQueue: ImageProcessingQueue { _previewProcessingQueue }
    public var previewPrefetcher: PreviewPrefetchable { _previewPrefetcher }
}

extension AppDependencyContainer: HasAppBundle {}

extension AppDependencyContainer: HasClipPreviewPlayConfigurationStorage {
    public var clipPreviewPlayConfigurationStorage: ClipPreviewPlayConfigurationStorageProtocol { _clipPreviewPlayConfigurationStorage }
}

extension AppDependencyContainer: HasPreviewPrefetcher {}

extension UserSettingsStorage: CloudKitSyncSettingStorage {
    public var isCloudKitSyncEnabled: AsyncStream<Bool> {
        AsyncStream { continuation in
            let cancellables = self.enabledICloudSync
                .sink { continuation.yield($0) }

            continuation.onTermination = { @Sendable _ in
                cancellables.cancel()
            }
        }
    }
}
