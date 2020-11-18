//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public class ClipsCollectionView: UICollectionView {
    public static let cellIdentifier = "Cell"

    override public var allowsMultipleSelection: Bool {
        didSet {
            self.visibleCells
                .compactMap { $0 as? ClipsCollectionViewCell }
                .forEach { $0.visibleSelectedMark = self.allowsMultipleSelection }
        }
    }

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
        self.register(ClipsCollectionViewCell.nib,
                      forCellWithReuseIdentifier: Self.cellIdentifier)
    }

    private func setupAppearance() {
        self.allowsSelection = true
        self.allowsMultipleSelection = false
    }
}
