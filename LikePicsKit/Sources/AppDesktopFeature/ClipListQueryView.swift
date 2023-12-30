//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import Domain
import Persistence
import SwiftUI

struct ClipListQueryView<Content: View>: View {
    enum Query {
        case all
        case tagged(Domain.Tag.ID)
        case album(Domain.Album.ID)
    }

    struct ClipSource: View {
        private let content: ([Domain.Clip]) -> Content
        @FetchRequest private var clips: FetchedResults<Persistence.Clip>

        init(request: FetchRequest<Persistence.Clip>, content: @escaping ([Domain.Clip]) -> Content) {
            _clips = request
            self.content = content
        }

        var body: some View {
            content(clips.compactMap({ $0.map(to: Domain.Clip.self) }))
        }
    }

    struct AlbumSource: View {
        private let content: ([Domain.Clip]) -> Content
        @FetchRequest private var albums: FetchedResults<Persistence.Album>
        @AppStorage(\.showHiddenItems) var showHiddenItems

        init(request: FetchRequest<Persistence.Album>, content: @escaping ([Domain.Clip]) -> Content) {
            _albums = request
            self.content = content
        }

        var body: some View {
            let clips = albums.first?
                .items?
                .compactMap({ $0 as? AlbumItem })
                .filter({ showHiddenItems ? true : $0.clip?.isHidden == false })
                .sorted(by: { $0.index < $1.index })
                .compactMap({ $0.clip?.map(to: Domain.Clip.self) }) ?? []
            content(clips)
        }
    }

    private let query: Query
    private let content: ([Domain.Clip]) -> Content

    @AppStorage(\.showHiddenItems) var showHiddenItems

    init(_ query: Query, @ViewBuilder content: @escaping ([Domain.Clip]) -> Content) {
        self.query = query
        self.content = content
    }

    var body: some View {
        Group {
            switch query {
            case .all:
                ClipSource(request: .init(sortDescriptors: [.init(keyPath: \Persistence.Clip.createdDate, ascending: false)],
                                          predicate: showHiddenItems ? nil : NSPredicate(format: "isHidden == false"),
                                          animation: .default),
                           content: content)

            case let .tagged(id):
                ClipSource(request: .init(sortDescriptors: [.init(keyPath: \Persistence.Clip.createdDate, ascending: false)],
                                          predicate: showHiddenItems
                                              ? NSPredicate(format: "SUBQUERY(tags, $tag, $tag.id == %@).@count > 0", id as CVarArg)
                                              : NSCompoundPredicate(andPredicateWithSubpredicates: [
                                                  NSPredicate(format: "SUBQUERY(tags, $tag, $tag.id == %@).@count > 0", id as CVarArg),
                                                  NSPredicate(format: "isHidden == false", id as CVarArg)
                                              ]),
                                          animation: .default),
                           content: content)

            case let .album(id):
                AlbumSource(request: .init(sortDescriptors: [],
                                           predicate: NSPredicate(format: "id == %@", id as CVarArg),
                                           animation: .default),
                            content: content)
            }
        }
        .animation(.default, value: showHiddenItems)
    }
}
