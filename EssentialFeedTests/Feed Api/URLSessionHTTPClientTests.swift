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

        }
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

    private class URLSessionSPY: URLSession {
        var recievedURLs: [URL] = []

        override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
            recievedURLs.append(url)
            return FakeURLSessionDataTask()
        }
    }

    private class FakeURLSessionDataTask: URLSessionDataTask {}
}
