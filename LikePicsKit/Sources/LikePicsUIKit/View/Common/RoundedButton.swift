//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public class RoundedButton: UIControl {
    private enum DisplayState {
        case disabled
        case enabled
        case enabledHighlighted
    }

    private let titleLabel = UILabel()

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

    public var title: String {
        get {
            titleLabel.text ?? ""
        }
        set {
            titleLabel.text = newValue
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

    // MARK: - Methods

    private func configureViewHierarchy() {
        isAccessibilityElement = true

        layer.cornerRadius = 12
        layer.cornerCurve = .continuous
        clipsToBounds = true

        titleLabel.isUserInteractionEnabled = false
        titleLabel.textAlignment = .center

        let metrics = UIFontMetrics(forTextStyle: .caption1)
        let desc = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .caption1)
        let font = UIFont.systemFont(ofSize: desc.pointSize, weight: .heavy)
        titleLabel.font = metrics.scaledFont(for: font, maximumPointSize: 14)
        titleLabel.adjustsFontForContentSizeCategory = true

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 5).isActive = true
        titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5).isActive = true
        titleLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 12).isActive = true
        titleLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -12).isActive = true

        updateAppearance()
        updateAccessibilityInfo()

        addInteraction(UIPointerInteraction(delegate: self))
    }

    private func updateAppearance() {
        switch displayState {
        case .disabled:
            titleLabel.textColor = .white
            backgroundColor = .systemGray

        case .enabled:
            titleLabel.textColor = .white
            backgroundColor = Asset.Color.likePicsRed.color

        case .enabledHighlighted:
            titleLabel.textColor = .white.withAlphaComponent(0.8)
            backgroundColor = Asset.Color.likePicsRed.color.withAlphaComponent(0.8)
        }
    }

    private func updateAccessibilityInfo() {
        var newTraits = UIAccessibilityTraits.button
        if !isEnabled {
            newTraits.insert(.notEnabled)
        }
        accessibilityTraits = newTraits
        accessibilityLabel = title
    }
}

extension RoundedButton: UIPointerInteractionDelegate {
    public func pointerInteraction(_ interaction: UIPointerInteraction, regionFor request: UIPointerRegionRequest, defaultRegion: UIPointerRegion) -> UIPointerRegion? {
        return UIPointerRegion(rect: bounds)
    }

    public func pointerInteraction(_ interaction: UIPointerInteraction, styleFor region: UIPointerRegion) -> UIPointerStyle? {
        return UIPointerStyle(effect: .highlight(UITargetedPreview(view: self)),
                              shape: .roundedRect(frame, radius: 12))
    }
}
