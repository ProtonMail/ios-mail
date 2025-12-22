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
import NIOHTTP1
import NIOHTTP2

final class RequestsHandler: ChannelInboundHandler, RemovableChannelHandler, Sendable {
    typealias InboundIn = HTTPServerRequestPart
    typealias OutboundOut = HTTPServerResponsePart

    private let requestsHandlerActor = RequestsHandlerActor()
    private let bundle: Bundle

    init(bundle: Bundle) {
        self.bundle = bundle
    }

    func addMockedRequest(_ request: NetworkRequest) async {
        await requestsHandlerActor.addMockedRequests(request)
    }

    func addMockedRequests(_ requests: NetworkRequest...) async {
        for request in requests {
            await requestsHandlerActor.addMockedRequests(request)
        }
    }

    func removeRequest(_ request: NetworkRequest) async {
        await requestsHandlerActor.remove(request)
    }

    func clear() async {
        await requestsHandlerActor.clear()
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let part = self.unwrapInboundIn(data)

        Task {
            guard case .head(let header) = part else {
                return
            }

            guard let request = await requestsHandlerActor.matchClientRequestHeader(header) else {
                print("⚠️ No matching request found for '\(header.uri)'.")

                let body = generateUnhandledRemoteRequestResponse(header: header)
                await serveResponse(context: context, statusCode: 404, body: body, mimeType: .json)

                return
            }

            guard let responseBody = bundle.getDataFor(fileName: request.localPath) else {
                print("⚠️ Unable to parse response body for '\(header.uri)'.")

                let body = generateAssetNotFoundResponse(localPath: request.localPath)
                await serveResponse(context: context, statusCode: 404, body: body, mimeType: request.mimeType)

                return
            }

            print("✅ Match found for '\(header.uri)'.")

            if request.serveOnce {
                await requestsHandlerActor.remove(request)
            }

            if request.latency != 0 {
                try? await Task.sleep(nanoseconds: request.latency.toNanoSeconds())
            }

            print("➡️ Serving \(header.method) - \(header.uri) with \(request)")

            await serveResponse(context: context, statusCode: request.status, body: responseBody, mimeType: request.mimeType)
        }
    }
}

extension RequestsHandler {
    @Sendable private func serveResponse(
        context: ChannelHandlerContext,
        statusCode: Int,
        body: Data,
        mimeType: NetworkMockMimeType
    ) async {
        var headers = HTTPHeaders()

        headers.add(name: "Content-Type", value: mimeType.rawValue)
        headers.add(name: "Content-Length", value: "\(body.count)")

        let responseHead = HTTPResponseHead(
            version: .init(major: 1, minor: 1),
            status: HTTPResponseStatus(statusCode: statusCode),
            headers: headers
        )

        context.eventLoop.execute {
            context.write(self.wrapOutboundOut(.head(responseHead)), promise: nil)

            var buffer = context.channel.allocator.buffer(capacity: body.count)
            buffer.writeBytes(body)

            context.channel.write(
                self.wrapOutboundOut(HTTPServerResponsePart.body(.byteBuffer(buffer))),
                promise: nil
            )

            context.channel
                .writeAndFlush(
                    self.wrapOutboundOut(HTTPServerResponsePart.end(nil))
                )
                .whenComplete { _ in
                    /* no op */
                }
        }
    }
}
