//
//  Network.Connection.swift
//  Utils
//
//  Created by Ivan Kh on 26.01.2023.
//

import Foundation
import Network
import Combine

public extension Black.Network {
    final class Connection {
        public enum ConnectionError : Swift.Error {
            case cancelled
        }

        public struct DataInContext {
            public let data: Data
            public let context: NWConnection.ContentContext
        }

        public var state: AnyNewValuePublisher<NWConnection.State, Never> { stateSubject.eraseToAnyNewValuePublisher() }
        private let stateSubject = KeepValueSubject<NWConnection.State, Never>(.setup)

        public var path: AnyNewValuePublisher<NWPath?, Never> { pathSubject.eraseToAnyNewValuePublisher() }
        private let pathSubject = KeepValueSubject<NWPath?, Never>(nil)

        public var data: AnyPublisher<DataInContext, Error> { dataSubject.eraseToAnyPublisher() }
        private let dataSubject = PassthroughSubject<DataInContext, Error>()

        private let connection: NWConnection
        public private(set) var isFinished = false
        private var receivingData = false
        private var established = false
        private var dataDisposable: AnyCancellable?

        public init(connection: NWConnection) {
            self.connection = connection
            subscribeForStatus()
            subscribeForPath()
        }

        var reconnecting: Bool {
            if case .waiting(_) = state.value {
                return established
            }
            else {
                return false
            }
        }

        public func start(_ queue: DispatchQueue = .global()) async throws {
            var disposable: AnyCancellable?

            listenForData()

            try await withCheckedThrowingContinuation { continuation in
                disposable = state.sink { newValue in
                    switch newValue {
                    case .ready:
                        disposable?.cancel()
                        continuation.resume()
                    case .failed(let error):
                        disposable?.cancel()
                        continuation.resume(throwing: error)
                    case .cancelled:
                        disposable?.cancel()
                        continuation.resume(throwing: ConnectionError.cancelled)
                    default:
                        break
                    }
                }

                connection.start(queue: queue)
            }
        }

        public func stop() async {
            guard !isFinished else { return }
            var disposable: AnyCancellable?

            self.isFinished = true

            await withCheckedContinuation { continuation in
                disposable = state.sink { newValue in
                    switch newValue {
                    case .failed(_), .cancelled:
                        disposable?.cancel()
                        continuation.resume()
                    default:
                        break
                    }
                }

                connection.cancel()
            } as Void
        }

        public func sendAsync(_ data: Data, in context: NWConnection.ContentContext) async throws {
            try await withCheckedThrowingContinuation { continuation in
                connection.send(content: data,
                                contentContext: context,
                                isComplete: true,
                                completion: .contentProcessed { error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    }
                    else {
                        continuation.resume()
                    }
                })
            } as Void
        }

        public func send(_ data: Data, in context: NWConnection.ContentContext) {
            Task {
                try? await sendAsync(data, in: context)
            }
        }

        public func read() async throws -> DataInContext {
            try await withThrowingTaskGroupContinuation(of: DataInContext.self) { continuation, group in
                group.addTask {
                    try await self.data.async(ConnectionError.cancelled)
                }

                group.addTask {
                    _ = await self.state.filter { $0 != .ready }.eraseToAnyPublisher().async()
                    throw ConnectionError.cancelled
                }

                if !self.receivingData {
                    self.listenForData()
                }

                if let result = await group.nextResult() {
                    continuation.resume(with: result)
                }
                else {
                    continuation.resume(throwing: ConnectionError.cancelled)
                }
            }
        }

        private func listenForData() {
            receivingData = true

            connection.receiveMessage { [weak self] completeContent, contentContext, isComplete, error in
                if contentContext?.isFinal == true {
                    self?.isFinished = true

                    Task { [weak self] in
                        await self?.stop()
                    }

                    return
                }

                if let error = error {
                    self?.dataSubject.send(completion: .failure(error))
                }
                else if let contentContext {
                    self?.dataSubject.send(.init(data: completeContent ?? Data(), context: contentContext))
                }

                if error == nil {
                    self?.listenForData()
                }
            }
        }

        private func subscribeForStatus() {
            self.connection.stateUpdateHandler = { [weak self] newState in
                switch newState {
                case .ready:
                    self?.established = true
                    break

                case .failed(_):
                    self?.connection.cancel()

                default:
                    break
                }

                if self?.isFinished == false {
                    self?.stateSubject.send(newState)
                }
                else {
                    self?.stateSubject.send(.cancelled)
                }
            }
        }

        private func subscribeForPath() {
            self.connection.pathUpdateHandler = { [weak self] newPath in
                self?.pathSubject.send(newPath)
            }
        }
    }
}
