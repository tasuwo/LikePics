//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

class ClipTargetCollectionView: UICollectionView {
    static let cellIdentifier = "Cell"

    // MARK: - Lifecycle

    override public init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)

        self.registerCell()
        self.setupAppearance()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        self.registerCell()
        self.setupAppearance()
    }

    // MARK: - Methods

    private func registerCell() {
        self.register(UICollectionViewCell.self, forCellWithReuseIdentifier: Self.cellIdentifier)
    }

    private func setupAppearance() {
        // TODO:
        // let layout = UICollectionViewFlowLayout()
        // layout.itemSize = .init(width: 150, height: 150)
        // layout.sectionInset = .init(top: 30, left: 30, bottom: 30, right: 30)
        // self.collectionViewLayout = layout
    }
}
