//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

class ClipPreviewCollectionLayout: UICollectionViewFlowLayout {
    // MARK: - Lifecycle

    override public init() {
        super.init()

        self.setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Methods

    private func setup() {
        self.scrollDirection = .horizontal
        self.sectionInset = .zero
    }

    // MARK: - UICollectionViewFlowLayout
}
