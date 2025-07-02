//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//
//

import CoreData
import Foundation

public class Clip: NSManagedObject {
}

public enum ClipUpdateError: Error {
    case notFound
}

extension NSManagedObjectContext {
    public func updateClip(having id: UUID, isHidden: Bool) throws {
        let request: NSFetchRequest<Clip> = Clip.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)

        guard let clip = try fetch(request).first else {
            throw ClipUpdateError.notFound
        }

        clip.isHidden = isHidden

        try save()
    }

    public func deleteClip(having id: UUID) throws {
        let request: NSFetchRequest<Clip> = Clip.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)

        guard let clip = try fetch(request).first else {
            throw ClipUpdateError.notFound
        }

        delete(clip)

        try save()
    }
}
