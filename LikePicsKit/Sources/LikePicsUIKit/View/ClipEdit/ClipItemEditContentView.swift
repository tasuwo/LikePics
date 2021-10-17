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

    @IBOutlet var thumbnailWidthConstraint: NSLayoutConstraint!
    @IBOutlet var thumbnailHeightConstraint: NSLayoutConstraint!

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
        Bundle.module.loadNibNamed("ClipItemEditContentView", owner: self, options: nil)
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
        siteUrlEditButton.titleLabel?.adjustsFontForContentSizeCategory = true
        siteUrlEditButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)

        siteUrlTitleLabel.text = L10n.clipItemEditContentViewSiteTitle

        siteUrlButton.titleLabel?.adjustsFontForContentSizeCategory = true
        siteUrlButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .callout)

        dataSizeTitleLabel.text = L10n.clipItemEditContentViewSizeTitle
        dataSizeTitleLabel.numberOfLines = 0

        thumbnailImageView.contentMode = .scaleAspectFill
        thumbnailImageView.layer.cornerRadius = 8
        thumbnailImageView.layer.cornerCurve = .continuous
    }
}

extension ClipItemEditContentView {
    private func apply(_ configuration: ClipItemEditContentConfiguration) {
        _configuration = configuration

        thumbnailImageView.image = configuration.thumbnail

        siteUrlButton.interactions.forEach { interaction in
            guard interaction is UIContextMenuInteraction else { return }
            siteUrlButton.removeInteraction(interaction)
        }
        if let delegate = configuration.interactionDelegate {
            siteUrlButton.addInteraction(UIContextMenuInteraction(delegate: delegate))
        }

        if let siteUrl = configuration.siteUrl {
            siteUrlButton.isEnabled = true
            siteUrlButton.setTitle(siteUrl.absoluteString, for: .normal)
            siteUrlButton.setTitle(siteUrl.absoluteString, for: .disabled)
        } else {
            siteUrlButton.isEnabled = false
            siteUrlButton.setTitle(L10n.clipItemEditContentViewSiteUrlEmpty, for: .normal)
            siteUrlButton.setTitle(L10n.clipItemEditContentViewSiteUrlEmpty, for: .disabled)
        }
        siteUrlEditButton.isHidden = !configuration.isSiteUrlEditable

        siteUrlButton.isEnabled = configuration.siteUrlDisabledForce ? false : siteUrlButton.isEnabled
        siteUrlEditButton.isHidden = configuration.siteUrlDisabledForce ? true : siteUrlEditButton.isHidden

        if let dataSize = configuration.dataSize {
            dataSizeLabel.text = ByteCountFormatter.string(fromByteCount: Int64(dataSize), countStyle: .binary)
        } else {
            dataSizeLabel.text = nil
        }

        if let width = configuration.imageWidth, let height = configuration.imageHeight {
            thumbnailHeightConstraint.constant = thumbnailWidthConstraint.constant * CGFloat(height) / CGFloat(width)
        } else {
            thumbnailHeightConstraint.constant = thumbnailWidthConstraint.constant * 4 / 3
        }

        let siteUrlEditAction = UIAction(identifier: .init("siteUrlEditAction"), handler: { [weak self] _ in
            guard let self = self, let text = self.siteUrlButton.titleLabel?.text else { return }
            configuration.delegate?.didTapSiteUrlEditButton(URL(string: text), sender: self)
        })
        siteUrlEditButton.removeAction(identifiedBy: .init("siteUrlEditAction"), for: .touchUpInside)
        siteUrlEditButton.addAction(siteUrlEditAction, for: .touchUpInside)

        let siteUrlTapAction = UIAction(identifier: .init("siteUrlTapAction"), handler: { [weak self] _ in
            guard let self = self, let text = self.siteUrlButton.titleLabel?.text else { return }
            configuration.delegate?.didTapSiteUrl(URL(string: text), sender: self)
        })
        siteUrlButton.removeAction(identifiedBy: .init("siteUrlTapAction"), for: .touchUpInside)
        siteUrlButton.addAction(siteUrlTapAction, for: .touchUpInside)
    }
}
