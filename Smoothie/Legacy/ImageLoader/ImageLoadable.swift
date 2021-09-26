//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

public protocol ImageLoadable: AnyObject {
    func load(for source: ImageSource, completion: @escaping (Data?) -> Void)
    func load(for request: LegacyImageRequest, completion: @escaping (Data?) -> Void)
}
