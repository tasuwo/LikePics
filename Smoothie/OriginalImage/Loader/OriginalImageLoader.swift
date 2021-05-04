//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

public protocol OriginalImageLoader {
    func loadData(with request: OriginalImageRequest) -> Data?
}
