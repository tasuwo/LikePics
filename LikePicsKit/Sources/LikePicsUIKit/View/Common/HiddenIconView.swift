//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Common
import UIKit

@IBDesignable
class HiddenIconView: UIView {
    // MARK: - Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.setupAppearance()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        self.setupAppearance()
    }

    // MARK: - Methods

    func setHiding(_ isHidden: Bool, animated: Bool) {
        if animated {
            if isHidden {
                self.alpha = 1
                UIView.likepics_animate(withDuration: 0.2) {
                    self.alpha = 0
                } completion: { _ in
                    self.isHidden = true
                    self.alpha = 1
                }
            } else {
                self.alpha = 0
                self.isHidden = false
                UIView.likepics_animate(withDuration: 0.2) {
                    self.alpha = 1
                }
            }
        } else {
            self.isHidden = isHidden
        }
    }

    // MARK: Privates

    private func setupAppearance() {
        let hiddenIconView = UIImageView(image: UIImage(systemName: "eye.slash")?.withRenderingMode(.alwaysTemplate))
        self.addSubview(hiddenIconView)
        hiddenIconView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hiddenIconView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            hiddenIconView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
        ])

        if !UIAccessibility.isReduceTransparencyEnabled {
            let blurEffect = UIBlurEffect(style: .extraLight)

            let blurEffectView = UIVisualEffectView(effect: blurEffect)
            blurEffectView.translatesAutoresizingMaskIntoConstraints = false
            self.insertSubview(blurEffectView, at: 0)
            NSLayoutConstraint.activate([
                blurEffectView.topAnchor.constraint(equalTo: self.topAnchor),
                blurEffectView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
                blurEffectView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
                blurEffectView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            ])
            blurEffectView.layer.cornerRadius = self.bounds.width / 2.0
            blurEffectView.clipsToBounds = true

            let vibrancyView = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: blurEffect))
            vibrancyView.translatesAutoresizingMaskIntoConstraints = false
            vibrancyView.contentView.addSubview(hiddenIconView)
            blurEffectView.contentView.addSubview(vibrancyView)

            NSLayoutConstraint.activate([
                vibrancyView.topAnchor.constraint(equalTo: blurEffectView.topAnchor),
                vibrancyView.bottomAnchor.constraint(equalTo: blurEffectView.bottomAnchor),
                vibrancyView.leadingAnchor.constraint(equalTo: blurEffectView.leadingAnchor),
                vibrancyView.trailingAnchor.constraint(equalTo: blurEffectView.trailingAnchor),

                hiddenIconView.centerXAnchor.constraint(equalTo: vibrancyView.contentView.centerXAnchor),
                hiddenIconView.centerYAnchor.constraint(equalTo: vibrancyView.contentView.centerYAnchor),
            ])
        } else {
            hiddenIconView.tintColor = .systemGray
            self.backgroundColor = .white
            self.layer.cornerRadius = self.bounds.width / 2.0
            self.clipsToBounds = true
        }

        self.isHidden = true
    }
}
