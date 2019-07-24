enum PaymentError: String, Error {
    case notFoundItem
    case sendReceipt
    case receiveResponse
    case hasUnfinishedTransaction
    case unknown

    var localizedDescription: String {
        return "PaymentError(\(self.rawValue))"
    }
}
