//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import CoreData
import Domain

public class NewClipQueryService {
    private let context: NSManagedObjectContext

    public init(context: NSManagedObjectContext) {
        self.context = context
    }
}

extension NewClipQueryService: ClipQueryServiceProtocol {
    public func queryClip(having id: Domain.Clip.Identity) -> Result<Domain.ClipQuery, ClipStorageError> {
        do {
            guard let query = try CoreDataClipQuery(id: id, context: self.context) else {
                return .failure(.notFound)
            }
            return .success(query)
        } catch {
            return .failure(.internalError)
        }
    }

    public func queryAllClips() -> Result<ClipListQuery, ClipStorageError> {
        do {
            let request = NSFetchRequest<Clip>(entityName: "Clip")
            request.sortDescriptors = [NSSortDescriptor(key: "createdDate", ascending: true)]
            return .success(try CoreDataClipListQuery(request: request, context: self.context))
        } catch {
            return .failure(.internalError)
        }
    }

    public func queryUncategorizedClips() -> Result<ClipListQuery, ClipStorageError> {
        do {
            let request = NSFetchRequest<Clip>(entityName: "Clip")
            request.sortDescriptors = [NSSortDescriptor(key: "createdDate", ascending: true)]
            request.predicate = NSPredicate(format: "tags.@count == 0")
            return .success(try CoreDataClipListQuery(request: request, context: self.context))
        } catch {
            return .failure(.internalError)
        }
    }

    public func queryClips(matchingKeywords keywords: [String]) -> Result<ClipListQuery, ClipStorageError> {
        return .failure(.internalError)
    }

    public func queryClips(tagged tag: Domain.Tag) -> Result<ClipListQuery, ClipStorageError> {
        do {
            guard let query = try CoreDataClipListQuery(id: tag.id, context: self.context) else {
                return .failure(.notFound)
            }
            return .success(query)
        } catch {
            return .failure(.internalError)
        }
    }

    public func queryAlbum(having id: Domain.Album.Identity) -> Result<AlbumQuery, ClipStorageError> {
        do {
            guard let query = try CoreDataAlbumQuery(id: id, context: self.context) else {
                return .failure(.notFound)
            }
            return .success(query)
        } catch {
            return .failure(.internalError)
        }
    }

    public func queryAllAlbums() -> Result<AlbumListQuery, ClipStorageError> {
        do {
            let request = NSFetchRequest<Album>(entityName: "Album")
            request.sortDescriptors = [NSSortDescriptor(key: "createdDate", ascending: true)]
            return .success(try CoreDataAlbumListQuery(request: request, context: self.context))
        } catch {
            return .failure(.internalError)
        }
    }

    public func queryAllTags() -> Result<TagListQuery, ClipStorageError> {
        do {
            let request = NSFetchRequest<Tag>(entityName: "Tag")
            request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            return .success(try CoreDataTagListQuery(request: request, context: self.context))
        } catch {
            return .failure(.internalError)
        }
    }
}
