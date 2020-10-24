//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public class ClipsCollectionView: UICollectionView {
    public static let cellIdentifier = "Cell"

    lazy var emptyMessageView: UIView = {
        let nib = UINib(nibName: "ClipsCollectionEmptyMessageView", bundle: Bundle(for: Self.self))
        // swiftlint:disable:next force_cast
        return nib.instantiate(withOwner: self, options: nil).first as! UIView
    }()

    public var visibleEmptyMessage: Bool = false {
        didSet {
            self.emptyMessageView.alpha = self.visibleEmptyMessage ? 1 : 0
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

    public func setEditing(_ editing: Bool, animated: Bool) {
        self.visibleCells
            .compactMap { $0 as? ClipsCollectionViewCell }
            .forEach { $0.visibleSelectedMark = editing }
        self.allowsMultipleSelection = editing
    }

    private func registerCell() {
        self.register(ClipsCollectionViewCell.nib,
                      forCellWithReuseIdentifier: Self.cellIdentifier)
    }

    private func setupAppearance() {
        self.allowsSelection = true
        self.allowsMultipleSelection = false

        self.addSubview(self.emptyMessageView)
        self.emptyMessageView.translatesAutoresizingMaskIntoConstraints = false
        self.emptyMessageView.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor).isActive = true
        self.emptyMessageView.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor).isActive = true
        self.emptyMessageView.trailingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.trailingAnchor).isActive = true
        self.emptyMessageView.leadingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leadingAnchor).isActive = true

        self.visibleEmptyMessage = false
    }
}
