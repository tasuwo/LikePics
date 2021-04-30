//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import UIKit

public class SearchEntrySectionHeaderView: UICollectionReusableView {
    public static let reuseIdentifier = "search-entry-section-header-reuse-identifier"

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

extension SearchEntrySectionHeaderView {
    private func configureViewHierarchy() {
        addSubview(label)

        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        let inset = CGFloat(16)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: inset),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -inset),
            label.topAnchor.constraint(equalTo: topAnchor, constant: inset),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -inset)
        ])

        let metrics = UIFontMetrics(forTextStyle: .title2)
        let desc = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .title2)
        let font = UIFont.systemFont(ofSize: desc.pointSize, weight: .bold)
        label.font = metrics.scaledFont(for: font)
    }
}
