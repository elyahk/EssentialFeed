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
            } else if let data = data, let response = response as? HTTPURLResponse {
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
        let result = resultValuesFor(data: anyData, respone: anyHTTPResponse, error: nil)

        XCTAssertEqual(result?.data, anyData)
        XCTAssertEqual(result?.response.url, anyHTTPResponse.url)
        XCTAssertEqual(result?.response.statusCode, anyHTTPResponse.statusCode)
    }

    func test_getFromURL_succedsOnHTTPURLResponseWithNilData() {
        let result = resultValuesFor(data: nil, respone: anyHTTPResponse(), error: nil)
        let emptyData = Data()

        XCTAssertEqual(emptyData, result?.data)
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

    private func resultValuesFor(data: Data?, respone: URLResponse?, error: Error?, file: StaticString = #filePath, line: UInt = #line) -> (data: Data, response: HTTPURLResponse)? {
        let result = resultFor(data: data, respone: respone, error: error)

        switch result {
        case let .success(data, response):
            return (data, response)
        default:
            XCTFail("Expected success, but got \(result) instead")
            return nil
        }
    }

    private func resultErrorFor(data: Data?, respone: URLResponse?, error: Error?, file: StaticString = #filePath, line: UInt = #line) -> Error? {
        let result = resultFor(data: data, respone: respone, error: error)

        switch result {
        case let .failure(error as NSError):
            return error
        default:
            XCTFail("Expected failure, but got \(result) instead")
            return nil
        }
    }

    private func resultFor(data: Data?, respone: URLResponse?, error: Error?, file: StaticString = #filePath, line: UInt = #line) -> HTTPClientResult {
        let sut = makeSUT(file: file, line: line)
        URLProtocolStub.stub(data: data, response: respone, error: error)

        let exp = expectation(description: "Wait for complation")

        var recievedResult: HTTPClientResult!
        sut.get(from: anyURL()) { result in
            recievedResult = result
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
        return recievedResult
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
