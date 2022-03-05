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

    func deleteCashedFeed() {
        deleteCashedFeedCallCount += 1
    }
}

class CasheFeedUseCaseTests: XCTestCase {
    func test_init_doesNotDeleteCasheUponCreation() {
        let store = FeedStore()
        let _ = LocalFeedLoader(store: store)

        XCTAssertEqual(store.deleteCashedFeedCallCount, 0)
    }

    func test_save_requestCacheDeletion() {
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store)
        let items = [uniqueItem(), uniqueItem()]

        sut.save(items)

        XCTAssertEqual(store.deleteCashedFeedCallCount, 1)
    }

    // MARK: - Helper

    private func uniqueItem() -> FeedImage {
        return FeedImage(id: UUID(), description: "any description", location: "any location", url: anyURL())
    }

    private func anyURL() -> URL {
        return URL(string: "https://a-url.com")!
    }
}
