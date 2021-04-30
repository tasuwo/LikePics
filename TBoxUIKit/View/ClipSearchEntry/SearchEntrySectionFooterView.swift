//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import UIKit

public class SearchEntrySectionFooterView: UICollectionReusableView {
    public static let reuseIdentifier = "search-entry-section-footer-reuse-identifier"

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

extension SearchEntrySectionFooterView {
    private func configureViewHierarchy() {
        addSubview(label)

        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            label.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])

        label.font = .preferredFont(forTextStyle: .caption1)
        label.numberOfLines = 0
        label.textColor = .secondaryLabel
    }
}
