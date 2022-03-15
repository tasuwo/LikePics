//
//  Copyright © 2022 Tasuku Tozawa. All rights reserved.
//

import UIKit

protocol FindViewTitleBarDelegate: AnyObject {
    func didTapTitleButton(_ view: FindViewTitleBar)
}

class FindViewTitleBar: UIView {
    var title: String? {
        get {
            titleLabel.text
        }
        set {
            titleLabel.text = newValue
            updateVisibility()
        }
    }

    var text: String? {
        get {
            searchField.text
        }
        set {
            searchField.text = newValue
        }
    }

    var isSearching = false {
        didSet {
            updateVisibility()
            if isSearching {
                searchField.becomeFirstResponder()
            } else {
                searchField.resignFirstResponder()
            }
        }
    }

    var textFieldDelegate: UITextFieldDelegate? {
        get {
            searchField.delegate
        }
        set {
            searchField.delegate = newValue
        }
    }

    @IBOutlet var baseView: UIView!
    @IBOutlet var titleLabelContainer: UIView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var searchField: UITextField!

    weak var delegate: FindViewTitleBarDelegate?

    // MARK: - Initializers

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupFromNib()
        setupAppearance()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - IBActions

    @IBAction func tapped(_ sender: Any) {
        self.delegate?.didTapTitleButton(self)
    }

    // MARK: - Methods

    private func setupFromNib() {
        UINib(nibName: String(describing: type(of: self)), bundle: Bundle.main).instantiate(withOwner: self, options: nil)
        baseView.frame = self.bounds

        baseView.translatesAutoresizingMaskIntoConstraints = true
        baseView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(baseView)
    }

    private func setupAppearance() {
        isSearching = false
    }

    private func updateVisibility() {
        searchField.isHidden = !isSearching
        titleLabelContainer.isHidden = isSearching || (titleLabel.text == nil || titleLabel.text?.isEmpty == true)
    }

    // MARK: - Override (UIView)

    override var intrinsicContentSize: CGSize {
        CGSize(width: 320, height: super.intrinsicContentSize.height)
    }
}
