//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import UIKit

public protocol SceneResolvable: AnyObject {
    func resolveScene() -> UIWindowScene?
}
