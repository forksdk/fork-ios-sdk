//
//  ForkNetworkManager.swift
//
//
//  Created by Aleksandras Gaidamauskas on 16/04/2024.
//

import Foundation
import Network

class ForkNetworkManager: ObservableObject {
    let monitor = NWPathMonitor()
    let queue = DispatchQueue(label: "ForkNetworkManager")
    @Published var isConnected = true

    init() {
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                self.isConnected = path.status == .satisfied
            }
        }

        monitor.start(queue: queue)
    }
}
