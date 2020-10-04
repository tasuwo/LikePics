//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import UIKit
import WebKit

public class ClipInformationView: UIView {
    public typealias Factory = ClipInformationLayoutFactory

    public var info: Factory.Information? {
        didSet {
            guard let info = self.info else { return }
            let snapshot = Factory.makeSnapshot(for: info)
            DispatchQueue.global(qos: .background).async {
                self.collectionViewDataSource.apply(snapshot, animatingDifferences: true)
            }
        }
    }

    public var panGestureRecognizer: UIPanGestureRecognizer {
        self.collectionView.panGestureRecognizer
    }

    public var contentOffSet: CGPoint {
        self.collectionView.contentOffset
    }

    public var isScrollEnabled: Bool {
        get {
            return self.collectionView.isScrollEnabled
        }
        set {
            self.collectionView.isScrollEnabled = newValue
        }
    }

    public weak var delegate: ClipInformationViewDelegate?

    public weak var dataSource: ClipInformationViewDataSource? {
        didSet {
            self.imageView.image = self.dataSource?.previewImage(self)
            self.updateImageViewFrame()
        }
    }

    // swiftlint:disable implicitly_unwrapped_optional superfluous_disable_command
    var imageView: UIImageView!
    private var collectionViewDataSource: Factory.DataSource!
    // swiftlint:enable implicitly_unwrapped_optional superfluous_disable_command

    @IBOutlet var baseView: UIView!
    @IBOutlet var collectionView: UICollectionView!

    // MARK: - Lifecycle

    override public init(frame: CGRect) {
        super.init(frame: frame)

        self.setupFromNib()
        self.setupAppearance()
        self.setupCollectionView()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)

        self.setupFromNib()
        self.setupAppearance()
        self.setupCollectionView()
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        self.updateImageViewFrame()
    }

    // MARK: - Methods

    private func setupFromNib() {
        Bundle(for: type(of: self)).loadNibNamed("ClipInformationView", owner: self, options: nil)
        self.baseView.frame = self.bounds
        self.addSubview(self.baseView)
        self.sendSubviewToBack(self.baseView)
    }

    private func setupAppearance() {
        self.imageView = UIImageView(frame: .init(origin: .zero, size: .zero))
        self.imageView.contentMode = .scaleAspectFit
        self.baseView.addSubview(self.imageView)
    }

    // MARK: Collection View

    private func setupCollectionView() {
        self.collectionView.collectionViewLayout = Factory.createLayout()
        Factory.registerCells(to: self.collectionView)
        self.collectionView.delegate = self
        self.collectionViewDataSource = Factory.makeDataSource(
            for: self.collectionView,
            configureUrlLink: { [weak self] button in
                guard let self = self else { return }
                button.addTarget(self, action: #selector(self.didTapUrl(_:)), for: .touchUpInside)
                button.addInteraction(UIContextMenuInteraction(delegate: self))
            },
            delegate: self
        )
    }

    @objc
    func didTapUrl(_ sender: UIButton) {
        guard let text = sender.titleLabel?.text, let url = URL(string: text) else { return }
        self.delegate?.clipInformationView(self, shouldOpen: url)
    }

    // MARK: Image View

    private func updateImageViewFrame() {
        self.imageView.frame = self.calcInitialFrame()
    }

    public func calcInitialFrame() -> CGRect {
        guard let dataSource = self.dataSource, let image = dataSource.previewImage(self) else {
            return .zero
        }
        let bounds = dataSource.previewPageBounds(self)
        let scale = ClipPreviewView.calcScaleToFit(image, on: bounds.size)
        let resizedImageSize = image.size.scaled(by: scale)
        return CGRect(origin: .init(x: (frame.size.width - resizedImageSize.width) / 2,
                                    y: -resizedImageSize.height + self.safeAreaInsets.top + 80),
                      size: resizedImageSize)
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
        guard let item = self.collectionViewDataSource.itemIdentifier(for: indexPath) else { return }
        switch item {
        case let .tag(value):
            self.delegate?.clipInformationView(self, didSelectTag: value.name)

        case .row, .empty:
            break
        }
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
        let open = UIAction(title: L10n.clipInformationViewContextMenuOpen, image: UIImage(systemName: "square.and.arrow.up.fill")) { _ in
            self.delegate?.clipInformationView(self, shouldOpen: url)
        }
        let copy = UIAction(title: L10n.clipInformationViewContextMenuCopy, image: UIImage(systemName: "square.on.square.fill")) { _ in
            self.delegate?.clipInformationView(self, shouldCopy: url)
        }
        return { _ in UIMenu(title: "", children: [open, copy]) }
    }
}

extension ClipInformationView: ClipInformationSectionHeaderDelegate {
    // MARK: - ClipInformationSectionHeaderDelegate

    public func didTapAdd(_ header: ClipInformationSectionHeader) {
        guard let identifier = header.identifier,
            let number = Int(identifier),
            let section = Factory.Section(rawValue: number),
            case .clipTag = section
        else {
            return
        }
        self.delegate?.didTapAddTagButton(self)
    }
}

private extension CGSize {
    func scaled(by scale: CGFloat) -> Self {
        return .init(width: self.width * scale, height: self.height * scale)
    }
}
