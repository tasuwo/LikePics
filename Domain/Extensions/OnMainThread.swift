//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

func onMainThread<T>(execute: @escaping () -> T) -> T {
    if Thread.isMainThread {
        return execute()
    } else {
        return DispatchQueue.main.sync {
            return execute()
        }
    }
}
