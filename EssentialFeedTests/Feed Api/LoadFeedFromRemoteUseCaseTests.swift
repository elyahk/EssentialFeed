//
//  FeedFeatureLoader.swift
//  EssentialFeedTests
//
//  Created by Eldorbek on 06/01/22.
//

import EssentialFeed
import XCTest

class LoadFeedFromRemoteUseCaseTests: XCTestCase {
    func test_init_doesNotRequestDataFromUrl() {
        let (_, client) = makeSUT()

        XCTAssertTrue(client.requestedUrls.isEmpty)
    }

    func test_load_requestsDataFromUrl() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)

        sut.load { _ in }

        XCTAssertEqual(client.requestedUrls, [url])
    }

    func test_loadTwice_requestsDataFromUrlTwice() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)

        sut.load { _ in }
        sut.load { _ in }

        XCTAssertEqual(client.requestedUrls, [url, url])
    }

    func test_load_deliversErrorOnClientError() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)

        expect(sut, toCompleteWith: failure(.connectivity), when: {
            let clientError = NSError(domain: "Test", code: 0)
            client.complete(with: clientError)
        })
    }

    func test_load_deliversErrorOnNon200HTTPResponse() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)

        let samples = [199, 201, 300, 400, 500]
        samples.enumerated().forEach { index, code in
            expect(sut, toCompleteWith: failure(.invalidData), when: {
                let json = makeItemsJSON(items: [])
                client.complete(withStatusCode: code, data: json, at: index)
            })
        }
    }

    func test_load_deliversErrorOn200HTTPResponseWithInvalidJson() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)

        expect(sut, toCompleteWith: failure(.invalidData), when: {
            let invalidJson = Data("Invalid json".utf8)
            client.complete(withStatusCode: 200, data: invalidJson)
        })
    }

    func test_load_deliversNoItemsOn200HTTPResponseWithEmptyJSONList() {
        let (sut, client) = makeSUT()

        expect(sut, toCompleteWith: .success([]), when: {
            let emptyJSON = makeItemsJSON(items: [])
            client.complete(withStatusCode: 200, data: emptyJSON)
        })
    }

    func test_load_deliversItemsOn200HTTPResponseWithValidJSONList() {
        let (sut, client) = makeSUT()

        let item1 = makeItem(
            id: UUID(),
            imageURL: URL(string: "https://a-url.com")!)

        let item2 = makeItem(
            id: UUID(),
            description: "a description",
            location: "a location",
            imageURL: URL(string: "https://another-url.com")!)

        expect(sut, toCompleteWith: .success([item1.model, item2.model]), when: {
            let json = makeItemsJSON(items: [item1.json, item2.json])
            client.complete(withStatusCode: 200, data: json)
        })
    }

    func test_load_doesNotDeliverResultAfterSUTInstanceHasBeenDeallocated() {
        let url = URL(string: "https://a-url.com")!
        let client = HTTPClientSpy()
        var sut: RemoteFeedLoader? = RemoteFeedLoader(url: url, client: client)

        var capturedResults = [RemoteFeedLoader.Result]()
        sut?.load { capturedResults.append($0)}

        sut = nil
        client.complete(withStatusCode: 200, data: makeItemsJSON(items: []))

        XCTAssertTrue(capturedResults.isEmpty)
    }

    // MARK: - Helpers
    
    private func makeSUT(url: URL = URL(string: "https://a-url.com")!, file: StaticString = #filePath, line: UInt = #line) -> (RemoteFeedLoader, HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)

        trackForMemoryLeak(sut, file: file, line: line)
        trackForMemoryLeak(client, file: file, line: line)

        return (sut, client)
    }

    private func failure(_ error: RemoteFeedLoader.Error) -> RemoteFeedLoader.Result {
        .failure(error)
    }

    private func makeItem(id: UUID, description: String? = nil, location: String? = nil, imageURL: URL) -> (model: FeedImage, json: [String: Any]) {
        let item = FeedImage(id: id, description: description, location: location, url: imageURL)

        let json = [
            "id": id.uuidString,
            "description": description,
            "location": location,
            "image": imageURL.absoluteString
        ].compactMapValues { $0 }

        return (item, json)
    }

    private func makeItemsJSON(items: [[String: Any]]) -> Data {
        return try! JSONSerialization.data(withJSONObject: [ "items": items])
    }

    private func expect(_ sut: RemoteFeedLoader, toCompleteWith expectedResult: RemoteFeedLoader.Result, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {

        let exp = expectation(description: "Wait for remote feed loader")
        sut.load { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(recivedItems), .success(expectedItems)):
                XCTAssertEqual(recivedItems, expectedItems, file: file, line: line)

            case let (.failure(recivedError as RemoteFeedLoader.Error), .failure(expectedError as RemoteFeedLoader.Error)):
                XCTAssertEqual(recivedError, expectedError, file: file, line: line)

            default:
                XCTFail("Expected Result: \(expectedResult), but recieve: \(receivedResult) instead!", file: file, line: line)
            }

            exp.fulfill()
        }

        action()

        wait(for: [exp], timeout: 1.0)
    }

    private class HTTPClientSpy: HTTPClient {
        var messages = [(url: URL, completion: (HTTPClientResult) -> Void)]()

        var requestedUrls: [URL] {
            messages.map { $0.url }
        }

        func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
            messages.append((url, completion))
        }

        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(.failure(error))
        }

        func complete(withStatusCode code: Int, data: Data, at index: Int = 0) {
            let response = HTTPURLResponse(
                url: messages[index].url,
                statusCode: code,
                httpVersion: nil,
                headerFields: nil
            )!
            
            messages[index].completion(.success(data, response))
        }
    }
}
