//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public protocol ClipItemInformationViewDataSource: AnyObject {
    func previewImage(_ view: ClipItemInformationView) -> UIImage?
    func previewPageBounds(_ view: ClipItemInformationView) -> CGRect
}
