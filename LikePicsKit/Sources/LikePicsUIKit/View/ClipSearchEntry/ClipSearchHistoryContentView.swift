//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import UIKit

class ClipSearchHistoryContentView: UIView, UIContentView {
    private var _configuration: ClipSearchHistoryContentConfiguration!
    var configuration: UIContentConfiguration {
        get {
            _configuration
        }
        set {
            guard let configuration = newValue as? ClipSearchHistoryContentConfiguration else { return }
            apply(configuration)
        }
    }

    @IBOutlet var baseView: UIView!
    @IBOutlet var separatorView: UIView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var secondaryTitleLabel: UILabel!

    // MARK: - Initializers

    init(configuration: ClipSearchHistoryContentConfiguration) {
        super.init(frame: .zero)

        setupFromNib()
        apply(configuration)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ClipSearchHistoryContentView {
    private func setupFromNib() {
        Bundle.module.loadNibNamed("ClipSearchHistoryContentView", owner: self, options: nil)
        baseView.frame = self.bounds
        baseView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(baseView)
        NSLayoutConstraint.activate(baseView.constraints(fittingIn: self))
    }
}

extension ClipSearchHistoryContentView {
    private func apply(_ configuration: ClipSearchHistoryContentConfiguration) {
        _configuration = configuration

        guard let history = configuration.clipSearchHistory else {
            titleLabel.text = nil
            secondaryTitleLabel.text = nil
            return
        }

        titleLabel.text = history.title
        secondaryTitleLabel.text = [
            history.isDisplaySettingHidden ? nil : history.displaySettingName,
            history.sortName,
        ].compactMap { $0 }.joined(separator: " / ")
    }
}
