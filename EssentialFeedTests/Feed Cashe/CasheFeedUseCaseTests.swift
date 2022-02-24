//
//  CasheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Eldorbek on 24/02/22.
//

import XCTest
import EssentialFeed


class LocalFeedLoader {
    private var feedStore: FeedStore
    private var currentTimestamp: () -> Date

    init(feedStore: FeedStore, currentTimestamp: @escaping () -> Date) {
        self.feedStore = feedStore
        self.currentTimestamp = currentTimestamp
    }

    func save(_ items: [FeedItem]) {
        feedStore.deleteCashedFeed { [unowned self] error in
            if error == nil {
                self.feedStore.insert(items, timestamp: currentTimestamp())
            }
        }
    }
}

class FeedStore {
    typealias DeletionCompletion = (Error?) -> Void

    var deleteCashedFeedCallCount: Int = 0
    var deletionCompletions: [DeletionCompletion] = []
    var insertions = [(items: [FeedItem], timestamp: Date)]()

    func deleteCashedFeed(completion: @escaping DeletionCompletion) {
        deleteCashedFeedCallCount += 1
        deletionCompletions.append(completion)
    }

    func completeDeletion(with error: Error, at index: Int = 0) {
        deletionCompletions[index](error)
    }

    func completeDeletionSuccessfully(at index: Int = 0) {
        deletionCompletions[index](nil)
    }

    func insert(_ items: [FeedItem], timestamp: Date) {
        insertions.append((items, timestamp))
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
        feedStore.completeDeletion(with: anyError)

        XCTAssertEqual(feedStore.insertions.count, 0)
    }

    func test_save_saveCasheWithTimeStampUponDeletionSuccessfully() {
        let timestamp = Date()
        let (sut, feedStore) = makeSUT(currentTimestamp: { timestamp } )
        let items = [uniqueItem(), uniqueItem()]

        sut.save(items)
        feedStore.completeDeletionSuccessfully()

        XCTAssertEqual(feedStore.insertions.count, 1)
        XCTAssertEqual(feedStore.insertions.first?.items, items)
        XCTAssertEqual(feedStore.insertions.first?.timestamp, timestamp)
    }

    // MARK: - Helpers

    private func makeSUT(currentTimestamp: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (LocalFeedLoader, FeedStore) {
        let feedStore = FeedStore()
        let sut = LocalFeedLoader(feedStore: feedStore, currentTimestamp: currentTimestamp)

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
