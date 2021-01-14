//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import UIKit

class ClipItemEditContentView: UIView, UIContentView {
    private var _configuration: ClipItemEditContentConfiguration!

    var configuration: UIContentConfiguration {
        get {
            _configuration
        }
        set {
            guard let configuration = newValue as? ClipItemEditContentConfiguration else { return }
            apply(configuration)
        }
    }

    @IBOutlet var baseView: UIView!
    @IBOutlet var thumbnailImageView: UIImageView!
    @IBOutlet var siteUrlTitleLabel: UILabel!
    @IBOutlet var siteUrlEditButton: UIButton!
    @IBOutlet var siteUrlButton: MultiLineButton!
    @IBOutlet var dataSizeTitleLabel: UILabel!
    @IBOutlet var dataSizeLabel: UILabel!

    // MARK: - Lifecycle

    init(configuration: ClipItemEditContentConfiguration) {
        super.init(frame: .zero)

        setupFromNib()
        setupAppearance()
        apply(configuration)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ClipItemEditContentView {
    private func setupFromNib() {
        Bundle(for: type(of: self)).loadNibNamed("ClipItemEditContentView", owner: self, options: nil)
        baseView.frame = self.bounds

        baseView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(baseView)
        NSLayoutConstraint.activate([
            baseView.topAnchor.constraint(equalTo: self.topAnchor),
            baseView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            baseView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            baseView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])
    }

    private func setupAppearance() {
        siteUrlEditButton.setTitle(L10n.clipItemEditContentViewSiteUrlEditTitle, for: .normal)
        siteUrlTitleLabel.text = L10n.clipItemEditContentViewSiteTitle
        dataSizeTitleLabel.text = L10n.clipItemEditContentViewSizeTitle
        dataSizeTitleLabel.numberOfLines = 0
    }
}

extension ClipItemEditContentView {
    private func apply(_ configuration: ClipItemEditContentConfiguration) {
        _configuration = configuration

        thumbnailImageView.image = configuration.thumbnail

        siteUrlButton.setTitle(configuration.siteUrl?.absoluteString, for: .normal)

        if let dataSize = configuration.dataSize {
            dataSizeLabel.text = ByteCountFormatter.string(fromByteCount: Int64(dataSize), countStyle: .binary)
        } else {
            dataSizeLabel.text = nil
        }

        let siteUrlEditAction = UIAction(identifier: .init("siteUrlEditAction"), handler: { [weak self] _ in
            guard let self = self,
                let text = self.siteUrlButton.titleLabel?.text,
                let url = URL(string: text)
            else {
                return
            }
            configuration.delegate?.didTapSiteUrl(url, sender: self)
        })
        siteUrlEditButton.removeAction(identifiedBy: .init("siteUrlEditAction"), for: .touchUpInside)
        siteUrlEditButton.addAction(siteUrlEditAction, for: .touchUpInside)

        let siteUrlTapAction = UIAction(identifier: .init("siteUrlTapAction"), handler: { [weak self] _ in
            guard let self = self,
                let text = self.siteUrlButton.titleLabel?.text,
                let url = URL(string: text)
            else {
                return
            }
            configuration.delegate?.didTapSiteUrlEditButton(url, sender: self)
        })
        siteUrlButton.removeAction(identifiedBy: .init("siteUrlTapAction"), for: .touchUpInside)
        siteUrlButton.addAction(siteUrlTapAction, for: .touchUpInside)
    }
}
