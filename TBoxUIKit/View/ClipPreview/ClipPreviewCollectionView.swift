//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public class ClipPreviewCollectionView: UICollectionView {
    public static let cellIdentifier = "Cell"

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
        self.register(ClipPreviewCollectionViewCell.nib,
                      forCellWithReuseIdentifier: Self.cellIdentifier)
    }

    private func setupAppearance() {
        self.allowsSelection = false
        self.allowsMultipleSelection = false

        self.showsVerticalScrollIndicator = false
        self.showsHorizontalScrollIndicator = false

        self.alwaysBounceHorizontal = true
        self.alwaysBounceVertical = false

        self.decelerationRate = .fast
    }
}
