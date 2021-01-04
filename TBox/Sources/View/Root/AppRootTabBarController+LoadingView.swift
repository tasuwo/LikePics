//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import UIKit

extension AppRootTabBarController {
    func addLoadingView() {
        guard self.loadingView == nil, let view = self.view else { return }

        let loadingView = UIView(frame: view.frame)
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingView)
        view.bringSubviewToFront(loadingView)
        NSLayoutConstraint.activate([
            loadingView.topAnchor.constraint(equalTo: view.topAnchor),
            loadingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loadingView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        let indicatorView = UIActivityIndicatorView(style: .large)
        indicatorView.translatesAutoresizingMaskIntoConstraints = false
        indicatorView.hidesWhenStopped = true
        loadingView.addSubview(indicatorView)
        NSLayoutConstraint.activate([
            indicatorView.centerXAnchor.constraint(equalTo: loadingView.centerXAnchor),
            indicatorView.centerYAnchor.constraint(equalTo: loadingView.centerYAnchor)
        ])

        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        label.textColor = .white
        label.text = L10n.appRootLoadingMessage
        loadingView.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: indicatorView.bottomAnchor, constant: 12),
            label.centerXAnchor.constraint(equalTo: loadingView.centerXAnchor)
        ])

        loadingView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        indicatorView.startAnimating()

        self.loadingView = loadingView
    }

    func removeLoadingView() {
        self.loadingView?.isHidden = true
        self.loadingView?.removeFromSuperview()
        self.loadingView = nil
    }
}
