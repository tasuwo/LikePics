//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import UIKit

public class ListSectionHeaderContentView: UICollectionReusableView, UIContentView {
    let label = UILabel()

    private var _configuration: ListSectionHeaderConfiguration!
    public var configuration: UIContentConfiguration {
        get {
            _configuration
        }
        set {
            guard let configuration = newValue as? ListSectionHeaderConfiguration else { return }
            apply(configuration)
        }
    }

    // MARK: - Initializers

    public init(configuration: ListSectionHeaderConfiguration) {
        self._configuration = configuration
        super.init(frame: .zero)
        configureViewHierarchy()
        apply(configuration)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ListSectionHeaderContentView {
    private func configureViewHierarchy() {
        addSubview(label)

        label.text = _configuration.title
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            label.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])

        let metrics = UIFontMetrics(forTextStyle: .title2)
        let desc = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .title2)
        let font = UIFont.systemFont(ofSize: desc.pointSize, weight: .bold)
        label.font = metrics.scaledFont(for: font)
    }

    private func apply(_ configuration: ListSectionHeaderConfiguration) {
        label.text = configuration.title
    }
}
