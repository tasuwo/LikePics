//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public class ClipPreviewPageView: UIView {
    public var image: UIImage? {
        get {
            self.imageView.image
        }
        set {
            self.imageView.image = newValue
            if let image = newValue {
                self.imageView.frame = Self.calcCenterizedFrame(ofImage: image, in: self.bounds)
            }
        }
    }

    @IBOutlet var baseView: UIView!
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var imageView: UIImageView!

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

    // MARK: - Methods

    static func calcCenterizedFrame(ofImage image: UIImage, in frame: CGRect) -> CGRect {
        let widthScale = frame.size.width / image.size.width
        let heightScale = frame.size.height / image.size.height
        let scale = min(widthScale, heightScale)

        let imageSize = CGSize(width: image.size.width * scale,
                               height: image.size.height * scale)
        let imageOrigin = CGPoint(x: frame.origin.x + (frame.size.width - imageSize.width) / 2,
                                  y: frame.origin.y + (frame.size.height - imageSize.height) / 2)

        return CGRect(origin: imageOrigin, size: imageSize)
    }

    private func setupFromNib() {
        Bundle(for: type(of: self)).loadNibNamed("ClipPreviewPageView", owner: self, options: nil)
        self.baseView.frame = self.bounds
        self.addSubview(self.baseView)
    }

    private func setupAppearance() {
        self.scrollView.minimumZoomScale = 1
        self.scrollView.maximumZoomScale = 3
        self.scrollView.showsVerticalScrollIndicator = false
        self.scrollView.showsHorizontalScrollIndicator = false
        self.imageView.contentMode = .scaleAspectFit
    }
}

extension ClipPreviewPageView: UIScrollViewDelegate {
    // MARK: - UIScrollViewDelegate

    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }
}
