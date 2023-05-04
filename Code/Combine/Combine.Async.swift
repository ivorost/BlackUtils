//  Created by Ivan Kh on 28.04.2023.

import Foundation
import Combine

public extension AnyPublisher where Self.Failure: Error {
    func async() async throws -> Output? {
        try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            var result: Output?

            cancellable = first()
                .sink { completion in
                    switch completion {
                    case .finished:
                        continuation.resume(returning: result)
                    case let .failure(error):
                        continuation.resume(throwing: error)
                    }
                    cancellable?.cancel()
                } receiveValue: { value in
                    result = value
                }
        }
    }

    func async(_ nilError: Error) async throws -> Output {
        try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            var result: Output?

            cancellable = first()
                .sink { completion in
                    switch completion {
                    case .finished:
                        if let result {
                            continuation.resume(returning: result)
                        }
                        else {
                            continuation.resume(throwing: nilError)
                        }
                    case let .failure(error):
                        continuation.resume(throwing: error)
                    }
                    cancellable?.cancel()
                } receiveValue: { value in
                    result = value
                }
        }
    }
}

public extension AnyPublisher where Self.Failure == Never {
    func async() async -> Output? {
        await withCheckedContinuation { continuation in
            var cancellable: AnyCancellable?
            var result: Output?

            cancellable = first()
                .sink { completion in
                    switch completion {
                    case .finished:
                        continuation.resume(returning: result)
                    case let .failure(error):
                        continuation.resume(throwing: error)
                    }
                    cancellable?.cancel()
                } receiveValue: { value in
                    result = value
                }
        }
    }
}
