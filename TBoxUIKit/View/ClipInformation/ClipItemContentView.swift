//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import UIKit

public class ClipItemContentView: UIView {
    public static var nib: UINib {
        return UINib(nibName: "ClipItemCell", bundle: Bundle(for: Self.self))
    }

    private var _configuration: ClipItemContentConfiguration!

    @IBOutlet private var baseView: UIView!
    @IBOutlet private var pageNumberLabelContainer: UIView!
    @IBOutlet private var pageNumberLabel: UILabel!
    @IBOutlet private var fileNameLabel: UILabel!
    @IBOutlet private var dataSizeLabel: UILabel!
    @IBOutlet private var thumbnailWidthConstraint: NSLayoutConstraint!
    @IBOutlet private var thumbnailHeightConstraint: NSLayoutConstraint!
    @IBOutlet private var overlayView: UIView!
    @IBOutlet private var selectionMarkContainer: UIView!

    @IBOutlet var thumbnailImageView: UIImageView!

    private var thumbnailImageAspectConstraint: NSLayoutConstraint? {
        willSet {
            thumbnailImageAspectConstraint?.isActive = false
        }
        didSet {
            thumbnailImageAspectConstraint?.isActive = true
        }
    }

    // MARK: - Initializers

    init(configuration: ClipItemContentConfiguration) {
        super.init(frame: .zero)

        setupFromNib()
        setupAppearance()
        apply(configuration)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Methods

    public func calcImageFrame(size: CGSize) -> CGRect {
        let imageArea = CGSize(width: bounds.size.width,
                               height: bounds.size.width)
        let scale = size.scale(fittingIn: imageArea)
        let imageSize = CGSize(width: size.width * scale,
                               height: size.height * scale)
        return CGRect(origin: CGPoint(x: (imageArea.width - imageSize.width) / 2,
                                      y: (imageArea.height - imageSize.height) / 2),
                      size: imageSize)
    }
}

extension ClipItemContentView: UIContentView {
    public var configuration: UIContentConfiguration {
        get {
            _configuration
        }
        set(newValue) {
            guard let configuration = newValue as? ClipItemContentConfiguration else { return }
            apply(configuration)
        }
    }
}

extension ClipItemContentView {
    private func setupFromNib() {
        Bundle(for: type(of: self)).loadNibNamed("ClipItemContentView", owner: self, options: nil)
        baseView.frame = self.bounds

        baseView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(baseView)
        NSLayoutConstraint.activate(baseView.constraints(fittingIn: self))
    }

    private func setupAppearance() {
        pageNumberLabelContainer.layer.cornerRadius = 5
        pageNumberLabelContainer.layer.cornerCurve = .continuous

        thumbnailImageView.layer.cornerRadius = 8
        thumbnailImageView.layer.cornerCurve = .continuous

        selectionMarkContainer.backgroundColor = .white
        selectionMarkContainer.layer.cornerRadius = selectionMarkContainer.bounds.width / 2.0

        overlayView.layer.cornerRadius = 8
        overlayView.layer.cornerCurve = .continuous
        overlayView.isHidden = true
    }

    func apply(_ configuration: ClipItemContentConfiguration) {
        _configuration = configuration

        if let image = configuration.image {
            thumbnailImageView.image = configuration.image
            let ratio = image.size.height / image.size.width

            if image.size.height > image.size.width {
                thumbnailHeightConstraint.isActive = true
                thumbnailWidthConstraint.isActive = false
            } else {
                thumbnailHeightConstraint.isActive = false
                thumbnailWidthConstraint.isActive = true
            }

            thumbnailImageAspectConstraint = thumbnailImageView.heightAnchor.constraint(equalTo: thumbnailImageView.widthAnchor,
                                                                                        multiplier: ratio)
        } else {
            thumbnailImageView.image = nil
            thumbnailImageAspectConstraint = nil
        }

        pageNumberLabel.text = "\(configuration.page)/\(configuration.numberOfPage)"
        fileNameLabel.text = configuration.displayFileName
        dataSizeLabel.text = configuration.displayDataSize

        overlayView.isHidden = configuration.isOverlayViewHidden
    }
}
