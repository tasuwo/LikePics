//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import RealmSwift

class RealmTagListQuery {
    private var token: NotificationToken?
    private let results: Results<TagObject>
    private var subject: CurrentValueSubject<[Tag], Error>

    // MARK: - Lifecycle

    init(results: Results<TagObject>) {
        self.results = results
        self.subject = .init(results.map({ .make(by: $0) }))
        self.token = self.results.observe { [weak self] (change: RealmCollectionChange<Results<TagObject>>) in
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

extension RealmTagListQuery: TagListQuery {
    // MARK: - TagListQuery

    var tags: CurrentValueSubject<[Tag], Error> {
        return self.subject
    }
}
