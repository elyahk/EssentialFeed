//
//  CasheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Eldorbek on 24/02/22.
//

import XCTest
import EssentialFeed

class FeedStore {
    var deleteCashedFeedCallCount: Int = 0

    func deleteCashedFeed() {
        deleteCashedFeedCallCount += 1
    }
}

class LocalFeedLoader {
    private var feedStore: FeedStore

    init(feedStore: FeedStore) {
        self.feedStore = feedStore
    }

    func save(_ items: [FeedItem]) {
        feedStore.deleteCashedFeed()
    }
}

class CasheFeedUseCaseTests: XCTestCase {
    func test_init_doesNotDeleteCasheUponCreation() {
        let feedStore = FeedStore()
        _ = LocalFeedLoader(feedStore: feedStore)

        XCTAssertEqual(feedStore.deleteCashedFeedCallCount, 0)
    }

    func test_save_deleteCashe() {
        let feedStore = FeedStore()
        let sut = LocalFeedLoader(feedStore: feedStore)
        let items = [uniqueItem(), uniqueItem()]

        sut.save(items)

        XCTAssertEqual(feedStore.deleteCashedFeedCallCount, 1)
    }

    // MARK: - Helpers

    private func uniqueItem() -> FeedItem {
        FeedItem(id: UUID(), description: "any", location: "any", imageUrl: anyURL())
    }

    private func anyURL() -> URL {
        return URL(string: "https://a-url.com")!
    }
}
