// Copyright (c) 2020 Combine Community, and/or Shai Mishali
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

import XCTest
import Combine

@available(OSX 10.15, iOS 13.0, tvOS 13.0, *)
class PublishersWithLatestFromCombineExtTests: XCTestCase {
    var subscription: AnyCancellable!

    func testWithResultSelector() {
        let subject1 = PassthroughSubject<Int, Never>()
        let subject2 = PassthroughSubject<String, Never>()
        var results = [String]()
        var completed = false

        subscription = subject1
            .withLatestFrom(subject2)
            .map { "\($0.0)\($0.1)" }
            .sink(
                receiveCompletion: { _ in completed = true },
                receiveValue: { results.append($0) }
            )

        subject1.send(1)
        subject1.send(2)
        subject1.send(3)
        subject2.send("bar")
        subject1.send(4)
        subject1.send(5)
        subject2.send("foo")
        subject1.send(6)
        subject2.send("qux")
        subject1.send(7)
        subject1.send(8)
        subject1.send(9)

        XCTAssertEqual(results, ["4bar", "5bar", "6foo", "7qux", "8qux", "9qux"])

        XCTAssertFalse(completed)
        subject2.send(completion: .finished)
        XCTAssertFalse(completed)
        subject1.send(completion: .finished)
        XCTAssertTrue(completed)
    }

    // We have to hold a reference to the subscription or the
    // publisher will get deallocated and canceled
    var demandSubscription: Subscription!

    func testWithResultSelectorLimitedDemand() {
        let subject1 = PassthroughSubject<Int, Never>()
        let subject2 = PassthroughSubject<String, Never>()
        var results = [String]()
        var completed = false

        let subscriber = AnySubscriber<String, Never>(
            receiveSubscription: { subscription in
                self.demandSubscription = subscription
                subscription.request(.max(3))
            },
            receiveValue: { val in
                results.append(val)
                return .none
            },
            receiveCompletion: { _ in completed = true }
        )

        subject1
            .withLatestFrom(subject2)
            .map { "\($0.0)\($0.1)" }
            .subscribe(subscriber)

        subject1.send(1)
        subject1.send(2)
        subject1.send(3)
        subject2.send("bar")
        subject1.send(4)
        subject1.send(5)
        subject2.send("foo")
        subject1.send(6)
        subject2.send("qux")
        subject1.send(7)
        subject1.send(8)
        subject1.send(9)

        XCTAssertEqual(results, ["4bar", "5bar", "6foo"])

        XCTAssertFalse(completed)
        subject2.send(completion: .finished)
        XCTAssertFalse(completed)
        subject1.send(completion: .finished)
        XCTAssertTrue(completed)
    }

    func testNoResultSelector() {
        let subject1 = PassthroughSubject<Int, Never>()
        let subject2 = PassthroughSubject<String, Never>()
        var results = [String]()
        var completed = false

        subscription = subject1
            .withLatestFrom(subject2)
            .sink(
                receiveCompletion: { _ in completed = true },
                receiveValue: { results.append($0.1) }
            )

        subject1.send(1)
        subject1.send(2)
        subject1.send(3)
        subject2.send("bar")
        subject1.send(4)
        subject1.send(5)
        subject2.send("foo")
        subject1.send(6)
        subject2.send("qux")
        subject1.send(7)
        subject1.send(8)
        subject1.send(9)

        XCTAssertEqual(results, ["bar", "bar", "foo", "qux", "qux", "qux"])

        XCTAssertFalse(completed)
        subject2.send(completion: .finished)
        XCTAssertFalse(completed)
        subject1.send(completion: .finished)
        XCTAssertTrue(completed)
        subscription.cancel()
    }
    
    static var allTests = [
        ("testWithResultSelector", testWithResultSelector),
        ("testWithResultSelectorLimitedDemand", testWithResultSelectorLimitedDemand),
        ("testNoResultSelector", testNoResultSelector),
    ]
}
