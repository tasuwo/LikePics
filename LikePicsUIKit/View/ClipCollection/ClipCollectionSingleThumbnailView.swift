//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Smoothie
import UIKit

public class ClipCollectionSingleThumbnailView: UIImageView {
    override public func smt_willLoad(userInfo: [AnyHashable: Any]?) {
        super.smt_willLoad(userInfo: userInfo)
        backgroundColor = Asset.Color.secondaryBackground.color
    }

    override public func smt_display(_ image: UIImage?, userInfo: [AnyHashable: Any]?) {
        DispatchQueue.main.async {
            self.backgroundColor = .clear
        }
        super.smt_display(image, userInfo: userInfo)
    }
}
