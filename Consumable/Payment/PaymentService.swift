import Combine
import StoreKit

protocol PaymentServiceType {
    func fetch() -> AnyPublisher<[ConsumableItem], Never>
    func purchase(by id: ConsumableItem.Id) -> AnyPublisher<PaymentState, Never>
    func recoveryPendingTransactions() -> AnyPublisher<Void, Never>
}

class PaymentService: NSObject, PaymentServiceType {
    static let shared = PaymentService()

    private let paymentQueue: PaymentQueue
    private let transationObserver: PaymentTransactionObserverType
    private let apiClient: APIClientType
    private let persitenceService: PersistenceServiceType
    private let environment: EnvironmentType

    private let _fetch = CurrentValueSubject<[SKProduct], Never>([])
    private let _purchase = PassthroughSubject<ConsumableItem.Id, Never>()
    private var _paymentState = PassthroughSubject<PaymentState, Never>()

    init(paymentQueue: PaymentQueue = SKPaymentQueue.default(),
         transationObserver: PaymentTransactionObserverType = PaymentTransactionObserver(),
         apiClient: APIClientType = APIClient(),
         persitenceService: PersistenceServiceType = PersistenceService(),
         environment: EnvironmentType = Environment.shared) {
        self.paymentQueue = paymentQueue
        self.transationObserver = transationObserver
        self.apiClient = apiClient
        self.persitenceService = persitenceService
        self.environment = environment
        super.init()
        paymentQueue.add(transationObserver)

        transationObserver.updatedTransactions
            .combineLatest(_purchase.eraseToAnyPublisher())
            .receive(subscriber: Subscribers.Sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] (transactions, id) in
                    guard let transaction = transactions.filter({ $0.payment.productIdentifier == id.row }).first else {
                        self?._paymentState.send(.failed(PaymentError.notFoundItem))
                        return
                    }

                    switch transaction.transactionState {
                    case .purchasing:
                        self?._paymentState.send(.started)

                    case .purchased:
                        // 2. 購入完了
                        self?.finishPurchaseConsumable(transaction: transaction)

                    case .failed:
                        self?.paymentQueue.finishTransaction(transaction)
                        self?._paymentState.send(.failed(transaction.error ?? PaymentError.unknown))

                    default:
                        break
                    }
                }
            ))

        _purchase
            .tryMap { [weak self] id -> Result<SKPayment, PaymentError> in
                guard let product = self?._fetch.value.filter({ $0.productIdentifier == id.row }).first else {
                    return .failure(PaymentError.notFoundItem)
                }

                return .success(SKMutablePayment(product: product))
            }
            .receive(subscriber: Subscribers.Sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] result in
                    switch result {
                    case let .success(payment):
                        self?.paymentQueue.add(payment)
                    case let .failure(error):
                        self?._paymentState.send(.failed(error))
                    }
                }
            ))
    }

    deinit {
        paymentQueue.remove(transationObserver)
    }

    func fetch() -> AnyPublisher<[ConsumableItem], Never> {
        return fetchProducts()
            .map { $0.map(ConsumableItem.init(product:)) }
            .eraseToAnyPublisher()
    }

    func purchase(by id: ConsumableItem.Id) -> AnyPublisher<PaymentState, Never> {
        if hasQueueingTransactions {
            // 未完了トランザクションが存在するとき
            return Just(.failed(PaymentError.hasUnfinishedTransaction)).eraseToAnyPublisher()
        }

        _purchase.send(id)
        return _paymentState.eraseToAnyPublisher()
    }

    func recoveryPendingTransactions() -> AnyPublisher<Void, Never> {
        // 未完了トランザクションのリトライ
        let transactions = paymentQueue.transactions
            .filter { $0.transactionState != .purchasing }

        for transaction in transactions {
            finishPurchaseConsumable(transaction: transaction)
        }

        return Just(()).eraseToAnyPublisher()
    }

    private var hasQueueingTransactions: Bool {
        return !paymentQueue.transactions.isEmpty
    }

    private func fetchProducts() -> AnyPublisher<[SKProduct], Never> {
        let productIdentifiers: Set<String> = [
            "com.nonchalant.consumable1",
            "com.nonchalant.consumable2"
        ]

        let request = SKProductsRequest(productIdentifiers: productIdentifiers)
        request.delegate = self
        request.start()

        return _fetch.eraseToAnyPublisher()
    }

    private func finishPurchaseConsumable(transaction: SKPaymentTransaction) {
        guard environment.isNetworkEnabled else {
            // レシート送信に失敗するケース
            _paymentState.send(.failed(PaymentError.sendReceipt))
            return
        }

        // 3. レシート送信 (4~6)
        apiClient.send()
            .receive(subscriber: Subscribers.Sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] result in
                    // 7. 完了レスポンス(201)
                    guard let me = self else {
                        self?._paymentState.send(.failed(PaymentError.unknown))
                        return
                    }

                    switch result {
                    case .success:
                        // 8. トランザクションの終了
                        me.paymentQueue.finishTransaction(transaction)

                        let price = me._fetch.value
                            .filter { $0.productIdentifier == transaction.payment.productIdentifier }
                            .first?
                            .price ?? 0

                        me.persitenceService.refreshAmount(with: Int(truncating: price) + me.persitenceService.fetchAmount())
                        me._paymentState.send(.purchased)

                    case let .failure(error):
                        // 完了レスポンスの受け取りに失敗するケース
                        self?._paymentState.send(.failed(error))
                    }
                }
            ))
    }
}

extension PaymentService: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        _fetch.send(response.products)
    }
}
