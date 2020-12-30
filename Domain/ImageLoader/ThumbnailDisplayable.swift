//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public protocol ThumbnailDisplayable: AnyObject {
    var identifier: UUID? { get }
    func startLoading()
    func set(_ result: ThumbnailLoadResult)
}
