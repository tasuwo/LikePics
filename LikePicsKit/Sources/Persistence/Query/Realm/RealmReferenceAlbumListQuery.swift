//
//  Copyright ©︎ 2022 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import Foundation
import RealmSwift

class RealmReferenceAlbumListQuery {
    private var token: NotificationToken?
    private let results: Results<ReferenceAlbumObject>
    private var subject: CurrentValueSubject<[Domain.ListingAlbumTitle], Error>

    // MARK: - Lifecycle

    init(results: Results<ReferenceAlbumObject>) {
        self.results = results
        self.subject = .init(results.map({ .make(by: $0) }))
        self.token = self.results.observe { [weak self] (change: RealmCollectionChange<Results<ReferenceAlbumObject>>) in
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

extension RealmReferenceAlbumListQuery: ListingAlbumTitleListQuery {
    // MARK: - ListingAlbumTitleListQuery

    var albums: CurrentValueSubject<[Domain.ListingAlbumTitle], Error> {
        return self.subject
    }
}

extension Domain.ListingAlbumTitle {
    fileprivate static func make(by album: ReferenceAlbumObject) -> Self {
        return .init(id: album.id, title: album.title, isHidden: album.isHidden, registeredDate: album.registeredDate, updatedDate: album.updatedDate)
    }
}
