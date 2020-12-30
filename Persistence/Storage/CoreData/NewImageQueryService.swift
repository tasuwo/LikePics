//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import CoreData
import Domain
import Smoothie

public class NewImageQueryService {
    public var context: NSManagedObjectContext {
        willSet {
            self.context.perform { [weak self] in
                if self?.context.hasChanges == true {
                    self?.context.rollback()
                }
            }
        }
    }

    // MARK: - Lifecycle

    public init(context: NSManagedObjectContext) {
        self.context = context
    }
}

extension NewImageQueryService: NewImageQueryServiceProtocol {
    public func read(having id: UUID) throws -> Data? {
        return try self.context.sync { [weak self] in
            let request: NSFetchRequest<Image> = Image.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            return try self?.context.fetch(request).first?.data
        }
    }
}

extension NewImageQueryService: OriginalImageLoader {
    // MARK: - OriginalImageLoader

    public func loadData(with request: OriginalImageRequest) -> Data? {
        guard let request = request as? NewImageDataLoadRequest else {
            RootLogger.shared.write(ConsoleLog(level: .error, message: "不正なリクエスト"))
            return nil
        }
        return try? self.read(having: request.imageId)
    }
}
