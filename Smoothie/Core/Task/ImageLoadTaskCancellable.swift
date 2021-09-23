//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

public struct ImageLoadTaskCancellable {
    // MARK: - Properties

    private let id: UUID
    private let task: ImageLoadTask

    // MARK: - Initializers

    init(id: UUID, task: ImageLoadTask) {
        self.id = id
        self.task = task
    }

    // MARK: - Methods

    public func cancel() {
        task.unsubscribe(for: id)
    }
}
