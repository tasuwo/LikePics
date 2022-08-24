//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import UIKit

class ImageLoadTask {
    private struct Subscription {
        let id: UUID
        let completion: (ImageResponse?) -> Void
    }

    // MARK: - Properties

    let request: ImageRequest
    private weak var pipeline: Pipeline?

    private var subscriptions: [UUID: Subscription] = [:]

    private var isStarted = false
    private var isDisposed = false
    var onDisposed: (() -> Void)?

    weak var ongoingOperation: Operation?

    // MARK: - Initializers

    init(request: ImageRequest, pipeline: Pipeline) {
        self.request = request
        self.pipeline = pipeline
    }

    // MARK: - Methods

    // MARK: Subscribe/Unsubscribe

    func subscribe(completion: @escaping (ImageResponse?) -> Void) -> ImageLoadTaskCancellable {
        let id = UUID()

        let subscription = Subscription(id: id, completion: completion)
        subscriptions[id] = subscription

        if !isStarted {
            self.start()
        }

        let cancellable = ImageLoadTaskCancellable(id: id, task: self)
        return cancellable
    }

    func unsubscribe(for id: UUID) {
        subscriptions.removeValue(forKey: id)

        if subscriptions.isEmpty {
            terminate(isCancelled: true)
        }
    }

    private func start() {
        guard !isStarted else { return }
        isStarted = true

        guard let pipeline = pipeline else {
            terminate(isCancelled: false)
            return
        }

        pipeline.startLoading(self)
    }

    // MARK: Event

    func didLoad(_ response: ImageResponse?) {
        subscriptions.values.forEach { $0.completion(response) }
        terminate(isCancelled: false)
    }

    // MARK: Termination

    private func terminate(isCancelled: Bool) {
        guard !isDisposed else { return }

        isDisposed = true

        if isCancelled {
            ongoingOperation?.cancel()
        }

        onDisposed?()
    }
}
