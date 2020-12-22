//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import UIKit

public protocol ImageSourceProvider {
    var viewDidLoad: PassthroughSubject<UIView, Never> { get }
    func resolveSources() -> Future<[ImageSource], ImageSourceProviderError>
}
