//
//  CasheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Eldorbek on 24/02/22.
//

import XCTest

class FeedStore {
    var deleteCashedFeedCallCount: Int = 0
}

class LocalFeedLoader {
    private var feedStore: FeedStore

    init(feedStore: FeedStore) {
        self.feedStore = feedStore
    }
}

class CasheFeedUseCaseTests: XCTestCase {
    func test_() {
        let feedStore = FeedStore()
        _ = LocalFeedLoader(feedStore: feedStore)

        XCTAssertEqual(feedStore.deleteCashedFeedCallCount, 0)
    }
}
