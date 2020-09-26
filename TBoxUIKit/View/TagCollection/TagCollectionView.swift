//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public class TagCollectionView: UICollectionView {
    public static let cellIdentifier = "Cell"

    override public var contentSize: CGSize {
        didSet {
            self.invalidateIntrinsicContentSize()
        }
    }

    override public var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: self.contentSize.height)
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
        self.register(TagCollectionViewCell.nib,
                      forCellWithReuseIdentifier: Self.cellIdentifier)
    }

    private func setupAppearance() {
        self.allowsSelection = true
        self.allowsMultipleSelection = true
    }
}
