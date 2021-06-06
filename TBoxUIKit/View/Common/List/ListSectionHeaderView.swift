//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import UIKit

public class ListSectionHeaderView: UICollectionReusableView {
    let label = UILabel()

    public var title: String {
        get {
            label.text ?? ""
        }
        set {
            label.text = newValue
        }
    }

    // MARK: - Initializers

    override public init(frame: CGRect) {
        super.init(frame: frame)
        configureViewHierarchy()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ListSectionHeaderView {
    private func configureViewHierarchy() {
        addSubview(label)

        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            label.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0)
        ])

        let metrics = UIFontMetrics(forTextStyle: .title2)
        let desc = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .title2)
        let font = UIFont.systemFont(ofSize: desc.pointSize, weight: .bold)
        label.font = metrics.scaledFont(for: font)
    }
}
