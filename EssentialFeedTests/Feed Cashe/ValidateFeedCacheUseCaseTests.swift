//
//  ValidateFeedCacheUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Eldorbek on 06/03/22.
//

import Foundation
import XCTest
import EssentialFeed

class ValidateFeedCacheUseCaseTests: XCTestCase {
    func test_init_doesNotMessageUponCreation() {
        let (store, _) = makeSUT()

        XCTAssertEqual(store.recievedMessages, [])
    }

    func test_validateCache_deletesCacheOnRetrievalError() {
        let (store, sut) = makeSUT()

        sut.validateCache()

        store.completeRetrieval(with: anyNSError())

        XCTAssertEqual(store.recievedMessages, [.retrieve, .deleteCachedFeed])
    }

    func test_validateCache_doesNotDeleteCacheOnEmptyCache() {
        let (store, sut) = makeSUT()

        sut.validateCache()

        store.completeRetrievalWithEmptyCache()

        XCTAssertEqual(store.recievedMessages, [.retrieve])
    }

    func test_validateCache_doesNotDeleteCacheOnNonExpiredDateCache() {
        let currentDate = Date()
        let (store, sut) = makeSUT(currentDate: { currentDate })

        sut.validateCache()

        let lessThanSevenDays = currentDate.minusFeedCacheMaxAge().adding(seconds: 1)
        store.completeRetrieval(with: uniqueImageFeed().locals, timestamp: lessThanSevenDays)

        XCTAssertEqual(store.recievedMessages, [.retrieve])
    }

    func test_validateCache_deleteCacheOnExpirationDateCache() {
        let currentDate = Date()
        let (store, sut) = makeSUT(currentDate: { currentDate })

        sut.validateCache()

        let lessThanSevenDays = currentDate.minusFeedCacheMaxAge()
        store.completeRetrieval(with: uniqueImageFeed().locals, timestamp: lessThanSevenDays)

        XCTAssertEqual(store.recievedMessages, [.retrieve, .deleteCachedFeed])
    }

    func test_validateCache_deleteCacheOnExpiredDateCache() {
        let currentDate = Date()
        let (store, sut) = makeSUT(currentDate: { currentDate })

        sut.validateCache()

        let lessThanSevenDays = currentDate.minusFeedCacheMaxAge().adding(days: -1)
        store.completeRetrieval(with: uniqueImageFeed().locals, timestamp: lessThanSevenDays)

        XCTAssertEqual(store.recievedMessages, [.retrieve, .deleteCachedFeed])
    }

    func test_validateCache_doesNotDeleteInvalidCacheAfterSUTInstanceHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = .init(store: store, currentDate: Date.init)

        sut?.validateCache()

        sut = nil
        store.completeRetrieval(with: anyNSError())

        XCTAssertEqual(store.recievedMessages, [.retrieve])
    }

    // MARK: - Helper

    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (store: FeedStoreSpy, sut: LocalFeedLoader) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        trackForMemoryLeak(sut, file: file, line: line)
        trackForMemoryLeak(store, file: file, line: line)

        return (store, sut)
    }
}

