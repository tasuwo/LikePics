//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import UIKit

protocol SearchMenuAction {
    var title: String { get }
    var isSelected: Bool { get }
    var image: UIImage? { get }
}

extension SearchMenuAction {
    func uiAction(_ handler: @escaping (SearchMenuAction) -> Void) -> UIAction {
        return .init(title: title, image: image, state: isSelected ? .on : .off) { _ in handler(self) }
    }
}
