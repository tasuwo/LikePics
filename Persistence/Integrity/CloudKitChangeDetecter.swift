//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import CoreData
import Domain

public class CloudKitChangeDetecter {
    private weak var delegate: RemoteChangeDetecterDelegate?

    // MARK: - Lifecycle

    public init() {}

    // MARK: - Methods

    @objc
    private func didFindRelevantTransactions(_ notification: Notification) {
        guard let transactions = notification.userInfo?["transactions"] as? [NSPersistentHistoryTransaction] else { return }

        var detected: Bool = false
        for transaction in transactions where transaction.changes != nil {
            for change in transaction.changes ?? [] where change.changedObjectID.entity.name == Tag.entity().name {
                switch change.changeType {
                case .delete:
                    detected = true

                case .insert:
                    detected = true

                case .update:
                    let changedPropertyNames = Array(change.updatedProperties ?? []).map({ $0.name })
                    detected = changedPropertyNames.contains("name")

                @unknown default:
                    break
                }
                if detected { break }
            }
            if detected { break }
        }

        if detected {
            self.delegate?.didDetectChangedTag(self)
        }
    }
}

extension CloudKitChangeDetecter: RemoteChangeDetecter {
    // MARK: - RemoteChangeDetecter

    public func set(_ delegate: RemoteChangeDetecterDelegate) {
        self.delegate = delegate
    }

    public func startObserve(_ cloudStack: CloudStack) {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.didFindRelevantTransactions(_:)),
                                               name: .didFindRelevantTransactions,
                                               object: cloudStack)
    }
}
