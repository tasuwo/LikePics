//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public protocol ListCellDelegate: AnyObject {
    func listCell(_ cell: ListCell, didSwitchRightAccessory switch: UISwitch)
    func listCell(_ cell: ListCell, didTapRightAccessory button: UIButton)
    func listCell(_ cell: ListCell, didTapBottomAccessory button: UIButton)
}

public class ListCell: UICollectionViewCell {
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
        return UINib(nibName: "ListCell", bundle: Bundle.module)
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

    public weak var delegate: ListCellDelegate?
    public weak var interactionDelegate: UIContextMenuInteractionDelegate? {
        didSet {
            bottomAccessoryButton.interactions.forEach { interaction in
                guard interaction is UIContextMenuInteraction else { return }
                bottomAccessoryButton.removeInteraction(interaction)
            }
            if let delegate = interactionDelegate {
                bottomAccessoryButton.addInteraction(UIContextMenuInteraction(delegate: delegate))
            }
        }
    }

    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var rightAccessoryLabel: UILabel!
    @IBOutlet private var rightAccessoryButton: UIButton!
    @IBOutlet private var rightAccessorySwitch: UISwitch!
    @IBOutlet private var bottomAccessoryButton: MultiLineButton!
    @IBOutlet private var bottomAccessoryLabel: UILabel!

    // MARK: - Lifecycle

    override public func awakeFromNib() {
        super.awakeFromNib()

        self.setupAppearance()
    }

    // MARK: - IBActions

    @IBAction func didChangeRightAccessorySwitch(_ sender: UISwitch) {
        self.delegate?.listCell(self, didSwitchRightAccessory: sender)
    }

    @IBAction func didTapRightAccessoryButton(_ sender: UIButton) {
        self.delegate?.listCell(self, didTapRightAccessory: sender)
    }

    @IBAction func didTapBottomAccessoryButton(_ sender: UIButton) {
        self.delegate?.listCell(self, didTapBottomAccessory: sender)
    }

    // MARK: - Methods

    public func setFont(_ font: UIFont) {
        [
            self.titleLabel,
            self.rightAccessoryLabel,
            self.rightAccessoryButton.titleLabel,
            self.bottomAccessoryButton.titleLabel,
            self.bottomAccessoryLabel,
        ].forEach {
            $0?.adjustsFontForContentSizeCategory = true
            $0?.font = font
        }
    }

    private func setupAppearance() {
        [
            self.titleLabel,
            self.rightAccessoryLabel,
            self.rightAccessoryButton.titleLabel,
            self.bottomAccessoryButton.titleLabel,
            self.bottomAccessoryLabel,
        ].forEach {
            $0?.adjustsFontForContentSizeCategory = true
            $0?.font = UIFont.preferredFont(forTextStyle: .body)
        }

        self.updateAccessoryVisibility()

        rightAccessoryButton.isPointerInteractionEnabled = true
        bottomAccessoryButton.isPointerInteractionEnabled = true
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
