//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Eldorbek on 21/03/22.
//

import Foundation
import XCTest
import EssentialFeed

class LocalFeedLoader {
    private let store: FeedStore

    init(store: FeedStore) {
        self.store = store
    }

    public func save(_ items: [FeedImage]) {
        store.deleteCache()
    }
}

class FeedStore {
    var deleteCacheCallCount = 0

    func deleteCache() {
        deleteCacheCallCount += 1
    }
}

class CacheFeedUseCaseTests: XCTestCase {
    func test_init_doesNotDeleteCacheUponCreation() {
        let store = FeedStore()
        _ = LocalFeedLoader(store: store)

        XCTAssertEqual(store.deleteCacheCallCount, 0)
    }

    func test_save_requestsDeleteCache() {
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store)

        sut.save([uniqueItem()])

        XCTAssertEqual(store.deleteCacheCallCount, 1)
    }

    // MARK: - Helpers

    private func uniqueItem() -> FeedImage {
        return FeedImage(id: UUID(), description: "any", location: "any", url: anyURL())
    }

    private func anyURL() -> URL {
        return URL(string: "http://any-url.com")!
    }

    private func anyNSError() -> NSError {
        return NSError(domain: "any error", code: 0)
    }

}
