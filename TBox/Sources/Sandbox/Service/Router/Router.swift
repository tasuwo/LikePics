//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol Router {
    func showUncategorizedClipCollectionView()
    func showClipCollectionView(for tag: Tag)
}
