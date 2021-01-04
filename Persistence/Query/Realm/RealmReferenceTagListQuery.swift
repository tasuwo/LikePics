//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import RealmSwift

class RealmReferenceTagListQuery {
    private var token: NotificationToken?
    private let results: Results<ReferenceTagObject>
    private var subject: CurrentValueSubject<[Domain.Tag], Error>

    // MARK: - Lifecycle

    init(results: Results<ReferenceTagObject>) {
        self.results = results
        self.subject = .init(results.map({ .make(by: $0) }))
        self.token = self.results.observe { [weak self] (change: RealmCollectionChange<Results<ReferenceTagObject>>) in
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

extension RealmReferenceTagListQuery: TagListQuery {
    // MARK: - TagListQuery

    var tags: CurrentValueSubject<[Domain.Tag], Error> {
        return self.subject
    }
}

private extension Domain.Tag {
    static func make(by tag: ReferenceTagObject) -> Self {
        // swiftlint:disable:next force_unwrapping
        return .init(id: UUID(uuidString: tag.id)!, name: tag.name, isHidden: false)
    }
}
