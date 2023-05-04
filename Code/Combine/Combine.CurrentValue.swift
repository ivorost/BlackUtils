//
//  Combine.AnyValue.swift
//  Utils-macOS
//
//  Created by Ivan Kh on 05.01.2023.
//

import Combine

public protocol ValuePublisher<Output, Failure>: Publisher {
    var value: Output { get }
}


extension CurrentValueSubject: ValuePublisher {}


extension Publisher where Self: ValuePublisher {
    public func eraseToAnyValuePublisher() -> AnyValuePublisher<Output, Failure> {
        AnyValuePublisher(self)
    }
}

extension Publisher where Self: Publisher, Self.Output: ExpressibleByNilLiteral {
    public func eraseToAnyValuePublisher() -> AnyCurrentOptionalValuePublisher<Self> {
        AnyCurrentOptionalValuePublisher(self)
    }
}

public struct AnyCurrentOptionalValuePublisher<Upstream>: ValuePublisher
where Upstream: Publisher, Upstream.Output: ExpressibleByNilLiteral {
    public typealias Output = Upstream.Output
    public typealias Failure = Upstream.Failure

    private let inner = Bridge()

    public var value: Upstream.Output {
        inner.subject.value
    }

    init(_ upstream: Upstream) {
        upstream.subscribe(inner)
    }

    public func receive<S>(subscriber: S) where S: Combine.Subscriber, S.Input == Output, S.Failure == Failure {
        inner.subject.receive(subscriber: subscriber)
    }
}

private extension AnyCurrentOptionalValuePublisher {
    class Bridge: Subscriber {
        typealias Input = Upstream.Output
        typealias Failure = Upstream.Failure

        let subject = CurrentValueSubject<Output, Failure>(nil)

        func receive(subscription: Subscription) {
            subject.send(subscription: subscription)
        }

        func receive(_ input: Output) -> Subscribers.Demand {
            subject.send(input)
            return .unlimited
        }

        func receive(completion: Subscribers.Completion<Failure>) {
            subject.send(completion: completion)
        }
    }
}

public struct AnyValuePublisher<Output, Failure>: ValuePublisher where Failure: Error {

    nonisolated public var value: Output {
        box.value
    }

    private let box: PublisherBoxBase<Output, Failure>

    public init<T: ValuePublisher>(_ upstream: T) where T.Output == Output, T.Failure == Failure {
        if let anyValuePublisher = upstream as? AnyValuePublisher<Output, Failure> {
            self.box = anyValuePublisher.box
        } else {
            self.box = PublisherBox(upstream)
        }
    }

    nonisolated public func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
        box.receive(subscriber: subscriber)
    }
}


extension AnyValuePublisher {
    private class PublisherBoxBase<Output, Failure: Error>: ValuePublisher {
        internal var value: Output {
            fatalError("abstract method")
        }

        internal init() {}

        internal func receive<Downstream: Subscriber>(subscriber: Downstream)
            where Failure == Downstream.Failure, Output == Downstream.Input {
            fatalError("abstract method")
        }
    }

    private final class PublisherBox<PublisherType: ValuePublisher>: PublisherBoxBase<PublisherType.Output, PublisherType.Failure> {
        internal let upstream: PublisherType

        internal override var value: PublisherType.Output {
            upstream.value
        }

        internal init(_ upstream: PublisherType) {
            self.upstream = upstream
        }

        internal override func receive<Downstream: Subscriber>(subscriber: Downstream) where Failure == Downstream.Failure, Output == Downstream.Input {
            upstream.receive(subscriber: subscriber)
        }
    }
}
