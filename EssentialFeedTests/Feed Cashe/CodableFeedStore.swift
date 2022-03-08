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

        do {
            let decoder = JSONDecoder()
            let cache = try decoder.decode(Cache.self, from: data)
            completion(.found(cache.feedLocal, cache.timestamp))
        } catch {
            completion(.failure(error))
        }
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

        expect(sut, toRetrieveTwice: .empty)
    }

    func test_retrieve_deliversFoundValuesOnNonEmptyCache() {
        let sut = makeSUT()
        let feed = uniqueImageFeed().locals
        let timestamp = Date()

        insert(feed: feed, timestamp: timestamp, to: sut)

        expect(sut, toRetrieve: .found(feed, timestamp))
    }

    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
        let sut = makeSUT()
        let feed = uniqueImageFeed().locals
        let timestamp = Date()

        insert(feed: feed, timestamp: timestamp, to: sut)

        expect(sut, toRetrieveTwice: .found(feed, timestamp))
    }

    func test_retrieve_deliversErrorOnInvalidCache() {
        let storeURL = testSpecificStoreURL
        let sut = makeSUT(storeURL: storeURL)

        try! "Invalid data".write(to: storeURL, atomically: false, encoding: .utf8)

        expect(sut, toRetrieveTwice: .failure(anyNSError()))
    }

    // MARK: - Helpers

    private var testSpecificStoreURL: URL { FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("\(type(of: self)).store") }

    private func makeSUT(storeURL: URL? = nil, file: StaticString = #filePath, line: UInt = #line) -> CodableFeedStore {
        let sut = CodableFeedStore(storeURL: storeURL ?? testSpecificStoreURL)
        trackForMemoryLeak(sut, file: file, line: line)

        return sut
    }

    private func insert(feed: [LocalFeedImage], timestamp: Date, to sut: CodableFeedStore) {
        let exp = expectation(description: "Wait for cache retrieval")
        sut.insert(feed, timestamp: timestamp) { insertionError in
            XCTAssertNil(insertionError, "Expected feed to be inserted successfully")
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }

    private func expect(_ sut: CodableFeedStore, toRetrieveTwice expectedResult: RetrievalResult) {
        expect(sut, toRetrieve: expectedResult)
        expect(sut, toRetrieve: expectedResult)
    }

    private func expect(_ sut: CodableFeedStore, toRetrieve expectedResult: RetrievalResult) {
        let exp = expectation(description: "Wait for retrieve")
        sut.retrieve { recievedResult in
            switch (recievedResult, expectedResult) {
            case (.empty, .empty), (.failure, .failure):
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
