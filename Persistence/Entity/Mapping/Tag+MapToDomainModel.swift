//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

extension Persistence.Tag {
    func map(to type: Domain.Tag.Type) -> Domain.Tag? {
        guard let id = self.id, let name = self.name else { return nil }
        return Domain.Tag(id: id,
                          name: name,
                          isHidden: self.isHidden,
                          clipCount: Int(self.clipCount))
    }
}
