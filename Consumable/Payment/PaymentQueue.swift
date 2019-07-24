import StoreKit

protocol PaymentQueue {
    var transactions: [SKPaymentTransaction] { get }

    func canMakePayments() -> Bool
    func add(_ observer: SKPaymentTransactionObserver)
    func remove(_ observer: SKPaymentTransactionObserver)
    func add(_ payment: SKPayment)
    func finishTransaction(_ transaction: SKPaymentTransaction)
    func restoreCompletedTransactions()
    func restoreCompletedTransactions(withApplicationUsername username: String?)
}

extension SKPaymentQueue: PaymentQueue {
    func canMakePayments() -> Bool {
        return SKPaymentQueue.canMakePayments()
    }
}
