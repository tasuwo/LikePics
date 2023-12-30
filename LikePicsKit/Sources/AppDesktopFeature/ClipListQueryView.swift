//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import Domain
import Persistence
import SwiftUI

struct ClipListQueryView: View {
    enum Query {
        case all
        case tagged(Domain.Tag.ID)
        case album(Domain.Album.ID)
    }

    struct ClipSource: View {
        @FetchRequest private var clips: FetchedResults<Persistence.Clip>

        init(_ request: FetchRequest<Persistence.Clip>) {
            _clips = request
        }

        var body: some View {
            ClipListView(clips: clips.compactMap({ $0.map(to: Domain.Clip.self) }))
        }
    }

    struct AlbumSource: View {
        @FetchRequest private var albums: FetchedResults<Persistence.Album>
        @AppStorage(StorageKey.showHiddenItems.rawValue) var showHiddenItems: Bool = false

        init(_ request: FetchRequest<Persistence.Album>) {
            _albums = request
        }

        var body: some View {
            let clips = albums.first?
                .items?
                .compactMap({ $0 as? AlbumItem })
                .filter({ showHiddenItems ? true : $0.clip?.isHidden == false })
                .sorted(by: { $0.index < $1.index })
                .compactMap({ $0.clip?.map(to: Domain.Clip.self) }) ?? []
            ClipListView(clips: clips)
        }
    }

    private let query: Query

    @AppStorage(StorageKey.showHiddenItems.rawValue) var showHiddenItems: Bool = false

    init(_ query: Query) {
        self.query = query
    }

    var body: some View {
        Group {
            switch query {
            case .all:
                ClipSource(.init(sortDescriptors: [.init(keyPath: \Persistence.Clip.createdDate, ascending: false)],
                                 predicate: showHiddenItems ? nil : NSPredicate(format: "isHidden == false"),
                                 animation: .default))

            case let .tagged(id):
                ClipSource(.init(sortDescriptors: [.init(keyPath: \Persistence.Clip.createdDate, ascending: false)],
                                 predicate: showHiddenItems
                                     ? NSPredicate(format: "SUBQUERY(tags, $tag, $tag.id == %@).@count > 0", id as CVarArg)
                                     : NSCompoundPredicate(andPredicateWithSubpredicates: [
                                         NSPredicate(format: "SUBQUERY(tags, $tag, $tag.id == %@).@count > 0", id as CVarArg),
                                         NSPredicate(format: "isHidden == false", id as CVarArg)
                                     ]),
                                 animation: .default))

            case let .album(id):
                AlbumSource(.init(sortDescriptors: [],
                                  predicate: NSPredicate(format: "id == %@", id as CVarArg),
                                  animation: .default))
            }
        }
        .animation(.default, value: showHiddenItems)
    }
}
