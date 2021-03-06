// Copyright 2021 Kevin Refermat
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Combine

@available(OSX 10.15, iOS 13.0, tvOS 13.0, *)
public extension Publisher {
    func withLatestFrom<Other: Publisher>(_ other: Other) -> Publishers.WithLatestFrom<Self, Other> {
        .init(trigger: self, other: other)
    }
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, *)
public extension Publishers {
    struct WithLatestFrom<Trigger: Publisher, Other: Publisher>: Publisher where Trigger.Failure == Other.Failure {
        public typealias Failure = Trigger.Failure
        public typealias Output = (Trigger.Output, Other.Output)

        private let trigger: Trigger
        private let other: Other

        init(trigger: Trigger, other: Other) {
            self.trigger = trigger
            self.other = other
        }

        public func receive<S>(subscriber: S) where S: Subscriber, Self.Failure == S.Failure, Self.Output == S.Input {
            let subscription = Subscription(trigger: trigger, other: other, subscriber: subscriber)
            subscriber.receive(subscription: subscription)
        }
    }
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, *)
extension Publishers.WithLatestFrom {
    class Subscription<S: Subscriber>: Combine.Subscription where S.Input == Output, S.Failure == Failure {
        private let trigger: Trigger
        private let other: Other
        private var subscriber: S?

        private var latestOtherValue: Other.Output?

        private var triggerCancellable: Combine.Subscription?
        private var otherCancellable: Cancellable?

        private var demand: Subscribers.Demand = .none
        private var didPerformInitialSubscribe = false

        init(trigger: Trigger, other: Other, subscriber: S) {
            self.trigger = trigger
            self.other = other
            self.subscriber = subscriber
        }

        func request(_ demand: Subscribers.Demand) {
            self.demand += demand

            guard didPerformInitialSubscribe == false else { return }

            didPerformInitialSubscribe = true

            trigger.subscribe(
                AnySubscriber<Trigger.Output, Trigger.Failure>(
                    receiveSubscription: { [weak self] (triggerSubscription) in
                        guard let self = self else { return }

                        self.triggerCancellable = triggerSubscription
                        triggerSubscription.request(.unlimited)
                    },
                    receiveValue: { [weak self] (triggerValue) -> Subscribers.Demand in
                        guard let self = self else { return .none }
                        guard let subscriber = self.subscriber else { return .none }
                        guard let otherValue = self.latestOtherValue else { return .none }

                        if self.demand > 0 {
                            if self.demand != .unlimited {
                                self.demand -= 1
                            }

                            let additionalDemand = subscriber.receive((triggerValue, otherValue))
                            self.demand += additionalDemand
                        }

                        return .none
                    },
                    receiveCompletion: { [weak self] (completion) in
                        self?.subscriber?.receive(completion: completion)
                    }
                )
            )

            otherCancellable = other.sink(
                receiveCompletion: { [weak self] (completion) in
                    guard let self = self else { return }

                    switch completion {
                    case .failure:
                        self.subscriber?.receive(completion: completion)
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] (value) in
                    self?.latestOtherValue = value
                }
            )
        }

        func cancel() {
            subscriber = nil
            triggerCancellable?.cancel()
            otherCancellable?.cancel()
        }
    }
}
