//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public protocol ClipInformationCellDelegate: UIContextMenuInteractionDelegate {
    func clipInformationCell(_ cell: ClipInformationCell, didSwitchRightAccessory switch: UISwitch)
    func clipInformationCell(_ cell: ClipInformationCell, didTapBottomAccessory button: UIButton)
}

public class ClipInformationCell: UICollectionViewCell {
    public enum RightAccessoryType {
        case none
        case label(title: String)
        case `switch`(isEnabled: Bool)
    }

    public enum BottomAccessoryType {
        case none
        case button(title: String)
    }

    public static var nib: UINib {
        return UINib(nibName: "ClipInformationCell", bundle: Bundle(for: Self.self))
    }

    public var title: String? {
        get {
            self.titleLabel.text
        }
        set {
            self.titleLabel.text = newValue
        }
    }

    public var rightAccessoryType: RightAccessoryType = .none {
        didSet {
            self.updateAccessoryVisibility()
        }
    }

    public var bottomAccessoryType: BottomAccessoryType = .none {
        didSet {
            self.updateAccessoryVisibility()
        }
    }

    public var visibleSeparator: Bool {
        get {
            return !self.separator.isHidden
        }
        set {
            self.separator.isHidden = !newValue
        }
    }

    public weak var delegate: ClipInformationCellDelegate? {
        didSet {
            guard let delegate = self.delegate else { return }
            self.bottomAccessoryButton.addInteraction(UIContextMenuInteraction(delegate: delegate))
        }
    }

    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var rightAccessoryLabel: UILabel!
    @IBOutlet private var rightAccessoryButton: UISwitch!
    @IBOutlet private var bottomAccessoryButton: MultiLineButton!
    @IBOutlet private var separator: UIView!

    // MARK: - Lifecycle

    override public func awakeFromNib() {
        super.awakeFromNib()

        self.setupAppearance()
    }

    // MARK: - IBActions

    @IBAction func didSwitchRightAccessoryButton(_ sender: UISwitch) {
        self.delegate?.clipInformationCell(self, didSwitchRightAccessory: sender)
    }

    @IBAction func didTapBottomAccessoryButton(_ sender: UIButton) {
        self.delegate?.clipInformationCell(self, didTapBottomAccessory: sender)
    }

    // MARK: - Methods

    private func setupAppearance() {
        self.separator.backgroundColor = .separator

        [
            self.titleLabel,
            self.rightAccessoryLabel,
            self.bottomAccessoryButton.titleLabel
        ].forEach {
            $0?.adjustsFontForContentSizeCategory = true
            $0?.font = UIFont.preferredFont(forTextStyle: .body)
        }

        self.updateAccessoryVisibility()
    }

    private func updateAccessoryVisibility() {
        switch self.rightAccessoryType {
        case .none:
            self.rightAccessoryLabel.isHidden = true
            self.rightAccessoryButton.isHidden = true

        case let .label(title: title):
            self.rightAccessoryLabel.text = title
            self.rightAccessoryLabel.isHidden = false
            self.rightAccessoryButton.isHidden = true

        case let .switch(isEnabled: isEnabled):
            self.rightAccessoryButton.isOn = isEnabled
            self.rightAccessoryLabel.isHidden = true
            self.rightAccessoryButton.isHidden = false
        }

        switch self.bottomAccessoryType {
        case .none:
            self.bottomAccessoryButton.isHidden = true

        case let .button(title: title):
            self.bottomAccessoryButton.setTitle(title, for: .normal)
            self.bottomAccessoryButton.isHidden = false
        }
    }
}
