//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Foundation

public typealias DarwinNotificationHandler = (DarwinNotification) -> Void

public protocol DarwinNotificationCenterProtocol {
    func addObserver(_ observer: AnyObject, for name: DarwinNotification.Name, using handler: @escaping DarwinNotificationHandler)
    func removeObserver(_ observer: AnyObject, for name: DarwinNotification.Name?)
    func post(name: DarwinNotification.Name)
}

public final class DarwinNotificationCenter {
    final class Subscription {
        let name: DarwinNotification.Name
        let handler: DarwinNotificationHandler

        weak var observer: AnyObject?

        init(name: DarwinNotification.Name, observer: AnyObject, handler: @escaping DarwinNotificationHandler) {
            self.name = name
            self.observer = observer
            self.handler = handler

            startObserve()
        }
    }

    public static let `default` = DarwinNotificationCenter()

    private let underlyingNotificationCenter = CFNotificationCenterGetDarwinNotifyCenter()
    private let queue = DispatchQueue(label: "net.tasuwo.TBoxCore.DarwinNotificationCenter", qos: .default, attributes: [], autoreleaseFrequency: .workItem)

    private var subscriptions = [Subscription]()

    // MARK: - Lifecycle

    private init() {}

    // MARK: - Methods

    // MARK: Privates

    private func signal(name: DarwinNotification.Name) {
        clean()
        queue.async {
            let targetSubscriptions = self.subscriptions.filter { $0.name == name }
            let notification = DarwinNotification(name: name)
            for subscription in targetSubscriptions {
                subscription.handler(notification)
            }
        }
    }

    private func clean() {
        queue.async {
            self.subscriptions = self.subscriptions.filter { subscription -> Bool in
                if subscription.observer == nil { subscription.endObserve() }
                return subscription.observer != nil
            }
        }
    }
}

extension DarwinNotificationCenter: DarwinNotificationCenterProtocol {
    // MARK: - DarwinNotificationCenterProtocol

    public func addObserver(_ observer: AnyObject, for name: DarwinNotification.Name, using handler: @escaping DarwinNotificationHandler) {
        clean()
        queue.async {
            let subscription = Subscription(name: name, observer: observer, handler: handler)
            guard !self.subscriptions.contains(subscription) else { return }
            self.subscriptions.append(subscription)
        }
    }

    public func removeObserver(_ observer: AnyObject, for name: DarwinNotification.Name?) {
        clean()
        queue.async {
            self.subscriptions = self.subscriptions.filter { subscription -> Bool in
                let shouldRetain = observer !== subscription.observer || (name != nil && subscription.name != name)
                if !shouldRetain { subscription.endObserve() }
                return shouldRetain
            }
        }
    }

    public func post(name: DarwinNotification.Name) {
        clean()
        guard let cfNotificationCenter = self.underlyingNotificationCenter else {
            fatalError("Invalid CFNotificationCenter")
        }
        CFNotificationCenterPostNotification(cfNotificationCenter, CFNotificationName(rawValue: name.rawValue), nil, nil, false)
    }
}

private extension DarwinNotificationCenter.Subscription {
    func startObserve() {
        guard let cfCenter = DarwinNotificationCenter.default.underlyingNotificationCenter else {
            fatalError("Invalid Darwin observation info.")
        }

        let callback: CFNotificationCallback = { _, _, name, _, _ in
            guard let cfName = name else { return }
            let notificationName = DarwinNotification.Name(cfName)
            DarwinNotificationCenter.default.signal(name: notificationName)
        }

        let observer = Unmanaged.passUnretained(self).toOpaque()
        CFNotificationCenterAddObserver(cfCenter, observer, callback, name.rawValue, nil, .coalesce)
    }

    func endObserve() {
        guard let cfCenter = DarwinNotificationCenter.default.underlyingNotificationCenter else {
            fatalError("Invalid Darwin observation info.")
        }
        let notificationName = CFNotificationName(rawValue: name.rawValue)
        var observer = self
        CFNotificationCenterRemoveObserver(cfCenter, &observer, notificationName, nil)
    }
}

extension DarwinNotificationCenter.Subscription: Equatable {
    // MARK: - Equatable

    static func == (lhs: DarwinNotificationCenter.Subscription, rhs: DarwinNotificationCenter.Subscription) -> Bool {
        return lhs.observer === rhs.observer && lhs.name == rhs.name
    }
}
