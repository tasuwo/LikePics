//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

class ListSectionBackgroundDecorationView: UICollectionReusableView {
    let topSeparatorView = UIView()
    let bottomSeparatorView = UIView()

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
        self.backgroundColor = .systemBackground

        [
            self.topSeparatorView,
            self.bottomSeparatorView
        ].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.backgroundColor = .separator
            self.addSubview($0)
        }

        NSLayoutConstraint.activate([
            self.topSeparatorView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 0),
            self.topSeparatorView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 0),
            self.topSeparatorView.topAnchor.constraint(equalTo: self.topAnchor, constant: 0),
            self.topSeparatorView.heightAnchor.constraint(equalToConstant: 0.5),

            self.bottomSeparatorView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 0),
            self.bottomSeparatorView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 0),
            self.bottomSeparatorView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0),
            self.bottomSeparatorView.heightAnchor.constraint(equalToConstant: 0.5)
        ])
    }
}
