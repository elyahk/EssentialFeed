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

    private struct UnExpectedValueRepresentation: Error {}

    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        session.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
            } else if let data = data, data.count > 0, let response = response as? HTTPURLResponse {
                completion(.success(data, response))
            } else {
                completion(.failure(UnExpectedValueRepresentation()))
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
        let error = anyNSError()
        let recivedError = resultErrorFor(data: nil, respone: nil, error: error) as NSError?

        XCTAssertEqual(recivedError?.domain, error.domain)
        XCTAssertEqual(recivedError?.code, error.code)
    }

    func test_getFromURL_performsGETRequestWuthURL() {
        let url = anyURL()
        let exp = expectation(description: "Wait for request")

        URLProtocolStub.observeRequest { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            exp.fulfill()
        }

        makeSUT().get(from: url) { _ in }

        wait(for: [exp], timeout: 1.0)
    }

    func test_getFromURL_failsAllInvalidRepresentationCases() {
        XCTAssertNotNil(resultErrorFor(data: nil, respone: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: nil, respone: nonHTTPResponse(), error: nil))
        XCTAssertNotNil(resultErrorFor(data: nil, respone: anyHTTPResponse(), error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData(), respone: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData(), respone: nil, error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: nil, respone: nonHTTPResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: nil, respone: anyHTTPResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), respone: nonHTTPResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), respone: anyHTTPResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), respone: nonHTTPResponse(), error: nil))
    }

    func test_getFromURL_succedsOnHTTPURLResponseWithData() {
        let anyData = anyData()
        let anyHTTPResponse = anyHTTPResponse()
        URLProtocolStub.stub(data: anyData, response: anyHTTPResponse, error: nil)

        let exp = expectation(description: "Wait for request")
        makeSUT().get(from: anyURL()) { result in
            switch result {
            case let .success(data, response):
                XCTAssertEqual(data, anyData)
                XCTAssertEqual(response.url, anyHTTPResponse.url)
                XCTAssertEqual(response.statusCode, anyHTTPResponse.statusCode)
            default:
                XCTFail("Expected succes, but got: \(result) instead")
            }

            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
    }


    // MARK: - Helper

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> URLSessionHTTPClient {
        let sut = URLSessionHTTPClient()
        trackForMemoryLeak(sut)
        
        return sut
    }

    private func anyURL() -> URL {
        return URL(string: "https://a-url.com")!
    }

    private func nonHTTPResponse() -> URLResponse {
        return URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
    }

    private func anyHTTPResponse() -> HTTPURLResponse {
        return HTTPURLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
    }

    private func anyData() -> Data { Data("any data".utf8) }

    private func anyNSError() -> NSError {
        return NSError(domain: "any error", code: 0)
    }

    private func resultErrorFor(data: Data?, respone: URLResponse?, error: Error?, file: StaticString = #filePath, line: UInt = #line) -> Error? {
        let sut = makeSUT(file: file, line: line)
        URLProtocolStub.stub(data: data, response: respone, error: error)

        let exp = expectation(description: "Wait for complation")

        var recievedError: Error?
        sut.get(from: anyURL()) { result in
            switch result {
            case let .failure(error as NSError):
                recievedError = error
            default:
                XCTFail("Expected failure with \(error), but got \(result) instead")
            }

            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)

        return recievedError
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

        static func stub(data: Data?, response: URLResponse?, error: Error?) {
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
