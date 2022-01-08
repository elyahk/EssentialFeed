//
//  URLSessionHTTPClient.swift
//  EssentialFeedTests
//
//  Created by Eldorbek on 08/01/22.
//

import Foundation
import XCTest

class URLSessionHTTPClient {
    let session: URLSession

    init(session: URLSession) {
        self.session = session
    }

    func get(from url: URL, completion: @escaping () -> Void) {
        session.dataTask(with: url) { _, _, _ in

        }.resume()
    }
}

class URLSessionHTTPClientTests: XCTestCase {
    func test_getFromURL_createsDataTaskWithURL() {
        let session = URLSessionSPY()
        let url = URL(string: "https://a-url.com")!
        let sut = URLSessionHTTPClient(session: session)

        sut.get(from: url) {  }

        XCTAssertEqual(session.recievedURLs, [url])
    }

    func test_getFromURL_resumeDataTaskWithURL() {
        let session = URLSessionSPY()
        let url = URL(string: "https://a-url.com")!
        let task = URLSessionDataTaskSpy()
        let sut = URLSessionHTTPClient(session: session)

        session.stub(url: url, task: task)

        sut.get(from: url) {  }

        XCTAssertEqual(task.resumeCallCount, 1)
    }

    private class URLSessionSPY: URLSession {
        var recievedURLs: [URL] = []
        var stubs = [URL: URLSessionDataTask]()

        override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
            recievedURLs.append(url)
            return stubs[url] ?? FakeURLSessionDataTask()
        }

        func stub(url: URL, task: URLSessionDataTask) {
            stubs[url] = task
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
