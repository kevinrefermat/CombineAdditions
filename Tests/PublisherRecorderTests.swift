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
class PublisherRecorderTests: XCTestCase {
    func testThatRecorderCapturesAllValuesWhenOnlyValuesAreSent() throws {
        let subject = PassthroughSubject<String, Never>()
        let sut = subject.record()
        
        let expectedValues = ["a", "b", "c"]
        expectedValues.forEach {
            subject.send($0)
        }
        
        XCTAssertEqual(sut.events, expectedValues.map { .value($0) })
        XCTAssertEqual(sut.values, expectedValues)
        XCTAssertNil(sut.completion)
    }
    
    func testThatRecorderCapturesAllValuesAndCompletionFinished() throws {
        let subject = PassthroughSubject<String, Never>()
        let sut = subject.record()
        
        let expectedValues = ["a", "b", "c"]
        expectedValues.forEach {
            subject.send($0)
        }
        subject.send(completion: .finished)
        
        XCTAssertEqual(sut.events, expectedValues.map { .value($0) } + [.completion(.finished)])
        XCTAssertEqual(sut.values, expectedValues)
        XCTAssertEqual(sut.completion, .finished)
    }
    
    func testThatRecorderCapturesAllValuesAndCompletionFailure() throws {
        struct TestError: Error, Equatable {
            let description: String
        }
        
        let subject = PassthroughSubject<String, TestError>()
        let sut = subject.record()
        
        let expectedValues = ["a", "b", "c"]
        let expectedError = TestError(description: "whoops")
        expectedValues.forEach {
            subject.send($0)
        }
        subject.send(completion: .failure(expectedError))
        
        XCTAssertEqual(sut.events, expectedValues.map { .value($0) } + [.completion(.failure(expectedError))])
        XCTAssertEqual(sut.values, expectedValues)
        XCTAssertEqual(sut.completion, .failure(expectedError))
    }
    
    func testThatNoValuesAreRecordedAfterCompletionFinished() throws {
        let subject = PassthroughSubject<String, Never>()
        let sut = subject.record()
        
        let expectedValues = ["a", "b", "c"]
        expectedValues.forEach {
            subject.send($0)
        }
        subject.send(completion: .finished)
        subject.send("d")
        
        XCTAssertEqual(sut.events, expectedValues.map { .value($0) } + [.completion(.finished)])
        XCTAssertEqual(sut.values, expectedValues)
        XCTAssertEqual(sut.completion, .finished)
    }
    
    static var allTests = [
        ("testThatRecorderCapturesAllValuesWhenOnlyValuesAreSent", testThatRecorderCapturesAllValuesWhenOnlyValuesAreSent),
        ("testThatRecorderCapturesAllValuesAndCompletionFinished", testThatRecorderCapturesAllValuesAndCompletionFinished),
        ("testThatRecorderCapturesAllValuesAndCompletionFailure", testThatRecorderCapturesAllValuesAndCompletionFailure),
        ("testThatNoValuesAreRecordedAfterCompletionFinished", testThatNoValuesAreRecordedAfterCompletionFinished)
    ]
}
