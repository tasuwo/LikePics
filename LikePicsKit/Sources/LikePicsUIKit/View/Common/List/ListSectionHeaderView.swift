//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import UIKit

public struct ListSectionHeaderRightItem {
    let title: String
    let action: UIAction
    let font: UIFont?

    public init(title: String, action: UIAction, font: UIFont?) {
        self.title = title
        self.action = action
        self.font = font
    }
}

public class ListSectionHeaderView: UICollectionReusableView {
    private let label = UILabel()
    private let rightItemsStackView = UIStackView()
    private var rightItems: [ListSectionHeaderRightItem] = []

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

// MARK: - Methods

extension ListSectionHeaderView {
    public func setTitleTextStyle(_ style: UIFont.TextStyle) {
        let metrics = UIFontMetrics(forTextStyle: style)
        let desc = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style)
        let font = UIFont.systemFont(ofSize: desc.pointSize, weight: .bold)
        label.font = metrics.scaledFont(for: font)
    }

    public func setRightItems(_ items: [ListSectionHeaderRightItem]) {
        let buttons: [UIButton] = items.map {
            let button = UIButton(type: .system, primaryAction: $0.action)
            button.setTitle($0.title, for: .normal)

            button.titleLabel?.adjustsFontForContentSizeCategory = true
            button.titleLabel?.font = $0.font
            button.isPointerInteractionEnabled = true

            return button
        }

        rightItemsStackView.arrangedSubviews.forEach {
            rightItemsStackView.removeArrangedSubview($0)
            NSLayoutConstraint.deactivate($0.constraints)
            $0.removeFromSuperview()
        }
        buttons.forEach {
            rightItemsStackView.addArrangedSubview($0)
        }
    }
}

// MARK: - Configuration

extension ListSectionHeaderView {
    private func configureViewHierarchy() {
        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true

        let metrics = UIFontMetrics(forTextStyle: .title2)
        let desc = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .title2)
        let font = UIFont.systemFont(ofSize: desc.pointSize, weight: .bold)
        label.font = metrics.scaledFont(for: font)

        addSubview(rightItemsStackView)
        rightItemsStackView.alignment = .fill
        rightItemsStackView.axis = .horizontal
        rightItemsStackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: rightItemsStackView.leadingAnchor, constant: -16),
            label.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 16),
            label.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: 0),
            rightItemsStackView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -16),
            rightItemsStackView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 16),
            rightItemsStackView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: 0),
        ])
    }
}
