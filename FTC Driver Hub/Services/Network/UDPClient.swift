//
//  UDPClient.swift
//  FTC Driver Hub
//
//  Created by dcrubro on 11. 10. 25.
//


import Foundation

final class UDPClient {
    private var socket: Int32 = -1
    private let queue = DispatchQueue(label: "UDPClientQueue")
    private var destAddr: sockaddr_in?

    /// Called whenever a UDP datagram is received
    var onReceive: ((Data, sockaddr_in) -> Void)?

    func start(host: String, port: UInt16 = 20884) {
        stop() // clean restart if already running

        socket = Darwin.socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
        guard socket >= 0 else {
            perror("socket() failed")
            return
        }

        var yes: Int32 = 1
        setsockopt(socket, SOL_SOCKET, SO_REUSEADDR, &yes, socklen_t(MemoryLayout.size(ofValue: yes)))
        setsockopt(socket, SOL_SOCKET, SO_BROADCAST, &yes, socklen_t(MemoryLayout.size(ofValue: yes)))

        var localAddr = sockaddr_in()
        localAddr.sin_family = sa_family_t(AF_INET)
        localAddr.sin_port = CFSwapInt16HostToBig(port)
        localAddr.sin_addr = in_addr(s_addr: INADDR_ANY)

        let bindResult = withUnsafePointer(to: &localAddr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                Darwin.bind(socket, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }

        guard bindResult == 0 else {
            perror("bind() failed")
            Darwin.close(socket)
            socket = -1
            return
        }

        print("Bound UDP socket to 0.0.0.0:\(port)")

        // Prepare destination address for sends
        var dest = sockaddr_in()
        dest.sin_family = sa_family_t(AF_INET)
        dest.sin_port = CFSwapInt16HostToBig(port)
        inet_pton(AF_INET, host, &dest.sin_addr)
        destAddr = dest

        // Start receiver loop
        queue.async { [weak self] in self?.receiveLoop() }
    }

    func send(_ data: Data) {
        guard var dest = destAddr, socket >= 0 else { return }
        data.withUnsafeBytes { buffer in
            _ = withUnsafeMutablePointer(to: &dest) {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    Darwin.sendto(socket, buffer.baseAddress, buffer.count, 0, $0,
                                  socklen_t(MemoryLayout<sockaddr_in>.size))
                }
            }
        }
    }

    private func receiveLoop() {
        var buffer = [UInt8](repeating: 0, count: 4096)
        var senderAddr = sockaddr_in()
        var addrLen = socklen_t(MemoryLayout<sockaddr_in>.size)

        while socket >= 0 {
            let bytesRead = withUnsafeMutablePointer(to: &senderAddr) {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    Darwin.recvfrom(socket, &buffer, buffer.count, 0, $0, &addrLen)
                }
            }
            if bytesRead > 0 {
                let data = Data(buffer[..<bytesRead])
                onReceive?(data, senderAddr)
            } else if bytesRead < 0 {
                perror("recvfrom() failed")
                break
            }
        }
    }

    func stop() {
        if socket >= 0 {
            Darwin.close(socket)
            socket = -1
            print("UDP socket closed")
        }
    }
}
