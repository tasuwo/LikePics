//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import Smoothie
import UIKit

public protocol AlbumListCollectionViewCellDelegate: AnyObject {
    func didTapTitleEditButton(_ cell: AlbumListCollectionViewCell)
    func didTapRemover(_ cell: AlbumListCollectionViewCell)
}

public class AlbumListCollectionViewCell: UICollectionViewCell {
    public static var nib: UINib {
        return UINib(nibName: "AlbumListCollectionViewCell", bundle: Bundle(for: Self.self))
    }

    public var identifier: String?

    public var albumId: Album.Identity?

    public var thumbnail: UIImage? {
        get {
            self.thumbnailImageView.image
        }
        set {
            self.thumbnailImageView.image = newValue
        }
    }

    public var title: String? {
        get {
            return self.titleButton.title(for: .normal)
        }
        set {
            self.titleButton.setTitle(newValue, for: .normal)
        }
    }

    public var clipCount: Int? {
        didSet {
            if let count = self.clipCount {
                self.metaLabel.text = L10n.albumListCollectionViewCellCount(count)
                self.metaLabel.isHidden = false
            } else {
                self.metaLabel.text = nil
                self.metaLabel.isHidden = true
            }
        }
    }

    public private(set) var visibleHiddenIcon: Bool = false
    public private(set) var isHiddenAlbum: Bool = false

    public private(set) var isEditing: Bool = false
    private var isDragging: Bool = false

    public var onReuse: ((String?) -> Void)?

    public weak var delegate: AlbumListCollectionViewCellDelegate?

    @IBOutlet var thumbnailImageView: UIImageView!
    @IBOutlet var titleButton: UIButton!
    @IBOutlet var metaLabel: UILabel!
    @IBOutlet var titleEditButton: UIButton!
    @IBOutlet var titleEditButtonContainer: UIView!
    @IBOutlet var titleEditButtonRowStackView: UIStackView!
    @IBOutlet var removerButton: UIButton!
    @IBOutlet var removerContainer: UIView!
    @IBOutlet var hiddenIcon: HiddenIconView!

    // MARK: - Lifecycle

    override public func awakeFromNib() {
        super.awakeFromNib()
        self.setupAppearance()
    }

    override public func prepareForReuse() {
        super.prepareForReuse()
        self.onReuse?(self.identifier)
    }

    override public func dragStateDidChange(_ dragState: UICollectionViewCell.DragState) {
        switch dragState {
        case .lifting, .dragging:
            self.isDragging = true
            guard self.isEditing else { return }
            self.updateAppearance(isEditing: false)

        case .none:
            self.isDragging = false
            guard self.isEditing else { return }
            self.updateAppearance(isEditing: true)

        @unknown default:
            break
        }
    }

