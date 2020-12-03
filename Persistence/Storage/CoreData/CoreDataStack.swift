//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import CoreData
import Domain

public protocol CoreDataStackDependency: AnyObject {
    func coreDataStack(_ coreDataStack: CoreDataStack, replaced container: NSPersistentCloudKitContainer)
}

public class CoreDataStack {
    // MARK: - Properties

    // MARK: Internals

    public static let transactionAuthor = "app"

    public var viewContext: NSManagedObjectContext {
        return self.persistentContainer.viewContext
    }

    public var newBackgroundContext: NSManagedObjectContext {
        return self.persistentContainer.newBackgroundContext()
    }

    public weak var dependency: CoreDataStackDependency?

    // MARK: Privates

    private var persistentContainer: NSPersistentCloudKitContainer
    private var isICloudSyncEnabled: Bool
    private let notificationCenter: NotificationCenter
    private let logger: TBoxLoggable

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
                logger: TBoxLoggable = RootLogger.shared)
    {
        self.persistentContainer = Self.makeContainer(isICloudSyncEnabled: isICloudSyncEnabled)
        self.isICloudSyncEnabled = isICloudSyncEnabled
        self.notificationCenter = notificationCenter
        self.logger = logger

        guard let tokenData = try? Data(contentsOf: self.tokenFile) else { return }
        do {
            self.lastHistoryToken = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSPersistentHistoryToken.self,
                                                                           from: tokenData)
        } catch {
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to unarchive NSPersistentHistoryToken. Error = \(error)
            """))
        }

        self.notificationCenter.addObserver(self,
                                            selector: #selector(self.storeRemoteChange(_:)),
                                            name: .NSPersistentStoreRemoteChange,
                                            object: self.persistentContainer)
    }

    // MARK: - Methods

    private static func makeContainer(isICloudSyncEnabled: Bool) -> NSPersistentCloudKitContainer {
        let container = PersistentContainerLoader.load()

        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Failed to retrieve a persistent store description.")
        }
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        if !isICloudSyncEnabled {
            description.cloudKitContainerOptions = nil
        }

        container.loadPersistentStores(completionHandler: { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true

        return container
    }

    private func reloadStack(isICloudSyncEnabled: Bool) {
        self.historyQueue.addOperation {
            self.notificationCenter.removeObserver(self,
                                                   name: .NSPersistentStoreRemoteChange,
                                                   object: self.persistentContainer)

            let newPersistentContainer = Self.makeContainer(isICloudSyncEnabled: isICloudSyncEnabled)

            self.notificationCenter.addObserver(self,
                                                selector: #selector(self.storeRemoteChange(_:)),
                                                name: .NSPersistentStoreRemoteChange,
                                                object: newPersistentContainer)

            self.persistentContainer = newPersistentContainer
            self.isICloudSyncEnabled = isICloudSyncEnabled

            self.dependency?.coreDataStack(self, replaced: newPersistentContainer)
        }
    }

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

            self.notificationCenter.post(name: .didFindRelevantTransactions,
                                         object: self,
                                         userInfo: ["transactions": transactions])

            self.lastHistoryToken = transactions.last?.token
        }
    }
}

extension CoreDataStack: CloudStack {
    // MARK: - CloudStack

    public var isCloudSyncEnabled: Bool {
        return self.isICloudSyncEnabled
    }

    public func reload(isCloudSyncEnabled: Bool) {
        self.reloadStack(isICloudSyncEnabled: isCloudSyncEnabled)
    }
}
