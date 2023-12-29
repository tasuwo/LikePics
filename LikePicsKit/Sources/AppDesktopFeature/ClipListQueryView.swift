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

        init(_ request: FetchRequest<Persistence.Album>) {
            _albums = request
        }

        var body: some View {
            let clips = albums.first?
                .items?
                .compactMap({ $0 as? AlbumItem })
                .sorted(by: { $0.index < $1.index })
                .compactMap({ $0.clip?.map(to: Domain.Clip.self) }) ?? []
            ClipListView(clips: clips)
        }
    }

    private let query: Query

    init(_ query: Query) {
        self.query = query
    }

    var body: some View {
        switch query {
        case .all:
            ClipSource(.init(sortDescriptors: [.init(keyPath: \Persistence.Clip.createdDate, ascending: false)], predicate: nil, animation: .default))

        case let .tagged(id):
            ClipSource(.init(sortDescriptors: [.init(keyPath: \Persistence.Clip.createdDate, ascending: false)],
                             predicate: NSPredicate(format: "SUBQUERY(tags, $tag, $tag.id == %@).@count > 0", id as CVarArg),
                             animation: .default))

        case let .album(id):
            AlbumSource(.init(sortDescriptors: [], predicate: NSPredicate(format: "id == %@", id as CVarArg)))
        }
    }
}
