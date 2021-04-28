//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import UIKit

protocol SearchFilterMenuAction {
    var title: String { get }
    var isSelected: Bool { get }
    var image: UIImage? { get }
}

extension SearchFilterMenuAction {
    func uiAction(_ handler: @escaping (SearchFilterMenuAction) -> Void) -> UIAction {
        return .init(title: title, image: image, state: isSelected ? .on : .off) { _ in handler(self) }
    }
}
