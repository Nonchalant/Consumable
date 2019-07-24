import Combine
import Foundation

protocol ConsumableViewModelType {
    var bindingModel: ConsumableBindingModelType { get }

    func fetch()
    func purchase(by id: ConsumableItem.Id)
    func recovery()
    func printReceipt()
}

class ConsumableViewModel: ConsumableViewModelType {
    private(set) var bindingModel: ConsumableBindingModelType
    private let paymentService: PaymentServiceType
    private let persistenceService: PersistenceServiceType
    private let bundle: Bundle

    private let _fetch = PassthroughSubject<Void, Never>()
    private let _purchase = PassthroughSubject<ConsumableItem.Id, Never>()
    private let _recovery = PassthroughSubject<Void, Never>()
    private let _printReceipt = PassthroughSubject<Void, Never>()

    init<S: Scheduler>(bindingModel: ConsumableBindingModelType = ConsumableBindingModel(),
                       paymentService: PaymentServiceType = PaymentService.shared,
                       persistenceService: PersistenceServiceType = PersistenceService(),
                       bundle: Bundle = .main,
                       mainScheduler: S) {
        self.bindingModel = bindingModel
        self.paymentService = paymentService
        self.persistenceService = persistenceService
        self.bundle = bundle

        self.bindingModel.amount = persistenceService.fetchAmount()

        _fetch
            .flatMap { paymentService.fetch() }
            .receive(on: mainScheduler)
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.bindingModel.amount = persistenceService.fetchAmount()
            })
            .receive(subscriber: Subscribers.Assign(object: bindingModel, keyPath: \.items))

        _purchase
            .flatMap { paymentService.purchase(by: $0) }
            .receive(on: mainScheduler)
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.bindingModel.amount = persistenceService.fetchAmount()
            })
            .receive(subscriber: Subscribers.Assign(object: bindingModel, keyPath: \.state))

        _recovery
            .flatMap { paymentService.recoveryPendingTransactions() }
            .receive(on: mainScheduler)
            .receive(subscriber: Subscribers.Sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] _ in
                    self?.bindingModel.amount = persistenceService.fetchAmount()
                }
            ))

        _printReceipt
            .receive(subscriber: Subscribers.Sink(
                receiveCompletion: { _ in },
                receiveValue: { _ in
                    let base64EncodedString = bundle.appStoreReceiptURL
                        .flatMap { try? Data(contentsOf: $0) }
                        .map { $0.base64EncodedString(options: .init(rawValue: 0)) }
                    print(base64EncodedString ?? "Not Found Receipt")
                }
            ))
    }

    func fetch() {
        _fetch.send(())
    }

    func purchase(by id: ConsumableItem.Id) {
        _purchase.send(id)
    }

    func recovery() {
        _recovery.send(())
    }

    func printReceipt() {
        _printReceipt.send(())
    }
}
