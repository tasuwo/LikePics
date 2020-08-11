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

            guard let image = self.imageView.image else { return }
            self.setInitialScale(for: image, on: self.bounds)
            self.updateConstraints(for: image, on: self.bounds)
        }
    }

    @IBOutlet var baseView: UIView!
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var imageView: UIImageView!

    @IBOutlet var leftInsetConstraint: NSLayoutConstraint!
    @IBOutlet var bottomInsetConstraint: NSLayoutConstraint!
    @IBOutlet var rightInsetConstraint: NSLayoutConstraint!
    @IBOutlet var topInsetConstraint: NSLayoutConstraint!

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

    public func shouldRecalculateInitialScale() {
        guard let image = self.imageView.image else { return }
        self.setInitialScale(for: image, on: self.bounds)
        self.updateConstraints(for: image, on: self.bounds)
    }

    private func setupFromNib() {
        Bundle(for: type(of: self)).loadNibNamed("ClipPreviewPageView", owner: self, options: nil)
        self.baseView.frame = self.bounds
        self.addSubview(self.baseView)
        self.sendSubviewToBack(self.baseView)
    }

    private func setupAppearance() {
        self.scrollView.showsVerticalScrollIndicator = false
        self.scrollView.showsHorizontalScrollIndicator = false
        self.scrollView.alwaysBounceVertical = false
        self.scrollView.alwaysBounceHorizontal = false
    }

    func setInitialScale(for image: UIImage, on frame: CGRect) {
        let widthScale = frame.size.width / image.size.width
        let heightScale = frame.size.height / image.size.height
        let scale = min(widthScale, heightScale)

        self.scrollView.minimumZoomScale = scale
        self.scrollView.maximumZoomScale = scale * 3

        self.scrollView.zoomScale = scale
    }

    func updateConstraints(for image: UIImage, on frame: CGRect) {
        let currentScale = self.scrollView.zoomScale

        let horizonalInset = max((frame.width - image.size.width * currentScale) / 2, 0)
        let verticalInset = max((frame.height - image.size.height * currentScale) / 2, 0)

        self.topInsetConstraint.constant = verticalInset
        self.bottomInsetConstraint.constant = verticalInset
        self.leftInsetConstraint.constant = horizonalInset
        self.rightInsetConstraint.constant = horizonalInset
    }

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
}

extension ClipPreviewPageView: UIScrollViewDelegate {
    // MARK: - UIScrollViewDelegate

    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }

    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        guard let image = self.imageView.image else { return }
        self.updateConstraints(for: image, on: self.bounds)
    }
}
