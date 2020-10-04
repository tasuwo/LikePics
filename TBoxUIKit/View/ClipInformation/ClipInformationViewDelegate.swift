//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import UIKit

public protocol ClipInformationViewDelegate: AnyObject {
    func didTapAddTagButton(_ view: ClipInformationView)
    func clipInformationView(_ view: ClipInformationView, didSelectTag tag: Tag)
    func clipInformationView(_ view: ClipInformationView, shouldOpen url: URL)
    func clipInformationView(_ view: ClipInformationView, shouldCopy url: URL)
}
