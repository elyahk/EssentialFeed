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
    init (store: FeedStore) {

    }
}

class FeedStore {
    var deleteCashedFeedCallCount: Int = 0
}

class CasheFeedUseCaseTests: XCTestCase {
    func test_init_doesNotDeleteCasheUponCreation() {
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store)

        XCTAssertEqual(store.deleteCashedFeedCallCount, 0)
    }
}
