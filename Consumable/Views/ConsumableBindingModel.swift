import Combine
import Foundation
import SwiftUI

protocol ConsumableBindingModelType: AnyObject {
    var items: [ConsumableItem] { get set }
    var state: PaymentState { get set }
    var amount: Int { get set }
}

class ConsumableBindingModel: ObservableObject, ConsumableBindingModelType {
    let objectWillChange: AnyPublisher<Void, Never>
    private let _objectWillChange = PassthroughSubject<Void, Never>()

    var items: [ConsumableItem] = [] {
        didSet {
            _objectWillChange.send(())
        }
    }

    var state: PaymentState = .initial {
        didSet {
            _objectWillChange.send(())
        }
    }

    var amount: Int = 0 {
        didSet {
            _objectWillChange.send(())
        }
    }

    init() {
        self.objectWillChange = _objectWillChange.eraseToAnyPublisher()
    }
}
