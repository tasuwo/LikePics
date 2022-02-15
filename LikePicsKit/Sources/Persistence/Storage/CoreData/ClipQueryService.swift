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

    private var observers: WeakContainerSet<ViewContextObserver> = .init()

    public init(context: NSManagedObjectContext) {
        self.context = context
    }
}

extension ClipQueryService: ClipQueryServiceProtocol {
    public func searchClips(query: ClipSearchQuery) -> Result<[Domain.Clip], ClipStorageError> {
        assert(Thread.isMainThread)

        guard !query.isEmpty else { return .success([]) }
        do {
            let request: NSFetchRequest<Clip> = Clip.fetchRequest()
            request.sortDescriptors = [query.sort.sortDescriptor]
            request.predicate = query.predicate
            request.fetchLimit = 12 // TODO:
            let clips = try self.context.fetch(request)
            return .success(clips.compactMap { $0.map(to: Domain.Clip.self) })
        } catch {
            return .failure(.internalError)
        }
    }

    public func searchAlbums(containingTitle title: String, includesHiddenItems: Bool, limit: Int) -> Result<[Domain.Album], ClipStorageError> {
        assert(Thread.isMainThread)

        let searchText = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !searchText.isEmpty else { return .success([]) }
        do {
            let request: NSFetchRequest<Album> = Album.fetchRequest()

            var predicate: NSPredicate
            // HACK: ひらがな,カタカナを区別しない
            if let transformed = searchText.applyingTransform(.hiraganaToKatakana, reverse: false), transformed != searchText {
                predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
                    NSPredicate(format: "title CONTAINS[cd] %@", transformed as CVarArg),
                    NSPredicate(format: "title CONTAINS[cd] %@", searchText as CVarArg)
                ])
            } else {
                predicate = NSPredicate(format: "title CONTAINS[cd] %@", searchText as CVarArg)
            }

