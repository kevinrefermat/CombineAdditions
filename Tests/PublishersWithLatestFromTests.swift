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

import XCTest
import Combine
import CombineAdditions

@available(OSX 10.15, iOS 13.0, tvOS 13.0, *)
class PublishersWithLatestFromTests: XCTestCase {
    func testThatOperatorWorksWhenBothUpstreamsAreSwitchToLatestPublishers() throws {
        struct Inputs {
            let tap = PassthroughSubject<Void, Never>()
            let value = CurrentValueSubject<String, Never>("")
        }

        let inputs = PassthroughSubject<Inputs, Never>()

        let tap = inputs
            .map { $0.tap }
            .switchToLatest()

        let value = inputs
            .map { $0.value }
            .switchToLatest()

        let recorder = tap
            .withLatestFrom(value)
            .map(\.1)
            .record()

        XCTAssertEqual(recorder.values, [])

        let firstInputs = Inputs()
        inputs.send(firstInputs)

        firstInputs.tap.send()

        XCTAssertEqual(recorder.values, [""])

        let secondInputs = Inputs()
        inputs.send(secondInputs)

        secondInputs.tap.send()

        XCTAssertEqual(recorder.values, ["", ""])
    }
    
    static var allTests = [
        ("testThatOperatorWorksWhenBothUpstreamsAreSwitchToLatestPublishers", testThatOperatorWorksWhenBothUpstreamsAreSwitchToLatestPublishers),
    ]
}
