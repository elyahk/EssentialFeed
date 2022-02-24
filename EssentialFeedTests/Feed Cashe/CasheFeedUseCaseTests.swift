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
    var saveCashedFeedCallCount: Int = 0

    func deleteCashedFeed() {
        deleteCashedFeedCallCount += 1
    }

    func completeWithDeletionError(_ error: Error) {

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
        let (_, feedStore) = makeSUT()
        XCTAssertEqual(feedStore.deleteCashedFeedCallCount, 0)
    }

    func test_save_deleteCashe() {
        let (sut, feedStore) = makeSUT()
        let items = [uniqueItem(), uniqueItem()]

        sut.save(items)

        XCTAssertEqual(feedStore.deleteCashedFeedCallCount, 1)
    }

    func test_save_doesNotSaveCasheUponDeletionError() {
        let (sut, feedStore) = makeSUT()
        let items = [uniqueItem(), uniqueItem()]
        let anyError = anyNSError()

        sut.save(items)
        feedStore.completeWithDeletionError(anyError)

        XCTAssertEqual(feedStore.saveCashedFeedCallCount, 0)
    }

    // MARK: - Helpers

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (LocalFeedLoader, FeedStore) {
        let feedStore = FeedStore()
        let sut = LocalFeedLoader(feedStore: feedStore)

        trackForMemoryLeak(sut, file: file, line: line)
        trackForMemoryLeak(feedStore, file: file, line: line)

        return (sut, feedStore)
    }
 
    private func uniqueItem() -> FeedItem {
        FeedItem(id: UUID(), description: "any", location: "any", imageUrl: anyURL())
    }

    private func anyURL() -> URL {
        return URL(string: "https://a-url.com")!
    }

    private func anyNSError() -> NSError {
        return NSError(domain: "any error", code: 0)
    }
}
