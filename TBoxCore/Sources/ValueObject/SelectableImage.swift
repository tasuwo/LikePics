//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import CoreGraphics

struct SelectableImage: SelectableImageCellDataSource {
    let url: URL
    let alternativeUrl: URL?
    let height: CGFloat
    let width: CGFloat

    var isValid: Bool {
        return self.height != 0
            && self.width != 0
            && self.height > 10
            && self.width > 10
    }
}
