//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//
//

import CoreData
import Foundation

public enum TagError: Error {
    case notFound
    case duplicate
}

public class Tag: NSManagedObject {
}

extension Tag {
    public static func create(withName name: String, in context: NSManagedObjectContext) throws -> UUID {
        let request: NSFetchRequest<Tag> = Tag.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", name)
        guard try context.fetch(request).count <= 0 else {
            throw TagError.duplicate
        }

        let newId = UUID()

        let tag = Tag(context: context)
        tag.id = newId
        tag.name = name
        tag.isHidden = false

        try context.save()

        return newId
    }

    public static func fetch(
        beginsWith text: String,
        showHiddenItems: Bool,
        context: NSManagedObjectContext
    ) throws -> [Tag] {
        let request: NSFetchRequest<Tag> = Tag.fetchRequest()
        var predicate: NSPredicate?

        if !text.isEmpty {
            // HACK: ひらがな,カタカナを区別しない
            if let transformed = text.applyingTransform(.hiraganaToKatakana, reverse: false), transformed != text {
                predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
                    NSPredicate(format: "name BEGINSWITH[cd] %@", transformed as CVarArg),
                    NSPredicate(format: "name BEGINSWITH[cd] %@", text as CVarArg),
                ])
            } else {
                predicate = NSPredicate(format: "name BEGINSWITH[cd] %@", text as CVarArg)
            }
        }

        if let _predicate = predicate {
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                _predicate,
                NSPredicate(format: "isHidden == false"),
            ])
        } else {
            predicate = NSPredicate(format: "isHidden == false")
        }

        request.predicate = predicate
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Tag.name, ascending: true)]

        return try context.fetch(request)
    }
}

extension NSManagedObjectContext {
    public func updateTag(having id: UUID, isHidden: Bool) throws {
        let request: NSFetchRequest<Tag> = Tag.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)

        guard let tag = try fetch(request).first else {
            throw TagError.notFound
        }

        tag.isHidden = isHidden

        try save()
    }

    public func deleteTag(having id: UUID) throws {
        let request: NSFetchRequest<Tag> = Tag.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)

        guard let tag = try fetch(request).first else {
            throw TagError.notFound
        }

        delete(tag)

        try save()
    }
}
