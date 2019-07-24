import SwiftUI

struct ConsumableView: View {
    private let viewModel: ConsumableViewModelType
    private let environment: EnvironmentType

    @ObservedObject
    private var bindingModel: ConsumableBindingModel

    @State
    private var network = true

    @State
    private var response = true

    var body: some View {
        environment.setIsNetworkEnabled(with: _network.wrappedValue)
        environment.setIsResponseReceivabled(with: _response.wrappedValue)

        return VStack(spacing: 35) {
            ForEach(bindingModel.items, id: \.id) { item in
                Button("Purchase \(item.title) (\(item.price))") {
                    // 1. 購入リクエスト
                    self.viewModel.purchase(by: item.id)
                }
            }

            Toggle(isOn: $network) {
                Text("Enable Network")
            }.padding()

            Toggle(isOn: $response) {
                Text("Receive Response")
            }.padding()

            Button("Fetch Consumable Items") {
                self.viewModel.fetch()
            }

            Button("Recovery Pending Transactions") {
                self.viewModel.recovery()
            }

            Button("Print Receipt") {
                self.viewModel.printReceipt()
            }

            Text("Amount: \(bindingModel.amount)")
            Text("State: \(bindingModel.state.localizedDescription)")
        }
    }

    init(viewModel: ConsumableViewModelType = ConsumableViewModel(mainScheduler: DispatchQueue.main),
         environment: EnvironmentType = Environment.shared) {
        self.viewModel = viewModel
        self.bindingModel = viewModel.bindingModel as! ConsumableBindingModel
        self.environment = environment
    }
}
