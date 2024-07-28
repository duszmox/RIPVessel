//
//  ApiService.swift
//  RIPVessel
//
//  Created by Gyula Kiri on 2024. 07. 27..
//
import OpenAPIURLSession
import Logging
import HTTPTypes
import Foundation
import OpenAPIRuntime


public class ApiService {
    
    public static let shared = ApiService()
    
    let client: Client;
    var logger = Logger(label: "HelloWorldURLSessionClient")

    public init() {
        self.logger.logLevel = .debug
        do {
            client = Client(
                serverURL: try Servers.server1(),
                // If this isn't present the decoder will fail where there is a date-time, refer: https://forums.developer.apple.com/forums/thread/744220
                configuration: .init(dateTranscoder: .iso8601WithFractionalSeconds),
                transport: URLSessionTransport(),
                middlewares: [LoggingMiddleware(logger: logger, bodyLoggingConfiguration: .upTo(maxBytes: 1024))]

            )
        }
        catch {
            fatalError("Failed to create client: \(error)")
        }
    }
    
}
fileprivate actor LoggingMiddleware {
    private let logger: Logger
    fileprivate let bodyLoggingPolicy: BodyLoggingPolicy

    fileprivate init(logger: Logger = defaultLogger, bodyLoggingConfiguration: BodyLoggingPolicy = .never) {
        self.logger = logger
        self.bodyLoggingPolicy = bodyLoggingConfiguration
    }

    fileprivate static var defaultLogger: Logger { Logger(label: "com.apple.swift-openapi.logging-middleware") }
}

extension LoggingMiddleware: ClientMiddleware {
    fileprivate func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        let (requestBodyToLog, requestBodyForNext) = try await bodyLoggingPolicy.process(body)
        log(request, requestBodyToLog)
        do {
            let (response, responseBody) = try await next(request, requestBodyForNext, baseURL)
            let (responseBodyToLog, responseBodyForNext) = try await bodyLoggingPolicy.process(responseBody)
            log(request, response, responseBodyToLog)
            return (response, responseBodyForNext)
        } catch {
            log(request, failedWith: error)
            throw error
        }
    }
}

extension LoggingMiddleware: ServerMiddleware {
    fileprivate func intercept(
        _ request: HTTPTypes.HTTPRequest,
        body: OpenAPIRuntime.HTTPBody?,
        metadata: OpenAPIRuntime.ServerRequestMetadata,
        operationID: String,
        next: @Sendable (HTTPTypes.HTTPRequest, OpenAPIRuntime.HTTPBody?, OpenAPIRuntime.ServerRequestMetadata)
            async throws -> (HTTPTypes.HTTPResponse, OpenAPIRuntime.HTTPBody?)
    ) async throws -> (HTTPTypes.HTTPResponse, OpenAPIRuntime.HTTPBody?) {
        let (requestBodyToLog, requestBodyForNext) = try await bodyLoggingPolicy.process(body)
        log(request, requestBodyToLog)
        do {
            let (response, responseBody) = try await next(request, requestBodyForNext, metadata)
            let (responseBodyToLog, responseBodyForNext) = try await bodyLoggingPolicy.process(responseBody)
            log(request, response, responseBodyToLog)
            return (response, responseBodyForNext)
        } catch {
            log(request, failedWith: error)
            throw error
        }
    }
}

extension LoggingMiddleware {
    func log(_ request: HTTPRequest, _ requestBody: BodyLoggingPolicy.BodyLog) {
        logger.debug(
            "Request",
            metadata: [
                "method": .stringConvertible(request.method), "path": .string(request.path ?? "<nil>"),
                "headers": .array(request.headerFields.map { "\($0.name)=\($0.value)" }),
                "body": .stringConvertible(requestBody),
            ]
        )
    }

    func log(_ request: HTTPRequest, _ response: HTTPResponse, _ responseBody: BodyLoggingPolicy.BodyLog) {
        logger.debug(
            "Response",
            metadata: [
                "method": .stringConvertible(request.method), "path": .string(request.path ?? "<nil>"),
                "headers": .array(response.headerFields.map { "\($0.name)=\($0.value)" }),
                "body": .stringConvertible(responseBody),
            ]
        )
    }

    func log(_ request: HTTPRequest, failedWith error: any Error) {
        logger.warning(
            "Request error",
            metadata: [
                "method": .stringConvertible(request.method), "path": .string(request.path ?? "<nil>"),
                "error": .string(error.localizedDescription),
            ]
        )
    }
}

fileprivate enum BodyLoggingPolicy {
    /// Never log request or response bodies.
    case never
    /// Log request and response bodies that have a known length less than or equal to `maxBytes`.
    case upTo(maxBytes: Int)

    enum BodyLog: Equatable, CustomStringConvertible {
        /// There is no body to log.
        case none
        /// The policy forbids logging the body.
        case redacted
        /// The body was of unknown length.
        case unknownLength
        /// The body exceeds the maximum size for logging allowed by the policy.
        case tooManyBytesToLog(Int64)
        /// The body can be logged.
        case complete(Data)

        var description: String {
            switch self {
            case .none: return "<none>"
            case .redacted: return "<redacted>"
            case .unknownLength: return "<unknown length>"
            case .tooManyBytesToLog(let byteCount): return "<\(byteCount) bytes>"
            case .complete(let data):
                if let string = String(data: data, encoding: .utf8) { return string }
                return String(describing: data)
            }
        }
    }

    func process(_ body: HTTPBody?) async throws -> (bodyToLog: BodyLog, bodyForNext: HTTPBody?) {
        switch (body?.length, self) {
        case (.none, _): return (.none, body)
        case (_, .never): return (.redacted, body)
        case (.unknown, _): return (.unknownLength, body)
        case (.known(let length), .upTo(let maxBytesToLog)) where length > maxBytesToLog:
            return (.tooManyBytesToLog(length), body)
        case (.known, .upTo(let maxBytesToLog)):
            let bodyData = try await Data(collecting: body!, upTo: maxBytesToLog)
            return (.complete(bodyData), HTTPBody(bodyData))
        }
    }
}
