//
//  CodableFeedStore.swift
//  EssentialFeedTests
//
//  Created by Eldorbek on 08/03/22.
//

import Foundation
import XCTest
import EssentialFeed

class CodableFeedStore {
    private struct Cache: Codable {
        let feed: [CodableFeedImage]
        let timestamp: Date

        var feedLocal: [LocalFeedImage] {
            feed.map { $0.local }
        }
    }

    private class CodableFeedImage: Codable {
        private let id: UUID
        private let description: String?
        private let location: String?
        private let url: URL

        internal init(_ image: LocalFeedImage) {
            self.id = image.id
            self.description = image.description
            self.location = image.location
            self.url = image.url
        }

        var local: LocalFeedImage { LocalFeedImage(id: id, description: description, location: location, url: url) }
    }

    private let storURL: URL

    init(storeURL: URL) {
        self.storURL = storeURL
    }

    func retrieve(completion: @escaping FeedStore.RetrievalCompletion) {
        guard let data = try? Data(contentsOf: storURL) else { return completion(.empty) }

        let decoder = JSONDecoder()
        let cache = try! decoder.decode(Cache.self, from: data)
        completion(.found(cache.feedLocal, cache.timestamp))
    }

    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping FeedStore.InsertionCompletion) {
        let encoder = JSONEncoder()
        let encoded = try! encoder.encode(Cache(feed: feed.map(CodableFeedImage.init), timestamp: timestamp))
        try! encoded.write(to: storURL)
        completion(nil)
    }
}

class CodableFeedStoreTests: XCTestCase {
    override func setUp() {
        super.setUp()

        setUpEmptyState()
    }

    override func tearDown() {
        super.tearDown()
        undoStoreSideEffects()
    }

    func test_retrieve_delieversEmptyOnEmptyCache() {
        let sut = makeSUT()

        expect(sut, toRetrieve: .empty)
    }

    func test_retrieve_hasNoSideEffectOnEmptyCache() {
        let sut = makeSUT()

        let exp = expectation(description: "Wait for retrieve")
        sut.retrieve { firstResult in
            sut.retrieve { secondResult in
                switch (firstResult, secondResult) {
                case (.empty, .empty):
                    break

                default:
                    XCTFail("Expected retriving twice to recieve twice empty cache, but got \(firstResult) and \(secondResult) instead")
                }

                exp.fulfill()
            }
        }

        wait(for: [exp], timeout: 1.0)
    }

    func test_retrieveAfterInsertingToEmptyCache_deliversInsertedValues() {
        let sut = makeSUT()
        let feed = uniqueImageFeed().locals
        let timestamp = Date()

        let exp = expectation(description: "Wait for cache retrieval")
        sut.insert(feed, timestamp: timestamp) { insertionError in
            XCTAssertNil(insertionError, "Expected feed to be inserted successfully")
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)

        expect(sut, toRetrieve: .found(feed, timestamp))
    }

    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
        let sut = makeSUT()
        let feed = uniqueImageFeed().locals
        let timestamp = Date()
        let exp = expectation(description: "Wait for cache retrieval")

        sut.insert(feed, timestamp: timestamp) { insertionError in
            XCTAssertNil(insertionError, "Expected feed to be inserted successfully")

            sut.retrieve { firstResult in
                sut.retrieve { secondResult in
                    switch (firstResult, secondResult) {
                    case let (.found(firstFeed, firstTimestamp), .found(secondFeed, secondTimestamp)):
                        XCTAssertEqual(firstFeed, feed)
                        XCTAssertEqual(firstTimestamp, timestamp)

                        XCTAssertEqual(secondFeed, feed)
                        XCTAssertEqual(secondTimestamp, timestamp)
                    default:
                        XCTFail("Expected retrieving same result on non empty cache feed to delivers same found feed \(feed) and  timestamp \(timestamp), but got \(firstResult) and \(secondResult) instead")
                    }

                    exp.fulfill()
                }
            }
        }

        wait(for: [exp], timeout: 1.0)
    }
    // MARK: - Helpers

    private var testSpecificStoreURL: URL { FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("\(type(of: self)).store") }

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> CodableFeedStore {
        let sut = CodableFeedStore(storeURL: testSpecificStoreURL)
        trackForMemoryLeak(sut, file: file, line: line)

        return sut
    }

    private func expect(_ sut: CodableFeedStore, toRetrieve expectedResult: RetrievalResult) {
        let exp = expectation(description: "Wait for retrieve")
        sut.retrieve { recievedResult in
            switch (recievedResult, expectedResult) {
            case (.empty, .empty):
                break

            case let (.found(recievedFeed, recievedTimestamp), .found(expectedFeed, expectedTimestamp)):
                XCTAssertEqual(recievedFeed, expectedFeed)
                XCTAssertEqual(recievedTimestamp, expectedTimestamp)

            default:
                XCTFail("Expected to retrieve \(expectedResult), got \(recievedResult) instead")
            }

            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
    }

    private func setUpEmptyState() {
        deleteStoreSideEffects()
    }

    private func undoStoreSideEffects() {
        deleteStoreSideEffects()
    }

    private func deleteStoreSideEffects() {
        try? FileManager.default.removeItem(at: testSpecificStoreURL)
    }
}
