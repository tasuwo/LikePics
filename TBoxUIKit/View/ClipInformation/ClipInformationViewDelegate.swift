//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public protocol ClipInformationViewDelegate: AnyObject {
    func didTapAddTagButton(_ view: ClipInformationView)
    func clipInformationView(_ view: ClipInformationView, didSelectTag name: String)
    func clipInformationView(_ view: ClipInformationView, shouldOpen url: URL)
    func clipInformationView(_ view: ClipInformationView, shouldCopy url: URL)
}
