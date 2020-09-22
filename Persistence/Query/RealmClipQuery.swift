//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import RealmSwift

class RealmClipQuery {
    private var token: NotificationToken? {
        willSet {
            self.token?.invalidate()
        }
    }

    private let object: ClipObject

    init(object: ClipObject) {
        self.object = object
    }

    deinit {
        self.token?.invalidate()
    }
}

extension RealmClipQuery: ClipQuery {
    // MARK: - ClipQuery

    var value: Clip {
        return Clip.make(by: self.object)
    }

    func observe(on queue: DispatchQueue, _ block: @escaping (QueryChange<Clip>) -> Void) {
        self.token = self.object.observe(on: queue) { (change: ObjectChange<ClipObject>) in
            switch change {
            case let .change(object, _):
                block(.change(Clip.make(by: object)))

            case .deleted:
                block(.deleted)

            case let .error(error):
                block(.error(error))
            }
        }
    }
}
