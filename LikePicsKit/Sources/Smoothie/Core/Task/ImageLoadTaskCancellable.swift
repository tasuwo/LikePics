//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Foundation

public struct ImageLoadTaskCancellable {
    // MARK: - Properties

    private let id: UUID
    private let task: ImageLoadTask
    private let queue: DispatchQueue

    // MARK: - Initializers

    init(id: UUID, task: ImageLoadTask, queue: DispatchQueue) {
        self.id = id
        self.task = task
        self.queue = queue
    }

    // MARK: - Methods

    public func cancel() {
        queue.async {
            task.unsubscribe(for: id)
        }
    }
}
