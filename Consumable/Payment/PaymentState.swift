import Foundation

enum PaymentState {
    case initial
    case started
    case purchased
    case failed(Error)

    var localizedDescription: String {
        switch self {
        case .initial:
            return "initial"

        case .started:
            return "started"

        case .purchased:
            return "purchased"

        case let .failed(error):
           return (error as? PaymentError)?.localizedDescription ?? error.localizedDescription
        }
    }
}
