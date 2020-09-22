//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

public protocol ClipQuery {
    var value: Clip { get }
    func observe(on queue: DispatchQueue, _ block: @escaping (QueryChange<Clip>) -> Void)
}
