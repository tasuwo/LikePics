//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import RealmSwift

class RealmAlbumListQuery {
    private var token: NotificationToken?
    private let results: Results<AlbumObject>
    private var subject: CurrentValueSubject<[Domain.Album], Error>

    // MARK: - Lifecycle

    init(results: Results<AlbumObject>) {
        self.results = results
        self.subject = .init(results.map({ .make(by: $0) }))
        self.token = self.results.observe { [weak self] (change: RealmCollectionChange<Results<AlbumObject>>) in
            switch change {
            case let .initial(results):
                self?.subject.send(results.map({ .make(by: $0) }))

            case let .update(results, deletions: _, insertions: _, modifications: _):
                self?.subject.send(results.map({ .make(by: $0) }))

            case let .error(error):
                self?.subject.send(completion: .failure(error))
            }
        }
    }

    deinit {
        self.token?.invalidate()
    }
}

extension RealmAlbumListQuery: AlbumListQuery {
    // MARK: - AlbumListQuery

    var albums: CurrentValueSubject<[Domain.Album], Error> {
        return self.subject
    }
}
