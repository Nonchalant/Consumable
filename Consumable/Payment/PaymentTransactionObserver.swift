import Combine
import StoreKit

protocol PaymentTransactionObserverType: SKPaymentTransactionObserver {
    var updatedTransactions: AnyPublisher<[SKPaymentTransaction], Never> { get }
}

class PaymentTransactionObserver: NSObject, PaymentTransactionObserverType {
    let updatedTransactions: AnyPublisher<[SKPaymentTransaction], Never>
    private let _updatedTransactions = PassthroughSubject<[SKPaymentTransaction], Never>()

    override init() {
        self.updatedTransactions = _updatedTransactions.eraseToAnyPublisher()
        super.init()
    }

    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        _updatedTransactions.send(transactions)
    }
}
