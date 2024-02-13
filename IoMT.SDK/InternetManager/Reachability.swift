import Foundation
import Reachability

class ReachabilityManager {
    
    let reachability: Reachability
    var im:InternetManager
    internal init(manager:InternetManager) {
        // Инициализируем Reachability
        guard let reachability = try? Reachability() else {
            fatalError("Unable to create Reachability")
        }
        self.reachability = reachability
        im = manager
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    func startMonitoring() {
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged(_:)), name: .reachabilityChanged, object: reachability)
        do {
            try reachability.startNotifier()
        } catch {
            print("Could not start reachability notifier")
        }
    }
    
    func stopMonitoring() {
        reachability.stopNotifier()
        NotificationCenter.default.removeObserver(self, name: .reachabilityChanged, object: reachability)
    }
    
    @objc func reachabilityChanged(_ notification: Notification) {
        guard let reachability = notification.object as? Reachability else {
            print("Invalid reachability object")
            return
        }
        
        switch reachability.connection {
        case .none:
            print("Network unreachable")
        case .wifi:
            self.im.dropTimer()
        case .cellular:
            print("Network reachable via cellular data")
            self.im.dropTimer()
        default:
            print("Unknown network status")
        }
    }
}
