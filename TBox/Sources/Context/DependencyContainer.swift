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

    let thumbnailLoader: Smoothie.ThumbnailLoader

    // MARK: Storage

    let clipStorage: NewClipStorage
    let tmpClipStorage: ClipStorageProtocol
    let referenceClipStorage: ReferenceClipStorageProtocol
    let imageStorage: NewImageStorage
    let tmpImageStorage: ImageStorageProtocol
    let userSettingsStorage: UserSettingsStorageProtocol
    let cloudUsageContextStorage: CloudUsageContextStorageProtocol

    // MARK: Service

    let clipCommandService: ClipCommandService
    let clipQueryService: ClipQueryService
    let imageQueryService: NewImageQueryService
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
        self.tmpImageStorage = try ImageStorage(configuration: .resolve(for: Bundle.main, kind: .group))
        self.logger = RootLogger.shared
        self.tmpClipStorage = try ClipStorage(config: .resolve(for: Bundle.main, kind: .group), logger: self.logger)
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
        self.clipStorage = NewClipStorage(context: self.commandContext)
        self.imageStorage = NewImageStorage(context: self.commandContext)
        self.clipQueryService = ClipQueryService(context: self.coreDataStack.viewContext)
        self.imageQueryService = NewImageQueryService(context: self.imageQueryContext)

        var config = ThumbnailLoadPipeline.Configuration(dataLoader: self.imageQueryService)
        let cacheDirectoryUrl = Self.resolveCacheDirectoryUrl()
        config.diskCache = try DiskCache(path: cacheDirectoryUrl)
        let pipeline = ThumbnailLoadPipeline(config: config)
        self.thumbnailLoader = Smoothie.ThumbnailLoader(pipeline: pipeline)

        self.clipCommandService = ClipCommandService(clipStorage: self.clipStorage,
                                                     referenceClipStorage: referenceClipStorage,
                                                     imageStorage: self.imageStorage,
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

    private static func resolveCacheDirectoryUrl() -> URL {
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

        return targetUrl
    }

    func makeCloudStackLoader() -> CloudStackLoader {
        return CloudStackLoader(userSettingsStorage: self.userSettingsStorage,
                                cloudAvailabilityStore: self.cloudAvailabilityObserver,
                                cloudStack: self.coreDataStack)
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
