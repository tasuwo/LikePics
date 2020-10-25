//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public class AlbumSelectionTableView: UITableView {
    public static let cellIdentifier = "Cell"

    // MARK: - Lifecycle

    override public init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)

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
        self.register(AlbumSelectionCell.nib,
                      forCellReuseIdentifier: Self.cellIdentifier)
    }

    private func setupAppearance() {
        self.allowsSelection = true
        self.allowsMultipleSelection = false
        self.tableFooterView = UIView()
    }
}
