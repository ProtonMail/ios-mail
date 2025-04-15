// Copyright (c) 2024 Proton Technologies AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import Foundation
import NIO
import XCTest

final class MockServer: Sendable {
    private let host: String
    private let port: Int
    private let requestsHandler: RequestsHandler
    private let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)

    private var serverBootstrap: ServerBootstrap {
        return ServerBootstrap(group: eventLoopGroup)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(
                ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR),
                value: 1
            )
            .childChannelInitializer { channel in
                channel.pipeline.configureHTTPServerPipeline(
                    withPipeliningAssistance: false,
                    withErrorHandling: false
                ).flatMap { _ in
                    channel.pipeline.addHandler(BackPressureHandler()).flatMap { item in
                        channel.pipeline.addHandler(self.requestsHandler)
                    }
                }
            }
            .childChannelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
            .childChannelOption(
                ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR),
                value: 1
            )
            .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 1)
    }

    init(host: String = "localhost", port: Int = 0, bundle: Bundle) {
        self.host = host
        self.port = port
        self.requestsHandler = RequestsHandler(bundle: bundle)
    }
}

extension MockServer {
    func start() -> SocketAddress? {
        do {
            let channel = try serverBootstrap.bind(host: host, port: port).wait()
            print("Server up and running on: \(channel.localAddress!)")

            return channel.localAddress
        } catch {
            XCTFail("Error on starting the mock server: \(error.localizedDescription)")
            return nil
        }
    }

    func stop() {
        do {
            try eventLoopGroup.syncShutdownGracefully()
        } catch {
            XCTFail("Error on stopping the mock server: \(error.localizedDescription)")
        }
    }
}

extension MockServer {
    func addRequests(_ requests: NetworkRequest...) async {
        for request in requests {
            await self.requestsHandler.addMockedRequest(request)
        }
    }
}
