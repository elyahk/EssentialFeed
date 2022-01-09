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

    init(session: URLSession = .shared) {
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
    override func setUp() {
        URLProtocolStub.startIntercepting()
    }

    override func tearDown() {
        URLProtocolStub.stopIntercepting()
    }

    func test_getFromURL_failsOnRequestError() {
        let url = URL(string: "https://a-url.com")!
        let error = NSError(domain: "Any error", code: 1)

        URLProtocolStub.stub(url: url, data: nil, response: nil, error: error)

        let exp = expectation(description: "Wait for complation")

        makeSUT().get(from: url) { result in
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

    func test_getFromURL_performsGETRequestWuthURL() {
        let url = URL(string: "https://a-url.com")!
        let exp = expectation(description: "Wait for request")

        URLProtocolStub.observeRequest { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            exp.fulfill()
        }

        makeSUT().get(from: url) { _ in }

        wait(for: [exp], timeout: 1.0)
    }

    // MARK: - Helper

    private func makeSUT() -> URLSessionHTTPClient {
        return URLSessionHTTPClient()
    }

    private class URLProtocolStub: URLProtocol {
        private static var stub: Stub?
        private static var requestObserver: ((URLRequest) -> Void)?

        private struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }

        override class func canInit(with request: URLRequest) -> Bool {
            requestObserver?(request)
            return true
        }

        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }

        static func observeRequest(observer: @escaping (URLRequest) -> Void) {
            requestObserver = observer
        }

        override func startLoading() {
            if let data = URLProtocolStub.stub?.data {
                client?.urlProtocol(self, didLoad: data)
            }

            if let response = URLProtocolStub.stub?.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }

            if let error = URLProtocolStub.stub?.error {
                client?.urlProtocol(self, didFailWithError: error)
            }

            client?.urlProtocolDidFinishLoading(self)
        }

        override func stopLoading() {}

        static func stub(url: URL, data: Data?, response: URLResponse?, error: Error?) {
            stub = Stub(data: data, response: response, error: error)
        }

        static func startIntercepting() {
            URLProtocol.registerClass(URLProtocolStub.self)
        }


        static func stopIntercepting() {
            URLProtocol.unregisterClass(URLProtocolStub.self)
            stub = nil
            requestObserver = nil
        }
    }
}