            if !includesHiddenItems {
                predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                    predicate,
                    NSPredicate(format: "isHidden == false")
                ])
            }

            request.predicate = predicate
            request.fetchLimit = limit
            let albums = try self.context.fetch(request)
            return .success(albums.compactMap { $0.map(to: Domain.Album.self) })
        } catch {
            return .failure(.internalError)
        }
    }

    public func searchTags(containingName name: String, includesHiddenItems: Bool, limit: Int) -> Result<[Domain.Tag], ClipStorageError> {
        assert(Thread.isMainThread)

        let searchText = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !searchText.isEmpty else { return .success([]) }
        do {
            let request: NSFetchRequest<Tag> = Tag.fetchRequest()

            var predicate: NSPredicate
            // HACK: ひらがな,カタカナを区別しない
            if let transformed = searchText.applyingTransform(.hiraganaToKatakana, reverse: false), transformed != searchText {
                predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
                    NSPredicate(format: "name CONTAINS[cd] %@", transformed as CVarArg),
                    NSPredicate(format: "name CONTAINS[cd] %@", searchText as CVarArg)
                ])
            } else {
                predicate = NSPredicate(format: "name CONTAINS[cd] %@", searchText as CVarArg)
            }

            if !includesHiddenItems {
                predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                    predicate,
                    NSPredicate(format: "isHidden == false")
                ])
            }

            request.predicate = predicate
            request.fetchLimit = limit
            let tags = try self.context.fetch(request)
            return .success(tags.compactMap { $0.map(to: Domain.Tag.self) })
        } catch {
            return .failure(.internalError)
        }
    }

    public func readClipAndTags(for clipIds: [Domain.Clip.Identity]) -> Result<([Domain.Clip], [Domain.Tag]), ClipStorageError> {
        assert(Thread.isMainThread)

        do {
            let request: NSFetchRequest<Clip> = Clip.fetchRequest()
            request.predicate = NSPredicate(format: "id IN %@", clipIds as CVarArg)
            let clips = try self.context.fetch(request)

            var resultClips: [Domain.Clip] = []
            var resultTags: [Domain.Tag] = []
            for clip in clips {
                if let clip = clip.map(to: Domain.Clip.self) {
                    resultClips.append(clip)
                }
                let tags = clip.tags?.allObjects
                    .compactMap { $0 as? Tag }
                    .compactMap { $0.map(to: Domain.Tag.self) } ?? []
                resultTags += tags
            }
            resultTags = Array(Set(resultTags))

            return .success((resultClips, resultTags))
        } catch {
            return .failure(.internalError)
        }
    }

    public func queryClip(having id: Domain.Clip.Identity) -> Result<Domain.ClipQuery, ClipStorageError> {
        assert(Thread.isMainThread)

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

    public func queryClipItems(inClipHaving id: Domain.Clip.Identity) -> Result<ClipItemListQuery, ClipStorageError> {
        assert(Thread.isMainThread)

        do {
            let factory: CoreDataClipItemListQuery.RequestFactory = {
                let request: NSFetchRequest<Item> = Item.fetchRequest()
                request.predicate = NSPredicate(format: "clipId == %@", id as CVarArg)
                request.sortDescriptors = [NSSortDescriptor(keyPath: \Item.index, ascending: true)]
                return request
            }
            let query = try CoreDataClipItemListQuery(requestFactory: factory, context: self.context)
            self.observers.append(.init(value: query))
            return .success(query)
        } catch {
            return .failure(.internalError)
        }
    }

    public func queryClipItem(having id: Domain.ClipItem.Identity) -> Result<Domain.ClipItemQuery, ClipStorageError> {
        assert(Thread.isMainThread)

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
        assert(Thread.isMainThread)

        do {
            let factory: CoreDataClipListQuery.RequestFactory = {
                let request: NSFetchRequest<Clip> = Clip.fetchRequest()
                request.sortDescriptors = [NSSortDescriptor(keyPath: \Clip.createdDate, ascending: false)]
                return request
            }
            let query = try CoreDataClipListQuery(requestFactory: factory, context: self.context)
            self.observers.append(.init(value: query))
            return .success(query)
        } catch {
            return .failure(.internalError)
        }
    }

    public func queryAllListingClips() -> Result<ListingClipListQuery, ClipStorageError> {
        assert(Thread.isMainThread)

        do {
            let factory: CoreDataListingClipListQuery.RequestFactory = {
                let request: NSFetchRequest<Clip> = Clip.fetchRequest()
                request.sortDescriptors = [NSSortDescriptor(keyPath: \Clip.createdDate, ascending: false)]
                return request
            }
            let query = try CoreDataListingClipListQuery(requestFactory: factory, context: self.context)
            self.observers.append(.init(value: query))
            return .success(query)
        } catch {
            return .failure(.internalError)
        }
    }

    public func queryUncategorizedClips() -> Result<ClipListQuery, ClipStorageError> {
        assert(Thread.isMainThread)

        do {
            let factory: CoreDataClipListQuery.RequestFactory = {
                let request: NSFetchRequest<Clip> = Clip.fetchRequest()
                request.sortDescriptors = [NSSortDescriptor(keyPath: \Clip.createdDate, ascending: false)]
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

    public func queryTags(forClipHaving clipId: Domain.Clip.Identity) -> Result<TagListQuery, ClipStorageError> {
        assert(Thread.isMainThread)

        do {
            let factory: CoreDataTagListQuery.RequestFactory = {
                let request: NSFetchRequest<Tag> = Tag.fetchRequest()
                request.sortDescriptors = [NSSortDescriptor(keyPath: \Tag.name, ascending: true)]
                request.predicate = NSPredicate(format: "SUBQUERY(clips, $clip, $clip.id == %@).@count > 0", clipId as CVarArg)
                return request
            }
            let query = try CoreDataTagListQuery(requestFactory: factory, context: self.context)
            self.observers.append(.init(value: query))
            return .success(query)
        } catch {
            return .failure(.internalError)
        }
    }

    public func queryClips(query: ClipSearchQuery) -> Result<ClipListQuery, ClipStorageError> {
        assert(Thread.isMainThread)

        guard !query.isEmpty else { return .failure(.invalidParameter) }
        do {
            let factory: CoreDataClipListQuery.RequestFactory = {
                let request: NSFetchRequest<Clip> = Clip.fetchRequest()
                request.sortDescriptors = [query.sort.sortDescriptor]
                request.predicate = query.predicate
                return request
            }
            let query = try CoreDataClipListQuery(requestFactory: factory, context: self.context)
            self.observers.append(.init(value: query))
            return .success(query)
        } catch {
            return .failure(.internalError)
        }
    }

    public func queryClips(tagged tag: Domain.Tag) -> Result<ClipListQuery, ClipStorageError> {
        assert(Thread.isMainThread)

        do {
            let factory: CoreDataClipListQuery.RequestFactory = {
                let request: NSFetchRequest<Clip> = Clip.fetchRequest()
                request.sortDescriptors = [NSSortDescriptor(keyPath: \Clip.createdDate, ascending: false)]
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

    public func queryClips(tagged tagId: Domain.Tag.Identity) -> Result<ClipListQuery, ClipStorageError> {
        assert(Thread.isMainThread)

        do {
            let factory: CoreDataClipListQuery.RequestFactory = {
                let request: NSFetchRequest<Clip> = Clip.fetchRequest()
                request.sortDescriptors = [NSSortDescriptor(keyPath: \Clip.createdDate, ascending: false)]
                request.predicate = NSPredicate(format: "SUBQUERY(tags, $tag, $tag.id == %@).@count > 0", tagId as CVarArg)
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
        assert(Thread.isMainThread)

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

    public func queryAlbums(containingClipHavingClipId id: Domain.Clip.Identity) -> Result<ListingAlbumListQuery, ClipStorageError> {
        assert(Thread.isMainThread)

        do {
            let factory: CoreDataListingAlbumListQuery.RequestFactory = {
                let request: NSFetchRequest<AlbumItem> = AlbumItem.fetchRequest()
                request.sortDescriptors = [NSSortDescriptor(keyPath: \AlbumItem.index, ascending: false)]
                request.predicate = NSPredicate(format: "clip.id == %@", id as CVarArg)
                return request
            }
            let query = try CoreDataListingAlbumListQuery(requestFactory: factory, context: context)
            observers.append(.init(value: query))

            return .success(query)
        } catch {
            return .failure(.internalError)
        }
    }

    public func queryAllAlbums() -> Result<AlbumListQuery, ClipStorageError> {
        assert(Thread.isMainThread)

        do {
            let factory: CoreDataAlbumListQuery.RequestFactory = {
                let request: NSFetchRequest<Album> = Album.fetchRequest()
                request.sortDescriptors = [NSSortDescriptor(keyPath: \Album.index, ascending: true)]
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
        assert(Thread.isMainThread)

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

extension ClipQueryService: TagQueryServiceProtocol {
    public func queryTags() -> Result<TagListQuery, ClipStorageError> {
        queryAllTags()
    }
}
