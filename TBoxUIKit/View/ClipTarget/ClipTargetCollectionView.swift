//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public class ClipTargetCollectionView: UICollectionView {
    public static let cellIdentifier = "Cell"
    public static let headerIdentifier = "Header"

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
        self.register(ClipTargetCollectionViewCell.nib,
                      forCellWithReuseIdentifier: Self.cellIdentifier)
        self.register(ClipTargetCollectionViewHeader.nib,
                      forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                      withReuseIdentifier: Self.headerIdentifier)
    }

    private func setupAppearance() {
        self.collectionViewLayout = ClipCollectionLayout()
        self.allowsMultipleSelection = true
    }
}
