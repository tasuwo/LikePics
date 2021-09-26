//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Smoothie
import UIKit

public class ClipCollectionSingleThumbnailView: UIImageView {
    override public func smt_display(_ image: UIImage?) {
        super.smt_display(image)
        backgroundColor = image == nil ? Asset.Color.secondaryBackground.color : .clear
    }
}
