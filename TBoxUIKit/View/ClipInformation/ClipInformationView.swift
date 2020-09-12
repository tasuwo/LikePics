//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit
import WebKit

public protocol ClipInformationViewDelegate: AnyObject {
    func clipInformationView(_ view: ClipInformationView, didSelectTag name: String)
    func clipInformationView(_ view: ClipInformationView, shouldOpen url: URL)
    func clipInformationView(_ view: ClipInformationView, shouldCopy url: URL)
    func clipInformationView(_ view: ClipInformationView, shouldSearch url: URL)
}

public class ClipInformationView: UIView {
    public var tags: [String] = [] {
        didSet {
            self.tagCollectionView.reloadData()
        }
    }

    public var siteUrl: String? {
        get {
            return self.siteUrlButton.titleLabel?.text
        }
        set {
            self.siteUrlButton.setTitle(newValue, for: .normal)
        }
    }

    public var imageUrl: String? {
        get {
            return self.imageUrlButton.titleLabel?.text
        }
        set {
            self.imageUrlButton.setTitle(newValue, for: .normal)
        }
    }

    public weak var delegate: ClipInformationViewDelegate?

    @IBOutlet var baseView: UIView!
    @IBOutlet var tagTitleLabel: UILabel!
    @IBOutlet var tagCollectionView: TagCollectionView!
    @IBOutlet var siteUrlButton: UIButton!
    @IBOutlet var imageUrlButton: UIButton!
    @IBOutlet var siteUrlTitleLabel: UILabel!
    @IBOutlet var imageUrlTitleLabel: UILabel!

    // MARK: - Lifecycle

    override public init(frame: CGRect) {
        super.init(frame: frame)

        self.setupFromNib()
        self.setupAppearance()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)

        self.setupFromNib()
        self.setupAppearance()
    }

    @IBAction func didTapSiteUrl(_ sender: UIButton) {
        guard let text = sender.titleLabel?.text, let url = URL(string: text) else { return }
        self.delegate?.clipInformationView(self, shouldOpen: url)
    }

    @IBAction func didTapImageUrl(_ sender: UIButton) {
        guard let text = sender.titleLabel?.text, let url = URL(string: text) else { return }
        self.delegate?.clipInformationView(self, shouldOpen: url)
    }

    // MARK: - Methods

    private func setupFromNib() {
        Bundle(for: type(of: self)).loadNibNamed("ClipInformationView", owner: self, options: nil)
        self.baseView.frame = self.bounds
        self.addSubview(self.baseView)
        self.sendSubviewToBack(self.baseView)
    }

    private func setupAppearance() {
        // TODO: Localize
        self.siteUrlTitleLabel.text = "サイトのURL"
        self.imageUrlTitleLabel.text = "画像のURL"

        self.siteUrlButton.addInteraction(UIContextMenuInteraction(delegate: self))
        self.imageUrlButton.addInteraction(UIContextMenuInteraction(delegate: self))
    }
}

extension ClipInformationView: UICollectionViewDelegate {
    // MARK: - UICollectionViewDelegate

    public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    public func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard self.tags.indices.contains(indexPath.row) else { return }
        self.delegate?.clipInformationView(self, didSelectTag: self.tags[indexPath.row])
    }
}

extension ClipInformationView: UICollectionViewDataSource {
    // MARK: - UICollectionViewDataSource

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.tags.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let dequeuedCell = collectionView.dequeueReusableCell(withReuseIdentifier: TagCollectionView.cellIdentifier, for: indexPath)
        guard let cell = dequeuedCell as? TagCollectionViewCell else { return dequeuedCell }
        guard self.tags.indices.contains(indexPath.row) else { return dequeuedCell }

        cell.title = self.tags[indexPath.row]

        return cell
    }
}

extension ClipInformationView: UICollectionViewDelegateFlowLayout {
    // MARK: - UICollectionViewDelegateFlowLayout

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard self.tags.indices.contains(indexPath.row) else { return .zero }
        let preferredSize = TagCollectionViewCell.preferredSize(for: self.tags[indexPath.row])
        return CGSize(width: fmin(preferredSize.width, collectionView.frame.width - 16 * 2), height: preferredSize.height)
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .init(top: 16, left: 16, bottom: 16, right: 16)
    }
}

extension ClipInformationView: UIContextMenuInteractionDelegate {
    // MARK: - UIContextMenuInteractionDelegate

    public func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        guard let button = interaction.view as? UIButton,
            let text = button.titleLabel?.text,
            let url = URL(string: text)
        else {
            return nil
        }
        return UIContextMenuConfiguration(identifier: nil,
                                          previewProvider: self.makePreviewProvider(for: url),
                                          actionProvider: self.makeActionProvider(for: url))
    }

    private func makePreviewProvider(for url: URL) -> (() -> UIViewController) {
        let viewController = UIViewController()

        let webView = WKWebView(frame: .zero)
        viewController.view = webView
        webView.load(URLRequest(url: url))

        return { viewController }
    }

    private func makeActionProvider(for url: URL) -> UIContextMenuActionProvider {
        // TODO: Localize
        let open = UIAction(title: "Open", image: UIImage(systemName: "square.and.arrow.up.fill")) { action in
            self.delegate?.clipInformationView(self, shouldOpen: url)
        }
        let copy = UIAction(title: "Copy", image: UIImage(systemName: "square.on.square.fill")) { action in
            self.delegate?.clipInformationView(self, shouldCopy: url)
        }
        let search = UIAction(title: "Search", image: UIImage(systemName: "magnifyingglass")) { action in
            self.delegate?.clipInformationView(self, shouldSearch: url)
        }
        return { _ in UIMenu(title: "", children: [open, copy, search]) }
    }
}
