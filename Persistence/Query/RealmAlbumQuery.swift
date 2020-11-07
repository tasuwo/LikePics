//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import RealmSwift

class RealmAlbumQuery {
    private var token: NotificationToken?
    private let object: AlbumObject
    private var subject: CurrentValueSubject<Domain.Album, Error>

    // MARK: - Lifecycle

    init(object: AlbumObject) {
        self.object = object
        self.subject = .init(Domain.Album.make(by: object))
        self.token = self.object.observe { [weak self] (change: ObjectChange<AlbumObject>) in
            switch change {
            case let .change(object, _):
                self?.subject.send(Domain.Album.make(by: object))

            case .deleted:
                self?.subject.send(completion: .finished)

            case let .error(error):
                self?.subject.send(completion: .failure(error))
            }
        }
    }

    deinit {
        self.token?.invalidate()
    }
}

extension RealmAlbumQuery: AlbumQuery {
    // MARK: - AlbumQuery

    var album: CurrentValueSubject<Domain.Album, Error> {
        return self.subject
    }
}
