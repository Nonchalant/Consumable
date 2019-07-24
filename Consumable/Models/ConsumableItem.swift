import Foundation
import StoreKit
import SwiftUI

struct ConsumableItem {
    let id: Id
    let title: String
    let price: String

    struct Id: Hashable {
        let row: String
    }
}

extension ConsumableItem {
    init(product: SKProduct) {
        self.id = Id(row: product.productIdentifier)
        self.title = product.localizedTitle

        let formatter = NumberFormatter()
        formatter.formatterBehavior = .behavior10_4
        formatter.numberStyle = .currency
        formatter.locale = product.priceLocale
        self.price = formatter.string(from: product.price) ?? ""
    }
}
