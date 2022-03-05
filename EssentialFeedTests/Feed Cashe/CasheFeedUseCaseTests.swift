//
//  CasheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Eldorbek on 05/03/22.
//

import Foundation
import XCTest
@testable import EssentialFeed

class LocalFeedLoader {
    let store: FeedStore
    init (store: FeedStore) {
        self.store = store
    }

    func save(_ items: [FeedImage]) {
        store.deleteCashedFeed()
    }
}

class FeedStore {
    var deleteCashedFeedCallCount: Int = 0
    var insertCallCount: Int = 0

    func deleteCashedFeed() {
        deleteCashedFeedCallCount += 1
    }

    func completeDeletion(with error: Error, at index: Int = 0) {

    }
}

class CasheFeedUseCaseTests: XCTestCase {
    func test_init_doesNotDeleteCasheUponCreation() {
        let (store, _) = makeSUT()

        XCTAssertEqual(store.deleteCashedFeedCallCount, 0)
    }

    func test_save_requestCacheDeletion() {
        let (store, sut) = makeSUT()
        let items = [uniqueItem(), uniqueItem()]

        sut.save(items)

        XCTAssertEqual(store.deleteCashedFeedCallCount, 1)
    }

    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let (store, sut) = makeSUT()
        let items = [uniqueItem(), uniqueItem()]
        let deletionError = anyNSError()

        sut.save(items)
        store.completeDeletion(with: deletionError)

        XCTAssertEqual(store.insertCallCount, 0)
    }

    // MARK: - Helper

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (store: FeedStore, sut: LocalFeedLoader) {
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store)
        trackForMemoryLeak(sut, file: file, line: line)
        trackForMemoryLeak(store, file: file, line: line)

        return (store, sut)
    }

    private func uniqueItem() -> FeedImage {
        return FeedImage(id: UUID(), description: "any description", location: "any location", url: anyURL())
    }

    private func anyURL() -> URL {
        return URL(string: "https://a-url.com")!
    }

    private func anyNSError() -> NSError {
        return NSError(domain: "any error", code: 0)
    }
}
