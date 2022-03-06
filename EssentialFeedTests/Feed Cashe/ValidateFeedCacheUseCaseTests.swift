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


    // MARK: - Helper

    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (store: FeedStoreSpy, sut: LocalFeedLoader) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        trackForMemoryLeak(sut, file: file, line: line)
        trackForMemoryLeak(store, file: file, line: line)

        return (store, sut)
    }

    private func anyNSError() -> NSError {
        return NSError(domain: "any error", code: 0)
    }
}
