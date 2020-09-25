//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import RealmSwift

class RealmClipListQuery {
    private var token: NotificationToken?
    private let results: Results<ClipObject>
    private var subject: CurrentValueSubject<[ClipQuery], Error>

    // MARK: - Lifecycle

    init(results: Results<ClipObject>) {
        self.results = results
        self.subject = .init(results.map({ RealmClipQuery(object: $0) }))
        self.token = self.results.observe { [weak self] (change: RealmCollectionChange<Results<ClipObject>>) in
            switch change {
            case let .initial(results):
                self?.subject.send(results.map({ RealmClipQuery(object: $0) }))

            case let .update(results, deletions: _, insertions: _, modifications: _):
                self?.subject.send(results.map({ RealmClipQuery(object: $0) }))

            case let .error(error):
                self?.subject.send(completion: .failure(error))
            }
        }
    }

    deinit {
        self.token?.invalidate()
    }
}

extension RealmClipListQuery: ClipListQuery {
    // MARK: - ClipListQuery

    var clips: CurrentValueSubject<[ClipQuery], Error> {
        return self.subject
    }
}
