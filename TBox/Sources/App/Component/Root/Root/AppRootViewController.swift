//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import TBoxUIKit
import UIKit

protocol AppRootViewController: ClipPreviewPresentingAnimatorDataSource {
    var currentViewController: UIViewController? { get }
}