    override public func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let pointForRemover = removerContainer.convert(point, from: self)
        if removerContainer.bounds.contains(pointForRemover) {
            return removerContainer.hitTest(pointForRemover, with: event)
        }
        return super.hitTest(point, with: event)
    }

    // MARK: - IBAction

    @IBAction func didTapTitleEditButton(_ sender: Any) {
        self.delegate?.didTapTitleEditButton(self)
    }

    @IBAction func didTapTitle(_ sender: Any) {
        self.delegate?.didTapTitleEditButton(self)
    }

    @IBAction func didTapRemover(_ sender: Any) {
        self.delegate?.didTapRemover(self)
    }

    // MARK: - Methods

    public func setEditing(_ isEditing: Bool, animated: Bool) {
        self.isEditing = isEditing
        if animated {
            self.updateAppearanceWithAnimation(isEditing: isEditing)
        } else {
            self.updateAppearance(isEditing: isEditing)
        }
    }

    public func setHiddenIconVisibility(_ isVisible: Bool, animated: Bool) {
        self.visibleHiddenIcon = isVisible
        self.updateHiddenIconAppearance(animated: animated)
    }

    public func setAlbumHiding(_ isHiding: Bool, animated: Bool) {
        self.isHiddenAlbum = isHiding
        self.updateHiddenIconAppearance(animated: animated)
    }

    private func setupAppearance() {
        self.thumbnailImageView.layer.cornerRadius = 10
        self.thumbnailImageView.contentMode = .scaleAspectFill

        self.titleButton.titleLabel?.adjustsFontForContentSizeCategory = true
        self.titleButton.titleLabel?.lineBreakMode = .byTruncatingTail

        if let imageView = self.removerButton.imageView {
            imageView.backgroundColor = .white
            imageView.layer.cornerRadius = imageView.bounds.width / 2
        }

        self.clipCount = nil
        self.isEditing = false

        self.titleButton.isEnabled = isEditing
        self.titleEditButtonContainer.isHidden = !isEditing
        self.removerContainer.isHidden = !isEditing
        self.hiddenIcon.isHidden = true

        self.contentView.clipsToBounds = false
    }

    private func updateAppearance(isEditing: Bool) {
        // HACK: Drag&Drop時にStackView上の編集アイコンが隠れたままになってしまう
        //       ケースがあるため、非同期に実行する
        DispatchQueue.main.async {
            self.titleButton.isEnabled = isEditing
            self.titleEditButtonContainer.isHidden = !isEditing
            self.removerContainer.isHidden = !isEditing
        }
    }

    private func updateAppearanceWithAnimation(isEditing: Bool) {
        guard self.isDragging == false else { return }

        CATransaction.begin()
        CATransaction.setAnimationDuration(0.2)

        UIView.animate(withDuration: 0.2) {
            self.titleButton.isEnabled = isEditing
            self.titleEditButtonContainer.isHidden = !isEditing
            self.titleEditButtonContainer.layoutIfNeeded()
        }

        let displayRemover = isEditing
        if displayRemover {
            self.removerContainer.alpha = 0
            self.removerContainer.isHidden = false
            UIView.animate(withDuration: 0.2) {
                self.removerContainer.alpha = 1
            }
        } else {
            self.removerContainer.alpha = 1
            UIView.animate(withDuration: 0.2) {
                self.removerContainer.alpha = 0
            } completion: { _ in
                self.removerContainer.isHidden = true
                self.removerContainer.alpha = 1
            }
        }

        CATransaction.commit()
    }

    private func updateHiddenIconAppearance(animated: Bool) {
        if visibleHiddenIcon {
            hiddenIcon.setHiding(!isHiddenAlbum, animated: animated)
        } else {
            hiddenIcon.setHiding(true, animated: animated)
        }
    }
}

extension AlbumListCollectionViewCell: ThumbnailLoadObserver {
    // MARK: - ThumbnailLoadObserver

    public func didStartLoading(_ request: ThumbnailRequest) {
        DispatchQueue.main.async {
            guard self.identifier == request.requestId else { return }
            self.thumbnail = nil
        }
    }

    public func didSuccessToLoad(_ request: ThumbnailRequest, image: UIImage) {
        DispatchQueue.main.async {
            guard self.identifier == request.requestId else { return }
            self.thumbnail = image
        }
    }

    public func didFailedToLoad(_ request: ThumbnailRequest) {
        DispatchQueue.main.async {
            guard self.identifier == request.requestId else { return }
            self.thumbnail = nil
        }
    }
}

extension AlbumListCollectionViewCell: ThumbnailPresentable {
    // MARK: - ThumbnailPresentable

    public func calcThumbnailImageSize(originalSize: CGSize?) -> CGSize {
        // Note: frame.height は不定なので、計算に利用しない
        if let originalSize = originalSize {
            if originalSize.width < originalSize.height {
                return .init(width: frame.width,
                             height: frame.width * (originalSize.height / originalSize.width))
            } else {
                return .init(width: frame.width * (originalSize.width / originalSize.height),
                             height: frame.width)
            }
        } else {
            return .init(width: frame.width, height: frame.width)
        }
    }
}
