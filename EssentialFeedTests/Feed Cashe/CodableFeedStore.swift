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
        let feed: [LocalFeedImage]
        let timestamp: Date
    }

    private let storURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("image-feed.store")

    func retrieve(completion: @escaping FeedStore.RetrievalCompletion) {
        guard let data = try? Data(contentsOf: storURL) else { return completion(.empty) }

        let decoder = JSONDecoder()
        let cache = try! decoder.decode(Cache.self, from: data)
        completion(.found(cache.feed, cache.timestamp))
    }

    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping FeedStore.InsertionCompletion) {
        let encoder = JSONEncoder()
        let encoded = try! encoder.encode(Cache(feed: feed, timestamp: timestamp))
        try! encoded.write(to: storURL)
        completion(nil)
    }
}

class CodableFeedStoreTests: XCTestCase {
    override func setUp() {
        super.setUp()

        let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("image-feed.store")
        try? FileManager.default.removeItem(at: storeURL)
    }

    override func tearDown() {
        super.tearDown()

        let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("image-feed.store")
        try? FileManager.default.removeItem(at: storeURL)
    }

    func test_retrieve_delieversEmptyOnEmptyCache() {
        let sut = CodableFeedStore()

        let exp = expectation(description: "Wait for retrieve")
        sut.retrieve { result in
            switch result {
            case .empty:
                break

            default:
                XCTFail("Expected empty result, got \(result) instead")
            }

            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
    }

    func test_retrieve_hasNoSideEffectOnEmptyCache() {
        let sut = CodableFeedStore()

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
        let sut = CodableFeedStore()
        let feed = uniqueImageFeed().locals
        let timestamp = Date()
        let exp = expectation(description: "Wait for cache retrieval")

        sut.insert(feed, timestamp: timestamp) { insertionError in
            XCTAssertNil(insertionError, "Expected feed to be inserted successfully")

            sut.retrieve { result in
                switch result {
                case let .found(retrievedFeed, retrievedTimestamp):
                    XCTAssertEqual(retrievedFeed, feed)
                    XCTAssertEqual(retrievedTimestamp, timestamp)

                default:
                    XCTFail("Expected retriving feed and timestamp, but got \(result) instead")
                }

                exp.fulfill()
            }
        }

        wait(for: [exp], timeout: 1.0)
    }
}
