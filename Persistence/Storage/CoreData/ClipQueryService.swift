//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import CoreData
import Domain

public class ClipQueryService {
    public var context: NSManagedObjectContext {
        didSet {
            self.observers.forEach { $0.value?.didReplaced(context: self.context) }
        }
    }

    private var observers: [WeakContainer<ViewContextObserver>] = []

    public init(context: NSManagedObjectContext) {
        self.context = context
    }
}

extension ClipQueryService: ClipQueryServiceProtocol {
    public func queryClip(having id: Domain.Clip.Identity) -> Result<Domain.ClipQuery, ClipStorageError> {
        do {
            guard let query = try CoreDataClipQuery(id: id, context: self.context) else {
                return .failure(.notFound)
            }
            self.observers.append(.init(value: query))
            return .success(query)
        } catch {
            return .failure(.internalError)
        }
    }

    public func queryClipItem(having id: Domain.ClipItem.Identity) -> Result<Domain.ClipItemQuery, ClipStorageError> {
        do {
            guard let query = try CoreDataClipItemQuery(id: id, context: self.context) else {
                return .failure(.notFound)
            }
            self.observers.append(.init(value: query))
            return .success(query)
        } catch {
            return .failure(.internalError)
        }
    }

    public func queryAllClips() -> Result<ClipListQuery, ClipStorageError> {
        do {
            let factory: CoreDataClipListQuery.RequestFactory = {
                let request: NSFetchRequest<Clip> = Clip.fetchRequest()
                request.sortDescriptors = [NSSortDescriptor(keyPath: \Clip.createdDate, ascending: true)]
                return request
            }
            let query = try CoreDataClipListQuery(requestFactory: factory, context: self.context)
            self.observers.append(.init(value: query))
            return .success(query)
        } catch {
            return .failure(.internalError)
        }
    }

    public func queryUncategorizedClips() -> Result<ClipListQuery, ClipStorageError> {
        do {
            let factory: CoreDataClipListQuery.RequestFactory = {
                let request: NSFetchRequest<Clip> = Clip.fetchRequest()
                request.sortDescriptors = [NSSortDescriptor(keyPath: \Clip.createdDate, ascending: true)]
                request.predicate = NSPredicate(format: "tags.@count == 0")
                return request
            }
            let query = try CoreDataClipListQuery(requestFactory: factory, context: self.context)
            self.observers.append(.init(value: query))
            return .success(query)
        } catch {
            return .failure(.internalError)
        }
    }

    public func queryClips(matchingKeywords keywords: [String]) -> Result<ClipListQuery, ClipStorageError> {
        return .failure(.internalError)
    }

    public func queryClips(tagged tag: Domain.Tag) -> Result<ClipListQuery, ClipStorageError> {
        do {
            let factory: CoreDataClipListQuery.RequestFactory = {
                let request: NSFetchRequest<Clip> = Clip.fetchRequest()
                request.sortDescriptors = [NSSortDescriptor(keyPath: \Clip.createdDate, ascending: true)]
                request.predicate = NSPredicate(format: "SUBQUERY(tags, $tag, $tag.id == %@).@count > 0", tag.id as CVarArg)
                return request
            }
            let query = try CoreDataClipListQuery(requestFactory: factory, context: self.context)
            self.observers.append(.init(value: query))
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
            self.observers.append(.init(value: query))
            return .success(query)
        } catch {
            return .failure(.internalError)
        }
    }

    public func queryAllAlbums() -> Result<AlbumListQuery, ClipStorageError> {
        do {
            let factory: CoreDataAlbumListQuery.RequestFactory = {
                let request: NSFetchRequest<Album> = Album.fetchRequest()
                request.sortDescriptors = [NSSortDescriptor(keyPath: \Album.createdDate, ascending: true)]
                return request
            }
            let query = try CoreDataAlbumListQuery(requestFactory: factory, context: self.context)
            self.observers.append(.init(value: query))
            return .success(query)
        } catch {
            return .failure(.internalError)
        }
    }

    public func queryAllTags() -> Result<TagListQuery, ClipStorageError> {
        do {
            let factory: CoreDataTagListQuery.RequestFactory = {
                let request: NSFetchRequest<Tag> = Tag.fetchRequest()
                request.sortDescriptors = [NSSortDescriptor(keyPath: \Tag.name, ascending: true)]
                return request
            }
            let query = try CoreDataTagListQuery(requestFactory: factory, context: self.context)
            self.observers.append(.init(value: query))
            return .success(query)
        } catch {
            return .failure(.internalError)
        }
    }
}
