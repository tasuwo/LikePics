//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import CoreData
import Domain
import Persistence
import TBoxCore
import TBoxUIKit
import UIKit

// swiftlint:disable implicitly_unwrapped_optional

class DependencyContainer {
    // MARK: - Properties

    // MARK: Storage

    var clipStorage: NewClipStorage!
    let tmpClipStorage: ClipStorageProtocol
    let referenceClipStorage: ReferenceClipStorageProtocol
    var imageStorage: NewImageStorage!
    let tmpImageStorage: ImageStorageProtocol
    var thumbnailStorage: ThumbnailStorageProtocol!
    let userSettingsStorage: UserSettingsStorageProtocol
    let cloudUsageContextStorage: CloudUsageContextStorageProtocol

    // MARK: Service

    var clipCommandService: (ClipCommandServiceProtocol & ClipStorable)!
    var clipQueryService: ClipQueryService!
    var imageQueryService: NewImageQueryService!
    private(set) var integrityValidationService: ClipReferencesIntegrityValidationServiceProtocol!
    private(set) var persistService: TemporaryClipsPersistServiceProtocol!

    // MARK: Core Data

    let coreDataStack: CoreDataStack
    var imageQueryContext: NSManagedObjectContext!
    var commandContext: NSManagedObjectContext!
    let cloudAvailabilityObserver: CloudAvailabilityObserver

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
        self.coreDataStack.dependency = self

        let newImageQueryContext = self.newImageQueryContext()
        let newCommandContext = self.newCommandContext()

        self.imageQueryContext = newImageQueryContext
        self.commandContext = newCommandContext
        self.clipStorage = NewClipStorage(context: newCommandContext)
        self.imageStorage = NewImageStorage(context: newCommandContext)
        self.clipQueryService = ClipQueryService(context: self.coreDataStack.viewContext)
        self.imageQueryService = NewImageQueryService(context: newImageQueryContext)
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
    }

    // MARK: - Methods

    func makeCloudStackLoader() -> CloudStackLoader {
        return CloudStackLoader(userSettingsStorage: self.userSettingsStorage,
                                cloudAvailabilityStore: self.cloudAvailabilityObserver,
                                cloudStack: self.coreDataStack)
    }

    private func newImageQueryContext() -> NSManagedObjectContext {
        return self.imageQueryQueue.sync {
            let context = self.coreDataStack.newBackgroundContext
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            context.transactionAuthor = CoreDataStack.transactionAuthor
            return context
        }
    }

    private func newCommandContext() -> NSManagedObjectContext {
        return self.clipCommandQueue.sync {
            let context = self.coreDataStack.newBackgroundContext
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            context.transactionAuthor = CoreDataStack.transactionAuthor
            return context
        }
    }
}

extension DependencyContainer: CoreDataStackDependency {
    // MARK: - CoreDataStackDependency

    func coreDataStack(_ coreDataStack: CoreDataStack, replaced container: NSPersistentCloudKitContainer) {
        let newImageQueryContext = self.newImageQueryContext()
        let newCommandContext = self.newCommandContext()

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
