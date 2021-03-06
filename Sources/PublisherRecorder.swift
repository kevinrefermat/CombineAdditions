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
public final class PublisherRecorder<Value, Failure> where Failure: Error {
    public enum Event {
        case value(Value)
        case completion(Subscribers.Completion<Failure>)
    }
    
    public private(set) var events = [Event]()
    
    private var cancellable: AnyCancellable?
    
    public init(_ publisher: AnyPublisher<Value, Failure>) {
        self.cancellable = publisher.sink(
            receiveCompletion: { [weak self] (completion) in
                self?.events.append(.completion(completion))
            },
            receiveValue: { [weak self] (value) in
                self?.events.append(.value(value))
            }
        )
    }
    
    public var values: [Value] {
        events.compactMap {
            switch $0 {
            case .value(let value):
                return value
            case .completion:
                return nil
            }
        }
    }
    
    public var completion: Subscribers.Completion<Failure>? {
        guard let lastEvent = events.last else { return nil }
        guard case .completion(let completion) = lastEvent else { return nil }
        return completion
    }
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, *)
extension PublisherRecorder.Event: Equatable where Value: Equatable, Failure: Equatable {}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, *)
public extension Publisher {
    func record() -> PublisherRecorder<Output, Failure> {
        .init(eraseToAnyPublisher())
    }
}
