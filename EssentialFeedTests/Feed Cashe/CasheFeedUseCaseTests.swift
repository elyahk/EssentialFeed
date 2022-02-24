//
//  CasheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Eldorbek on 24/02/22.
//

import XCTest
import EssentialFeed

class FeedStore {
    typealias DeletionCompletion = (Error?) -> Void

    var deleteCashedFeedCallCount: Int = 0
    var saveCashedFeedCallCount: Int = 0
    var deletionCompletions: [DeletionCompletion] = []

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

    func save(_ items: [FeedItem]) {
        saveCashedFeedCallCount += 1
    }
}

class LocalFeedLoader {
    private var feedStore: FeedStore

    init(feedStore: FeedStore) {
        self.feedStore = feedStore
    }

    func save(_ items: [FeedItem]) {
        feedStore.deleteCashedFeed { [unowned self] error in
            if error == nil {
                self.feedStore.save(items)
            }
        }
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

        XCTAssertEqual(feedStore.saveCashedFeedCallCount, 0)
    }

    func test_save_saveCasheUponDeletionSuccessfully() {
        let (sut, feedStore) = makeSUT()
        let items = [uniqueItem(), uniqueItem()]

        sut.save(items)
        feedStore.completeDeletionSuccessfully()

        XCTAssertEqual(feedStore.saveCashedFeedCallCount, 1)
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
