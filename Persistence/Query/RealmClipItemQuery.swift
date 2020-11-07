//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import RealmSwift

class RealmClipItemQuery {
    private var token: NotificationToken?
    private let object: ClipItemObject
    private var subject: CurrentValueSubject<Domain.ClipItem, Error>

    // MARK: - Lifecycle

    init(object: ClipItemObject) {
        self.object = object
        self.subject = .init(Domain.ClipItem.make(by: object))
        self.token = self.object.observe { [weak self] (change: ObjectChange<ClipItemObject>) in
            switch change {
            case let .change(object, _):
                self?.subject.send(Domain.ClipItem.make(by: object))

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

extension RealmClipItemQuery: ClipItemQuery {
    // MARK: - ClipItemQuery

    var clipItem: CurrentValueSubject<Domain.ClipItem, Error> {
        return self.subject
    }
}
