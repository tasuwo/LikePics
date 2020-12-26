//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public enum GridLayout {
    public static func make() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { _, environment -> NSCollectionLayoutSection? in
            return Self.makeSection(for: environment)
        }
        return layout
    }

    public static func makeSection(for environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let itemWidth: NSCollectionLayoutDimension = {
            switch environment.traitCollection.horizontalSizeClass {
            case .compact:
                return .fractionalWidth(0.5)

            case .regular, .unspecified:
                return .fractionalWidth(0.25)

            @unknown default:
                return .fractionalWidth(0.25)
            }
        }()
        let itemSize = NSCollectionLayoutSize(widthDimension: itemWidth,
                                              heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .fractionalWidth(itemWidth.dimension))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)

        return section
    }
}
