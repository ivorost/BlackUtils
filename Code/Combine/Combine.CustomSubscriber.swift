//  Created by Ivan Kh on 26.04.2023.

import Foundation
import Combine

public protocol CustomSubscriberHandler {
    associatedtype Value
    associatedtype Failure: Error

    func receive(_ input: Value)
    func receive(completion: Subscribers.Completion<Failure>)
}

public extension CustomSubscriberHandler {
    func receive(completion: Subscribers.Completion<Failure>) {}
}

public struct CustomSubscriber<Upstream: Publisher, Handler: CustomSubscriberHandler>: Publisher
where Handler.Value == Upstream.Output, Handler.Failure == Upstream.Failure {
    public typealias Output = Upstream.Output
    public typealias Failure = Upstream.Failure
    let upstream: Upstream
    let handler: Handler

    public init(upstream: Upstream, handler: Handler) {
        self.upstream = upstream
        self.handler = handler
    }

    public func receive<S: Subscriber>(subscriber: S) where S.Input == Output, S.Failure == Failure {
        let bridge = Bridge(downstream: subscriber, handler: handler)
        upstream.subscribe(bridge)
    }
}

private extension CustomSubscriber {
    class Bridge<S: Subscriber>: Subscriber where S.Input == Output, S.Failure == Failure {
        typealias Input = S.Input
        typealias Failure = S.Failure

        private let downstream: S
        private let handler: Handler

        init(downstream: S, handler: Handler) {
            self.downstream = downstream
            self.handler = handler
        }

        func receive(subscription: Subscription) {
            downstream.receive(subscription: subscription)
        }

        func receive(_ input: S.Input) -> Subscribers.Demand {
            handler.receive(input)
            return downstream.receive(input)
        }

        func receive(completion: Subscribers.Completion<S.Failure>) {
            handler.receive(completion: completion)
            downstream.receive(completion: completion)
        }
    }
}
