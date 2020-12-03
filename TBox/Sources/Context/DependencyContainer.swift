//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import CoreData
import Domain
import Persistence
import TBoxCore
import UIKit

class DependencyContainer {
    // MARK: - Properties

    // MARK: Storage

    let clipStorage: NewClipStorage
    let tmpClipStorage: ClipStorageProtocol
    let referenceClipStorage: ReferenceClipStorageProtocol
    let imageStorage: NewImageStorage
    let tmpImageStorage: ImageStorageProtocol
    let thumbnailStorage: ThumbnailStorageProtocol
    let userSettingsStorage: UserSettingsStorageProtocol
    let cloudUsageContextStorage: CloudUsageContextStorageProtocol

    // MARK: Service

    let clipCommandService: ClipCommandService
    let clipQueryService: ClipQueryService
    let imageQueryService: NewImageQueryService
    let integrityValidationService: ClipReferencesIntegrityValidationService
    let persistService: TemporaryClipsPersistServiceProtocol
    let cloudChangeDetecter: CloudKitChangeDetecter

    // MARK: Core Data

    let coreDataStack: CoreDataStack
    let cloudAvailabilityObserver: CloudAvailabilityObserver
    var imageQueryContext: NSManagedObjectContext
    var commandContext: NSManagedObjectContext

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
        self.thumbnailStorage = try ThumbnailStorage(queryService: self.imageQueryService, bundle: Bundle.main)

        self.clipCommandService = ClipCommandService(clipStorage: self.clipStorage,
                                                     referenceClipStorage: referenceClipStorage,
                                                     imageStorage: self.imageStorage,
                                                     thumbnailStorage: self.thumbnailStorage,
                                                     logger: self.logger,
                                                     queue: self.clipCommandQueue)
        self.integrityValidationService = ClipReferencesIntegrityValidationService(clipStorage: self.clipStorage,
                                                                                   referenceClipStorage: self.referenceClipStorage,
                                                                                   logger: self.logger,
                                                                                   queue: self.clipCommandQueue)
        self.persistService = TemporaryClipsPersistService(temporaryClipStorage: self.tmpClipStorage,
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
