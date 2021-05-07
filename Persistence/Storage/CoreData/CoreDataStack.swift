//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import CoreData
import Domain

public protocol CoreDataStackObserver: AnyObject {
    func coreDataStack(_ coreDataStack: CoreDataStack, reloaded container: NSPersistentCloudKitContainer)
}

public class CoreDataStack {
    // MARK: - Properties

    // MARK: Internals

    public var viewContext: NSManagedObjectContext {
        return self.persistentContainer.viewContext
    }

    public weak var coreDataStackObserver: CoreDataStackObserver?
    public weak var cloudStackObserver: CloudStackObserver?

    // MARK: Privates

    private static let transactionAuthor = "app"

    private var persistentContainer: NSPersistentCloudKitContainer
    private var isICloudSyncEnabled: Bool
    private let notificationCenter: NotificationCenter
    private let logger: Loggable

    private var lastHistoryToken: NSPersistentHistoryToken? {
        didSet {
            guard let token = lastHistoryToken,
                  let data = try? NSKeyedArchiver.archivedData(withRootObject: token,
                                                               requiringSecureCoding: true)
            else {
                return
            }

            do {
                try data.write(to: tokenFile)
            } catch {
                self.logger.write(ConsoleLog(level: .error, message: """
                Failed to write token data. Error = \(error)
                """))
            }
        }
    }

    private lazy var tokenFile: URL = {
        let url = NSPersistentContainer
            .defaultDirectoryURL()
            .appendingPathComponent("TBox", isDirectory: true)

        if !FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.createDirectory(at: url,
                                                        withIntermediateDirectories: true,
                                                        attributes: nil)
            } catch {
                self.logger.write(ConsoleLog(level: .error, message: """
                Failed to create persistent container URL. Error = \(error)
                """))
            }
        }

        return url.appendingPathComponent("token.data", isDirectory: false)
    }()

    private lazy var historyQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    // MARK: - Lifecycle

    public init(isICloudSyncEnabled: Bool,
                notificationCenter: NotificationCenter = .default,
                logger: Loggable = RootLogger.shared)
    {
        self.persistentContainer = Self.makeContainer(isICloudSyncEnabled: isICloudSyncEnabled)
        self.isICloudSyncEnabled = isICloudSyncEnabled
        self.notificationCenter = notificationCenter
        self.logger = logger

        if let tokenData = try? Data(contentsOf: self.tokenFile) {
            do {
                self.lastHistoryToken = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSPersistentHistoryToken.self, from: tokenData)
            } catch {
                self.logger.write(ConsoleLog(level: .error, message: """
                Failed to unarchive NSPersistentHistoryToken. Error = \(error)
                """))
            }
        }

        self.notificationCenter.addObserver(self,
                                            selector: #selector(self.storeRemoteChange(_:)),
                                            name: .NSPersistentStoreRemoteChange,
                                            object: self.persistentContainer.persistentStoreCoordinator)
    }

    // MARK: - Methods

    public func newBackgroundContext(on queue: DispatchQueue) -> NSManagedObjectContext {
        return queue.sync {
            let context = self.persistentContainer.newBackgroundContext()
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            context.transactionAuthor = CoreDataStack.transactionAuthor
            return context
        }
    }
}

// MARK: - Load/Reload Stack

extension CoreDataStack {
    private static func makeContainer(isICloudSyncEnabled: Bool) -> NSPersistentCloudKitContainer {
        let container = PersistentContainerLoader.load()

        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Failed to retrieve a persistent store description.")
        }
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true

        if !isICloudSyncEnabled {
            description.cloudKitContainerOptions = nil
        }

        container.loadPersistentStores(completionHandler: { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true

        return container
    }

    private func reloadStack(isICloudSyncEnabled: Bool) {
        self.historyQueue.addOperation {
            self.notificationCenter.removeObserver(self,
                                                   name: .NSPersistentStoreRemoteChange,
                                                   object: self.persistentContainer.persistentStoreCoordinator)

            let newPersistentContainer = Self.makeContainer(isICloudSyncEnabled: isICloudSyncEnabled)

            self.notificationCenter.addObserver(self,
                                                selector: #selector(self.storeRemoteChange(_:)),
                                                name: .NSPersistentStoreRemoteChange,
                                                object: newPersistentContainer.persistentStoreCoordinator)

            self.persistentContainer = newPersistentContainer
            self.isICloudSyncEnabled = isICloudSyncEnabled

            self.coreDataStackObserver?.coreDataStack(self, reloaded: newPersistentContainer)
        }
    }
}

// MARK: - Persistent History

extension CoreDataStack {
    @objc
    private func storeRemoteChange(_ notification: Notification) {
        self.historyQueue.addOperation {
            self.processPersistentHistory()
        }
    }

    private func processPersistentHistory() {
        let context = self.persistentContainer.newBackgroundContext()
        context.performAndWait {
            // swiftlint:disable:next force_unwrapping
            let fetchRequest = NSPersistentHistoryTransaction.fetchRequest!
            fetchRequest.predicate = NSPredicate(format: "author != %@", Self.transactionAuthor)

            let request = NSPersistentHistoryChangeRequest.fetchHistory(after: self.lastHistoryToken)
            request.fetchRequest = fetchRequest

            let result = (try? context.execute(request)) as? NSPersistentHistoryResult
            guard let transactions = result?.result as? [NSPersistentHistoryTransaction], !transactions.isEmpty else {
                return
            }

            var insertedTagObjectIDs = [NSManagedObjectID]()
            var updatedTagObjectIDs = [NSManagedObjectID]()
            var deletedTagObjectIDs = [NSManagedObjectID]()
            for transaction in transactions where transaction.changes != nil {
                // swiftlint:disable:next force_unwrapping
                for change in transaction.changes! where change.isTagChange {
                    switch change.changeType {
                    case .insert:
                        insertedTagObjectIDs.append(change.changedObjectID)

                    case .update:
                        updatedTagObjectIDs.append(change.changedObjectID)

                    case .delete:
                        deletedTagObjectIDs.append(change.changedObjectID)

                    @unknown default:
                        break
                    }
                }
            }

            self.cloudStackObserver?.didRemoteChangedTags(inserted: insertedTagObjectIDs,
                                                          updated: updatedTagObjectIDs,
                                                          deleted: deletedTagObjectIDs)

            self.lastHistoryToken = transactions.last?.token
        }
    }
}

private extension NSPersistentHistoryChange {
    var isTagChange: Bool {
        return self.changedObjectID.entity.name == Tag.entity().name
    }

    var isInsertOrUpdate: Bool {
        return self.changeType == .insert || self.changeType == .update
    }
}

// MARK: - CloudStack

extension CoreDataStack: CloudStack {
    public var isCloudSyncEnabled: Bool {
        return self.isICloudSyncEnabled
    }

    public func reload(isCloudSyncEnabled: Bool) {
        self.reloadStack(isICloudSyncEnabled: isCloudSyncEnabled)
    }

    public func set(_ observer: CloudStackObserver) {
        self.cloudStackObserver = observer
    }
}
