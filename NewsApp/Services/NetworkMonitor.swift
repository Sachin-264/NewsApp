import Foundation
import Network
import Combine

final class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.newsapp.networkmonitor", qos: .background)

    @Published private(set) var isConnected: Bool = true
    @Published private(set) var isCellular: Bool = false

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                let satisfied = path.status == .satisfied
                if self?.isConnected != satisfied {
                    self?.isConnected = satisfied
                }
                self?.isCellular = path.isExpensive
            }
        }
        monitor.start(queue: queue)
    }
}
