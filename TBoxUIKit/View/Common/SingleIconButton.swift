//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import UIKit

public class SingleIconButton: UIControl {
    public enum Icon {
        case ellipsis
        case offgrid
        case grid

        var image: UIImage {
            switch self {
            case .ellipsis:
                // swiftlint:disable:next force_unwrapping
                return UIImage(systemName: "ellipsis")!.withRenderingMode(.alwaysTemplate)

            case .offgrid:
                // swiftlint:disable:next force_unwrapping
                return UIImage(systemName: "rectangle.3.offgrid")!.withRenderingMode(.alwaysTemplate)

            case .grid:
                // swiftlint:disable:next force_unwrapping
                return UIImage(systemName: "square.grid.2x2")!.withRenderingMode(.alwaysTemplate)
            }
        }
    }

    private enum DisplayState {
        case disabled
        case enabled
        case enabledHighlighted
    }

    private let iconView = UIImageView()

    private var displayState: DisplayState {
        if isEnabled {
            if isHighlighted {
                return .enabledHighlighted
            } else {
                return .enabled
            }
        } else {
            return .disabled
        }
    }

    override public var isHighlighted: Bool {
        didSet {
            updateAppearance()
            updateAccessibilityInfo()
        }
    }

    override public var isEnabled: Bool {
        didSet {
            updateAppearance()
            updateAccessibilityInfo()
        }
    }

    // MARK: - Initializers

    override public init(frame: CGRect) {
        super.init(frame: frame)
        configureViewHierarchy()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureViewHierarchy()
    }

    // MARK: - UIView (Overrides)

    override public func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.size.width / 2.0
    }

    // MARK: - Methods

    public func setIcon(_ icon: Icon) {
        iconView.image = icon.image
    }

    private func configureViewHierarchy() {
        isAccessibilityElement = true

        layer.cornerRadius = bounds.size.width / 2.0
        clipsToBounds = true

        iconView.isUserInteractionEnabled = false
        iconView.contentMode = .scaleAspectFit

        iconView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconView)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalTo: heightAnchor),
            heightAnchor.constraint(equalToConstant: 24),
            iconView.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            iconView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            iconView.leftAnchor.constraint(equalTo: leftAnchor, constant: 4),
            iconView.rightAnchor.constraint(equalTo: rightAnchor, constant: -4)
        ])

        updateAppearance()
        updateAccessibilityInfo()
    }

    private func updateAppearance() {
        switch displayState {
        case .disabled:
            iconView.tintColor = .white
            backgroundColor = .systemGray

        case .enabled:
            iconView.tintColor = .white
            backgroundColor = Asset.Color.likePicsRed.color

        case .enabledHighlighted:
            iconView.tintColor = .white.withAlphaComponent(0.8)
            backgroundColor = Asset.Color.likePicsRed.color.withAlphaComponent(0.8)
        }
    }

    private func updateAccessibilityInfo() {
        var newTraits = UIAccessibilityTraits.button
        if !isEnabled {
            newTraits.insert(.notEnabled)
        }
        accessibilityTraits = newTraits
    }
}
