//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public protocol ClipInformationViewDataSource: AnyObject {
    func previewImage(_ view: ClipInformationView) -> UIImage?
    func previewPageBounds(_ view: ClipInformationView) -> CGRect
}
