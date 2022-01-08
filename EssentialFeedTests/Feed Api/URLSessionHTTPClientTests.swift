//
//  URLSessionHTTPClient.swift
//  EssentialFeedTests
//
//  Created by Eldorbek on 08/01/22.
//

import Foundation
import EssentialFeed
import XCTest

class URLSessionHTTPClient {
    let session: URLSession

    init(session: URLSession) {
        self.session = session
    }

    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        session.dataTask(with: url) { _, _, error in
            if let error = error {
                completion(.failure(error))
            }

        }.resume()
    }
}

class URLSessionHTTPClientTests: XCTestCase {
    func test_getFromURL_resumeDataTaskWithURL() {
        let session = URLSessionSPY()
        let url = URL(string: "https://a-url.com")!
        let task = URLSessionDataTaskSpy()
        let sut = URLSessionHTTPClient(session: session)

        session.stub(url: url, task: task)

        sut.get(from: url) {  _ in }

        XCTAssertEqual(task.resumeCallCount, 1)
    }

    func test_getFromURL_failsOnRequestError() {
        let url = URL(string: "https://a-url.com")!
        let error = NSError(domain: "Any error", code: 1)
        let session = URLSessionSPY()

        session.stub(url: url, error: error)

        let sut = URLSessionHTTPClient(session: session)

        let exp = expectation(description: "Wait for complation")

        sut.get(from: url) { result in
            switch result {
            case let .failure(recievedError as NSError):
                XCTAssertEqual(recievedError.domain, error.domain)
                XCTAssertEqual(recievedError.code, error.code)
            default:
                XCTFail("Expected failure with \(error), but got \(result) instead")
            }

            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
    }

    // MARK: - Helper

    private class URLSessionSPY: URLSession {
        var recievedURLs: [URL] = []
        private var stubs: [URL: Stub] = [:]

        private struct Stub {
            let url: URL
            let task: URLSessionDataTask
            let error: Error
        }

        override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
            guard let stub = stubs[url] else {
                fatalError("Couldn't find stub for \(url)")
            }

            completionHandler(nil, nil, stub.error)
            return stub.task
        }

        func stub(url: URL, task: URLSessionDataTask = URLSessionDataTaskSpy(), error: Error = NSError(domain: "", code: 0)) {
            stubs[url] = Stub(url: url, task: task, error: error)
        }
    }

    private class FakeURLSessionDataTask: URLSessionDataTask {
        override func resume() {}
    }

    private class URLSessionDataTaskSpy: URLSessionDataTask {
        var resumeCallCount: Int = 0

        override func resume() {
            resumeCallCount += 1
        }
    }
}
