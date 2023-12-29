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

    let clipQueryService: ClipQueryCacheService<ClipQueryService>
    let imageQueryService: ImageQueryService

    // MARK: Core Data

    private let persistentStack: PersistentStack
    private let persistentStackLoader: PersistentStackLoader
    private let persistentStackMonitor: PersistentStackMonitor
    private var persistentStackLoading: Task<Void, Never>?
    private var persistentStackReloading: AnyCancellable?
    private var persistentStackEventsObserving: Set<AnyCancellable> = .init()
    private let cloudAvailabilityService: CloudAvailabilityService
    private var imageQueryContext: NSManagedObjectContext

    // MARK: Queue

    private let imageQueryQueue = DispatchQueue(label: "net.tasuwo.TBox.ImageQuery")

    // MARK: Bundle

    public let appBundle: Bundle

    public init(appBundle: Bundle) throws {
        self.appBundle = appBundle

        // MARK: CoreData

        var persistentStackConf = PersistentStack.Configuration(author: "app",
                                                                persistentContainerName: "Model",
                                                                managedObjectModelUrl: ManagedObjectModelUrl)
        persistentStackConf.persistentHistoryTokenSaveDirectory = NSPersistentContainer
            .defaultDirectoryURL()
            .appendingPathComponent("TBox", isDirectory: true)
        persistentStackConf.persistentHistoryTokenFileName = "token.data"
        persistentStackConf.shouldLoadPersistentContainerAtInitialized = true
        self.persistentStack = PersistentStack(configuration: persistentStackConf, isCloudKitEnabled: true) // TODO: 設定できるようにする
        self.viewContext = persistentStack.viewContext

        self.persistentStackLoader = PersistentStackLoader(persistentStack: persistentStack,
                                                           availabilityProvider: CloudKitSyncAvailabilityProvider())
        self.persistentStackMonitor = PersistentStackMonitor()
        self.cloudAvailabilityService = CloudAvailabilityService()

        self.imageQueryContext = self.persistentStack.newBackgroundContext(on: self.imageQueryQueue)
        self.clipQueryService = ClipQueryCacheService(ClipQueryService(context: self.persistentStack.viewContext))
        self.imageQueryService = ImageQueryService(context: self.imageQueryContext)

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

        // MARK: Service

        persistentStackReloading = persistentStack
            .reloaded
            .sink { [weak self] in
                guard let self else { return }
                self.viewContext = self.persistentStack.viewContext

                let newImageQueryContext = self.persistentStack.newBackgroundContext(on: self.imageQueryQueue)
                self.imageQueryContext = newImageQueryContext

                self.clipQueryService.internalService.context = self.persistentStack.viewContext
                self.imageQueryService.context = newImageQueryContext
            }

        // TODO: RemoteChangeMergeHandler

        persistentStackMonitor.startMonitoring()

        persistentStackLoading = self.persistentStackLoader.run()
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

class CloudKitSyncAvailabilityProvider: CloudKitSyncAvailabilityProviding {
    public var isCloudKitSyncAvailable: AsyncStream<Bool> {
        AsyncStream { continuation in
            // TODO: 設定できるようにする
            continuation.yield(true)
        }
    }
}

class CloudAvailabilityService {
    private let _availability: CurrentValueSubject<CloudAvailability?, Never> = .init(nil)
    private let task: Task<Void, Never>

    init() {
        self.task = Task { [_availability] in
            for await status in CKAccountStatus.ps.stream {
                _availability.send(CloudAvailability(status))
            }
        }
    }

    deinit {
        task.cancel()
    }
}

extension CloudAvailabilityService: CloudAvailabilityServiceProtocol {
    var availability: AnyPublisher<CloudAvailability?, Never> { _availability.eraseToAnyPublisher() }
}

private extension CloudAvailability {
    init?(_ status: CKAccountStatus?) {
        guard let status else { return nil }
        switch status {
        case .available:
            self = .available

        default:
            self = .unavailable
        }
    }
}
