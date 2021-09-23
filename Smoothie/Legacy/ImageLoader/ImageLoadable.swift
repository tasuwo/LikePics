//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

public protocol ImageLoadable {
    func load(for request: LegacyImageRequest, completion: @escaping (Data?) -> Void)
}
