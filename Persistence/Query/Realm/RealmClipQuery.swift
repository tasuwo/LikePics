//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import RealmSwift

class RealmClipQuery {
    private var token: NotificationToken?
    private let object: ClipObject
    private var subject: CurrentValueSubject<Domain.Clip, Error>

    // MARK: - Lifecycle

    init(object: ClipObject) {
        self.object = object
        self.subject = .init(Domain.Clip.make(by: object))
        self.token = self.object.observe { [weak self] (change: ObjectChange<ClipObject>) in
            switch change {
            case let .change(object, _):
                self?.subject.send(Domain.Clip.make(by: object))

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

extension RealmClipQuery: ClipQuery {
    // MARK: - ClipQuery

    var clip: CurrentValueSubject<Domain.Clip, Error> {
        return self.subject
    }
}
