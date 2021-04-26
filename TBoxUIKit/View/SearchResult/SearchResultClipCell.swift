//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Smoothie
import UIKit

public class SearchResultClipCell: UICollectionViewCell {
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

        self.imageView.image = nil
    }

    // MARK: - Methods

    private func setupAppearance() {
        self.clipsToBounds = true
        self.layer.masksToBounds = true
        self.layer.cornerRadius = 6
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
                              duration: 0.5,
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
