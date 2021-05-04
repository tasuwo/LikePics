//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Smoothie
import UIKit

public class SearchResultClipCell: UICollectionViewCell {
    public static let imageCornerRadius: CGFloat = 6

    public static var nib: UINib {
        return UINib(nibName: "SearchResultClipCell", bundle: Bundle(for: Self.self))
    }

    @IBOutlet public var imageView: UIImageView!

    public var identifier: String?
    public var onReuse: ((String?) -> Void)?

    // MARK: - Lifecycle

    override public func awakeFromNib() {
        super.awakeFromNib()
        self.setupAppearance()
    }

    override public func prepareForReuse() {
        super.prepareForReuse()

        self.onReuse?(self.identifier)

        self.identifier = nil
        self.onReuse = nil
        self.imageView.image = nil
    }

    // MARK: - Methods

    private func setupAppearance() {
        self.clipsToBounds = true
        self.layer.masksToBounds = true
        self.layer.cornerRadius = Self.imageCornerRadius
    }
}

extension SearchResultClipCell: ThumbnailLoadObserver {
    // MARK: - ThumbnailLoadObserver

    public func didStartLoading(_ request: ThumbnailRequest) {
        // NOP
    }

    public func didSuccessToLoad(_ request: ThumbnailRequest, image: UIImage) {
        DispatchQueue.main.async {
            guard self.identifier == request.requestId else { return }
            UIView.transition(with: self.imageView,
                              duration: 0.25,
                              options: .transitionCrossDissolve,
                              animations: { [weak self] in self?.imageView.image = image },
                              completion: nil)
        }
    }

    public func didFailedToLoad(_ request: ThumbnailRequest) {
        DispatchQueue.main.async {
            guard self.identifier == request.requestId else { return }
            self.imageView.image = nil
        }
    }
}

extension SearchResultClipCell: ClipPreviewPresentingCell {
    // MARK: - ClipPreviewPresentingCell

    public func animatingImageView(at index: Int) -> UIImageView? { imageView }
}

extension SearchResultClipCell: ThumbnailPresentable {
    // MARK: - ThumbnailPresentable

    public func calcThumbnailImageSize(originalSize: CGSize?) -> CGSize {
        if let originalSize = originalSize {
            if originalSize.width < originalSize.height {
                return .init(width: frame.width,
                             height: frame.width * (originalSize.height / originalSize.width))
            } else {
                return .init(width: frame.height * (originalSize.width / originalSize.height),
                             height: frame.height)
            }
        } else {
            return frame.size
        }
    }
}
