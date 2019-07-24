import Combine
import Foundation

protocol PersistenceServiceType {
    func refreshAmount(with amount: Int)
    func fetchAmount() -> Int
}

class PersistenceService: PersistenceServiceType {
    private let userDefaults: UserDefaults
    private let key: String = "amount"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func refreshAmount(with amount: Int) {
        return userDefaults.set(amount, forKey: key)
    }

    func fetchAmount() -> Int {
        return userDefaults.integer(forKey: key)
    }
}
