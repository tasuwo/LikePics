//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import UIKit

public class ClipSearchHistoryHeaderContentView: UIView, UIContentView {
    let label = UILabel()
    let removeAllButton = UIButton(type: .system)

    private var _configuration: ClipSearchHistoryHeaderConfiguration!
    public var configuration: UIContentConfiguration {
        get {
            _configuration
        }
        set {
            guard let configuration = newValue as? ClipSearchHistoryHeaderConfiguration else { return }
            apply(configuration)
        }
    }

    // MARK: - Initializers

    public init(configuration: ClipSearchHistoryHeaderConfiguration) {
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

extension ClipSearchHistoryHeaderContentView {
    private func configureViewHierarchy() {
        addSubview(label)

        label.text = L10n.searchHistorySectionTitle
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            label.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
        ])

        let metrics = UIFontMetrics(forTextStyle: .title2)
        let desc = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .title2)
        let font = UIFont.systemFont(ofSize: desc.pointSize, weight: .bold)
        label.font = metrics.scaledFont(for: font)

        addSubview(removeAllButton)
        removeAllButton.translatesAutoresizingMaskIntoConstraints = false
        removeAllButton.titleLabel?.font = .preferredFont(forTextStyle: .body)
        removeAllButton.titleLabel?.adjustsFontForContentSizeCategory = true
        removeAllButton.setTitle(L10n.searchEntryHeaderRemoveAll, for: .normal)
        NSLayoutConstraint.activate([
            removeAllButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            removeAllButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
        ])
    }

    private func apply(_ configuration: ClipSearchHistoryHeaderConfiguration) {
        removeAllButton.isEnabled = configuration.isRemoveAllButtonEnabled

        removeAllButton.removeAction(identifiedBy: .init("removeAllSearchHistory"), for: .touchUpInside)
        if configuration.isRemoveAllButtonEnabled {
            let action = UIAction(identifier: .init("removeAllSearchHistory")) { _ in
                configuration.removeAllHistoriesHandler?()
            }
            removeAllButton.addAction(action, for: .touchUpInside)
        }
    }
}
