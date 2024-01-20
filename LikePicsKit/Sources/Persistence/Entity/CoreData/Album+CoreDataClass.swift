//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//
//

import CoreData
import Foundation

public class Album: NSManagedObject {
    public static func fetch(beginsWith text: String,
                             showHiddenItems: Bool,
                             context: NSManagedObjectContext) throws -> [Album]
    {
        let request: NSFetchRequest<Album> = Album.fetchRequest()
        var predicate: NSPredicate?

        if !text.isEmpty {
            // HACK: ひらがな,カタカナを区別しない
            if let transformed = text.applyingTransform(.hiraganaToKatakana, reverse: false), transformed != text {
                predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
                    NSPredicate(format: "title BEGINSWITH[cd] %@", transformed as CVarArg),
                    NSPredicate(format: "title BEGINSWITH[cd] %@", text as CVarArg)
                ])
            } else {
                predicate = NSPredicate(format: "title BEGINSWITH[cd] %@", text as CVarArg)
            }
        }

        if let _predicate = predicate {
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                _predicate,
                NSPredicate(format: "isHidden == false")
            ])
        } else {
            predicate = NSPredicate(format: "isHidden == false")
        }

        request.predicate = predicate
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Album.title, ascending: true)]

        return try context.fetch(request)
    }
}

public enum AlbumUpdateError: Error {
    case notFound
}

public extension NSManagedObjectContext {
    func createAlbum(withTitle title: String) throws -> UUID {
        let request: NSFetchRequest<Album> = Album.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Album.index, ascending: true)]
        let albums = try self.fetch(request)

        let newId = UUID()

        let album = Album(context: self)
        let date = Date()
        album.id = newId
        album.title = title
        album.index = 1
        album.isHidden = false
        album.createdDate = date
        album.updatedDate = date

        var currentIndex: Int64 = 2
        albums.forEach {
            $0.index = currentIndex
            currentIndex += 1
        }

        try self.save()

        return newId
    }

    func updateAlbum(having id: UUID, isHidden: Bool) throws {
        let request: NSFetchRequest<Album> = Album.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)

        guard let album = try fetch(request).first else {
            throw AlbumUpdateError.notFound
        }

        album.isHidden = isHidden

        try save()
    }

    func updateAlbum(having id: UUID, title: String) throws {
        let request: NSFetchRequest<Album> = Album.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)

        guard let album = try fetch(request).first else {
            throw AlbumUpdateError.notFound
        }

        album.title = title

        try save()
    }

    func deleteAlbum(having id: UUID) throws {
        let request: NSFetchRequest<Album> = Album.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)

        guard let album = try fetch(request).first else {
            throw AlbumUpdateError.notFound
        }

        delete(album)

        try save()
    }
}
