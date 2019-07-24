import Combine

protocol APIClientType {
    func send() -> AnyPublisher<Result<Void, Error>, Never>
}

struct APIClient: APIClientType {
    private let environment: EnvironmentType

    init(environment: EnvironmentType = Environment.shared) {
        self.environment = environment
    }

    func send() -> AnyPublisher<Result<Void, Error>, Never> {
        guard environment.isResponseReceivabled else {
            return Just(.failure(PaymentError.receiveResponse)).eraseToAnyPublisher()
        }

        return Just(.success(())).eraseToAnyPublisher()
    }
}
