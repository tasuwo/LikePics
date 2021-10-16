//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

final class ImageLoadTaskPool {
    // MARK: - Properties

    private var pool: [ImageRequestKey: ImageLoadTask] = [:]

    // MARK: - Methods

    func task(for key: ImageRequestKey, make: () -> ImageLoadTask) -> ImageLoadTask {
        if let task = pool[key] {
            return task
        }
        let task = make()
        task.onDisposed = { [weak self] in
            self?.pool.removeValue(forKey: key)
        }
        pool[key] = task
        return task
    }
}
