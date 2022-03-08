//
//  CodableFeedStore.swift
//  EssentialFeedTests
//
//  Created by Eldorbek on 08/03/22.
//

import Foundation
import XCTest
import EssentialFeed

class CodableFeedStoreTests: XCTestCase, FailableFeedStore {
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

        expect(sut, toRetrieve: .failure(anyNSError()))
    }

    func test_retrieve_hasNoSideEffectsOnInvalidCache() {
        let storeURL = testSpecificStoreURL
        let sut = makeSUT(storeURL: storeURL)

        try! "Invalid data".write(to: storeURL, atomically: false, encoding: .utf8)

        expect(sut, toRetrieveTwice: .failure(anyNSError()))
    }

    func test_insert_overridesPreviouslyInsertedCacheValues() {
        let sut = makeSUT()

        let firstInsertionError = insert(feed: uniqueImageFeed().locals, timestamp: Date(), to: sut)
        XCTAssertNil(firstInsertionError, "Expected insert successfully")

        let latesFeed = uniqueImageFeed().locals
        let latesTimestamp = Date()
        let latestInsertionError = insert(feed: latesFeed, timestamp: latesTimestamp, to: sut)
        XCTAssertNil(latestInsertionError, "Expected successfully override data")

        expect(sut, toRetrieveTwice: .found(latesFeed, latesTimestamp))
    }

    func test_insert_deliversErrorOnInsertionError() {
        let invalidStoreURL = URL(string: "invalid://store-url")!
        let sut = makeSUT(storeURL: invalidStoreURL)
        let feed = uniqueImageFeed().locals
        let timestamp = Date()

        let firstInsertionError = insert(feed: feed, timestamp: timestamp, to: sut)

        XCTAssertNotNil(firstInsertionError, "Expected insertion error")
    }

    func test_insert_noSideEffectsOnInsertionError() {
        let invalidStoreURL = URL(string: "invalid://store-url")!
        let sut = makeSUT(storeURL: invalidStoreURL)
        let feed = uniqueImageFeed().locals
        let timestamp = Date()

        insert(feed: feed, timestamp: timestamp, to: sut)

        expect(sut, toRetrieve: .empty)
    }

    func test_delete_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()

        let deletionError = deleteCache(from: sut)

        XCTAssertNil(deletionError, "Expected delete succeed")
        expect(sut, toRetrieve: .empty)
    }

    func test_delete_nonEmptyCacheI() {
        let sut = makeSUT()

        insert(feed: uniqueImageFeed().locals, timestamp: Date(), to: sut)
        let deletionError = deleteCache(from: sut)

        XCTAssertNil(deletionError, "Expected delete succeed")
        expect(sut, toRetrieve: .empty)
    }

    func test_delete_deliversErrorOnDeletionError() {
        let nonDeletePermissionURL = documentStoreURL
        let sut = makeSUT(storeURL: nonDeletePermissionURL)

        let deletionError = deleteCache(from: sut)

        XCTAssertNotNil(deletionError, "Expected delete error")
    }

    func test_delete_noSideEffectsOnDeletionError() {
        let nonDeletePermissionURL = documentStoreURL
        let sut = makeSUT(storeURL: nonDeletePermissionURL)

        deleteCache(from: sut)

        expect(sut, toRetrieve: .empty)
    }

    func test_storeSideEffects_runSerially() {
        let sut = makeSUT()
        var completedOperationsInOrder = [XCTestExpectation]()

        let op1 = expectation(description: "Wait for insertion")
        sut.insert([], timestamp: Date()) { _ in
            completedOperationsInOrder.append(op1)
            op1.fulfill()
        }

        let op2 = expectation(description: "Wait for deletion")
        sut.deleteCashedFeed { _ in
            completedOperationsInOrder.append(op2)
            op2.fulfill()
        }

        let op3 = expectation(description: "Wait for retrieving")
        sut.retrieve { _ in
            completedOperationsInOrder.append(op3)
            op3.fulfill()
        }

        waitForExpectations(timeout: 5.0)

        XCTAssertEqual(completedOperationsInOrder, [op1, op2, op3])
    }


    // MARK: - Helpers

    private var testSpecificStoreURL: URL { FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("\(type(of: self)).store") }
    private var documentStoreURL: URL { FileManager.default.urls(for: .cachesDirectory, in: .systemDomainMask).first! }

    private func makeSUT(storeURL: URL? = nil, file: StaticString = #filePath, line: UInt = #line) -> FeedStore {
        let sut = CodableFeedStore(storeURL: storeURL ?? testSpecificStoreURL)
        trackForMemoryLeak(sut, file: file, line: line)

        return sut
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
