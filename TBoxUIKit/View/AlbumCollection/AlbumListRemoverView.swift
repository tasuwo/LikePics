//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import UIKit

public protocol AlbumListRemoverViewDelegate: AnyObject {
    func albumListRemoverView(_ view: AlbumListRemoverView)
}

public class AlbumListRemoverView: UICollectionReusableView {
    // MARK: - Properties

    // MARK: Overrides (UIView)

    override public var frame: CGRect {
        didSet {
            self.configureCorner()
        }
    }

    override public var bounds: CGRect {
        didSet {
            self.configureCorner()
        }
    }

    // MARK: Public

    public weak var delegate: AlbumListRemoverViewDelegate?

    // MARK: Private

    private let symbolView = UIImageView(image: UIImage(systemName: "minus.circle.fill"))
    private var tapGestureRecognizer: UITapGestureRecognizer!

    // MARK: - Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.configure()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }

    // MARK: - Methods

    // MARK: Configure

    func configure() {
        self.symbolView.backgroundColor = .white
        self.symbolView.layer.cornerRadius = self.symbolView.bounds.width / 2.0
        self.symbolView.translatesAutoresizingMaskIntoConstraints = false

        self.addSubview(self.symbolView)

        NSLayoutConstraint.activate([
            self.symbolView.centerXAnchor.constraint(equalTo: centerXAnchor),
            self.symbolView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        self.backgroundColor = .clear

        self.setupGestureRecognizer()
        self.configureCorner()
    }

    func configureCorner() {
        let radius = bounds.width / 2.0
        layer.cornerRadius = radius
    }

    // MARK: Gesture Recognizer

    private func setupGestureRecognizer() {
        self.tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.didTap(_:)))
        self.tapGestureRecognizer.numberOfTapsRequired = 1
        self.addGestureRecognizer(self.tapGestureRecognizer)
    }

    @objc
    func didTap(_ sender: UITapGestureRecognizer) {
        self.delegate?.albumListRemoverView(self)
    }
}
