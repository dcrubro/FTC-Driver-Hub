//
//  UDPClient.swift
//  FTC Driver Hub
//
//  Created by dcrubro on 11. 10. 25.
//

import Foundation
import Network

final class UDPClient {
    private var connection: NWConnection?
    private let queue = DispatchQueue(label: "udp.client.queue")

    var onReceive: ((Data) -> Void)?

    func start(host: String, port: UInt16) {
        let endpointHost = NWEndpoint.Host(host)
        let endpointPort = NWEndpoint.Port(rawValue: port)!

        let params = NWParameters.udp
        connection = NWConnection(host: endpointHost, port: endpointPort, using: params)

        connection?.stateUpdateHandler = { state in
            // You can add logging here if desired
        }

        connection?.start(queue: queue)
        receiveLoop()
    }

    func send(_ data: Data) {
        connection?.send(content: data, completion: .contentProcessed({ _ in }))
    }

    func stop() {
        connection?.cancel()
        connection = nil
    }

    private func receiveLoop() {
        connection?.receiveMessage { [weak self] data, _, _, error in
            if let data, !data.isEmpty {
                self?.onReceive?(data)
            }
            if error == nil {
                self?.receiveLoop()
            }
        }
    }
}
