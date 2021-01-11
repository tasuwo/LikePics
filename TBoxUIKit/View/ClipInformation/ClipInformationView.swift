//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import UIKit
import WebKit

public class ClipInformationView: UIView {
    public typealias Factory = ClipInformationLayout

    public static let topImageHeight: CGFloat = 80

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

    var imageView: UIImageView!
    private var collectionViewDataSource: Factory.DataSource!

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

        // HACK: 複数行あるセルの描画が少しずれるため、再描画をかける
        self.collectionView.layoutIfNeeded()
    }

    // MARK: - Methods

    /// - attention: 同一スレッドからのみセットする必要がある
    public func setInfo(_ info: Factory.Information, animated: Bool) {
        let snapshot = Factory.makeSnapshot(for: info)
        self.collectionViewDataSource.apply(snapshot, animatingDifferences: animated)
    }

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
        self.collectionView.contentInset = .init(top: Self.topImageHeight, left: 0, bottom: 0, right: 0)
        self.collectionView.layoutMargins = .init(top: 0, left: 18, bottom: 0, right: 18)
        Factory.registerCells(to: self.collectionView)
        self.collectionView.delegate = self
        self.collectionViewDataSource = Factory.makeDataSource(for: self.collectionView,
                                                               infoCellDelegate: self,
                                                               tagCellDelegate: self,
                                                               sectionHeaderDelegate: self)
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
        let scale = ClipPreviewView.calcScaleScaleToFit(forSize: image.size, fittingIn: bounds.size)
        let resizedImageSize = image.size.scaled(by: scale)
        return CGRect(origin: .init(x: (frame.size.width - resizedImageSize.width) / 2,
                                    y: -resizedImageSize.height + self.safeAreaInsets.top + Self.topImageHeight),
                      size: resizedImageSize)
    }
}

extension ClipInformationView: UICollectionViewDelegate {
    // MARK: - UICollectionViewDelegate

    public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    public func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return false
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

extension ClipInformationView: ListSectionHeaderDelegate {
    // MARK: - ListSectionHeaderDelegate

    public func didTapAdd(_ header: ListSectionHeader) {
        guard let identifier = header.identifier,
            let number = Int(identifier),
            let section = Factory.Section(rawValue: number),
            case .tag = section
        else {
            return
        }
        self.delegate?.didTapAddTagButton(self)
    }
}

extension ClipInformationView: TagCollectionViewCellDelegate {
    // MARK: - TagCollectionViewCellDelegate

    public func didTapDeleteButton(_ cell: TagCollectionViewCell) {
        guard let indexPath = self.collectionView.indexPath(for: cell),
            let item = self.collectionViewDataSource.itemIdentifier(for: indexPath) else { return }
        switch item {
        case let .tag(value):
            guard let cell = collectionView.cellForItem(at: indexPath) else { return }
            self.delegate?.clipInformationView(self, didSelectTag: value, at: cell)

        case .row, .empty:
            break
        }
    }
}

extension ClipInformationView: ListCellDelegate {
    // MARK: - ListCellDelegate

    public func listCell(_ cell: ListCell, didTapBottomAccessory button: UIButton) {
        guard case let .button(title: title) = cell.bottomAccessoryType, let url = URL(string: title) else { return }
        self.delegate?.clipInformationView(self, shouldOpen: url)
    }

    public func listCell(_ cell: ListCell, didTapRightAccessory button: UIButton) {
        let url: URL? = {
            if case let .button(title: title) = cell.bottomAccessoryType, let url = URL(string: title) {
                return url
            } else {
                return nil
            }
        }()
        self.delegate?.clipInformationView(self, startEditingSiteUrl: url)
    }

    public func listCell(_ cell: ListCell, didSwitchRightAccessory switch: UISwitch) {
        self.delegate?.clipInformationView(self, shouldHide: `switch`.isOn)
    }
}

private extension CGSize {
    func scaled(by scale: CGFloat) -> Self {
        return .init(width: self.width * scale, height: self.height * scale)
    }
}
