//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public class AlbumListCollectionView: UICollectionView {
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
        self.register(AlbumListCollectionViewCell.nib,
                      forCellWithReuseIdentifier: Self.cellIdentifier)
    }

    private func setupAppearance() {
        self.allowsSelection = true
        self.allowsMultipleSelection = false
    }
}
