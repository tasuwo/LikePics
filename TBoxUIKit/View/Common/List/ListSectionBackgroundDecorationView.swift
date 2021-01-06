//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public class ListSectionBackgroundDecorationView: UICollectionReusableView {
    let backgroundView = UIView()

    // MARK: - Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.setupAppearance()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("not implemented")
    }

    // MARK: - Methods

    private func setupAppearance() {
        backgroundColor = .clear

        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.backgroundColor = .systemBackground
        backgroundView.layer.cornerRadius = 18
        addSubview(backgroundView)
        NSLayoutConstraint.activate([
            backgroundView.rightAnchor.constraint(equalTo: rightAnchor),
            backgroundView.leftAnchor.constraint(equalTo: leftAnchor),
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
