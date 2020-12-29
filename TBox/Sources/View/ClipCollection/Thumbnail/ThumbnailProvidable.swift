//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import UIKit

protocol ThumbnailProvidable: AnyObject {
    var identifier: UUID? { get set }

    func set(thumbnail: Thumbnail?, context: Any?)
    func imageSize(context: Any?) -> CGSize
}
