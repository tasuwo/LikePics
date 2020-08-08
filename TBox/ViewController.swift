//
//  ViewController.swift
//  TBox
//
//  Created by Tasuku Tozawa on 2020/08/07.
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import UIKit

class ViewController: UIViewController {
    let resolver = WebImageResolver()
    var images: [UIImage] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        self.resolver.webView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.resolver.webView)
        self.resolver.webView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        self.resolver.webView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        self.resolver.webView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.resolver.webView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true

        // self.resolver.webView.isHidden = true

        self.resolver.resolveWebImages(inUrl: URL(string: "")!) { result in
            switch result {
            case let .success(urls):
                self.images = urls
                    .compactMap { try? Data(contentsOf: $0) }
                    .compactMap { UIImage(data: $0) }
            default:
                break
            }
        }
    }
}
