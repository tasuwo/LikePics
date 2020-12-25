//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public protocol ClipInformationCellDelegate: UIContextMenuInteractionDelegate {
    func clipInformationCell(_ cell: ClipInformationCell, didSwitchRightAccessory switch: UISwitch)
    func clipInformationCell(_ cell: ClipInformationCell, didTapRightAccessory button: UIButton)
    func clipInformationCell(_ cell: ClipInformationCell, didTapBottomAccessory button: UIButton)
}

public class ClipInformationCell: UICollectionViewCell {
    public enum RightAccessoryType {
        case label(title: String)
        case button(title: String)
        case `switch`(isOn: Bool)
    }

    public enum BottomAccessoryType {
        case button(title: String)
        case label(title: String)
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

    public var rightAccessoryType: RightAccessoryType? {
        didSet {
            self.updateAccessoryVisibility()
        }
    }

    public var bottomAccessoryType: BottomAccessoryType? {
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
    @IBOutlet private var rightAccessoryButton: UIButton!
    @IBOutlet private var rightAccessorySwitch: UISwitch!
    @IBOutlet private var bottomAccessoryButton: MultiLineButton!
    @IBOutlet private var bottomAccessoryLabel: UILabel!
    @IBOutlet private var separator: UIView!

    // MARK: - Lifecycle

    override public func awakeFromNib() {
        super.awakeFromNib()

        self.setupAppearance()
    }

    // MARK: - IBActions

    @IBAction func didChangeRightAccessorySwitch(_ sender: UISwitch) {
        self.delegate?.clipInformationCell(self, didSwitchRightAccessory: sender)
    }

    @IBAction func didTapRightAccessoryButton(_ sender: UIButton) {
        self.delegate?.clipInformationCell(self, didTapRightAccessory: sender)
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
            self.rightAccessoryButton.titleLabel,
            self.bottomAccessoryButton.titleLabel,
            self.bottomAccessoryLabel
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
            self.rightAccessorySwitch.isHidden = true

        case let .label(title: title):
            self.rightAccessoryLabel.text = title
            self.rightAccessoryLabel.isHidden = false
            self.rightAccessoryButton.isHidden = true
            self.rightAccessorySwitch.isHidden = true

        case let .button(title: title):
            UIView.setAnimationsEnabled(false)
            self.rightAccessoryButton.setTitle(title, for: .normal)
            self.rightAccessoryButton.layoutIfNeeded()
            UIView.setAnimationsEnabled(true)
            self.rightAccessoryLabel.isHidden = true
            self.rightAccessoryButton.isHidden = false
            self.rightAccessorySwitch.isHidden = true

        case let .switch(isOn: isOn):
            self.rightAccessorySwitch.isOn = isOn
            self.rightAccessoryLabel.isHidden = true
            self.rightAccessoryButton.isHidden = true
            self.rightAccessorySwitch.isHidden = false
        }

        switch self.bottomAccessoryType {
        case .none:
            self.bottomAccessoryButton.isHidden = true
            self.bottomAccessoryLabel.isHidden = true

        case let .button(title: title):
            UIView.setAnimationsEnabled(false)
            self.bottomAccessoryButton.setTitle(title, for: .normal)
            self.bottomAccessoryButton.layoutIfNeeded()
            UIView.setAnimationsEnabled(true)
            self.bottomAccessoryButton.isHidden = false
            self.bottomAccessoryLabel.isHidden = true

        case let .label(title: title):
            self.bottomAccessoryLabel.text = title
            self.bottomAccessoryButton.isHidden = true
            self.bottomAccessoryLabel.isHidden = false
        }
    }
}
