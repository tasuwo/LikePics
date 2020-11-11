//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import RealmSwift

class RealmTagQuery {
    private var token: NotificationToken?
    private let object: TagObject
    private var subject: CurrentValueSubject<Domain.Tag, Error>

    // MARK: - Lifecycle

    init(object: TagObject) {
        self.object = object
        self.subject = .init(Domain.Tag.make(by: object))
        self.token = self.object.observe { [weak self] (change: ObjectChange<TagObject>) in
            switch change {
            case let .change(object, _):
                self?.subject.send(Domain.Tag.make(by: object))

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

extension RealmTagQuery: TagQuery {
    // MARK: - TagQuery

    var tag: CurrentValueSubject<Domain.Tag, Error> {
        return self.subject
    }
}
