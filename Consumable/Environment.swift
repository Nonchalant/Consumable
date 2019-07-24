protocol EnvironmentType {
    var isNetworkEnabled: Bool { get }
    var isResponseReceivabled: Bool { get }

    func setIsNetworkEnabled(with isNetworkEnabled: Bool)
    func setIsResponseReceivabled(with isResponseReceivabled: Bool)
}

class Environment: EnvironmentType {
    static let shared = Environment()

    private(set) var isNetworkEnabled: Bool = true
    private(set) var isResponseReceivabled: Bool = true

    func setIsNetworkEnabled(with isNetworkEnabled: Bool) {
        self.isNetworkEnabled = isNetworkEnabled
    }

    func setIsResponseReceivabled(with isResponseReceivabled: Bool) {
        self.isResponseReceivabled = isResponseReceivabled
    }
}
