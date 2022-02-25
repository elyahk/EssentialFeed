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

    func save(_ items: [FeedItem], completion: @escaping (Error?) -> Void) {
        feedStore.deleteCashedFeed { [unowned self] error in
            if error == nil {
                self.feedStore.insert(items, timestamp: currentTimestamp(), completion: completion)
            } else {
                completion(error)
            }
        }
    }
}

class FeedStore {
    typealias DeletionCompletion = (Error?) -> Void
    typealias InsertionCompletion = (Error?) -> Void

    enum Message: Equatable {
        case deletion
        case insert([FeedItem], Date)
    }

    var deletionCompletions: [DeletionCompletion] = []
    var insertionCompletions: [InsertionCompletion] = []

    var recievedMessage: [Message] = []

    func deleteCashedFeed(completion: @escaping DeletionCompletion) {
        deletionCompletions.append(completion)
        recievedMessage.append(.deletion)
    }

    func insert(_ items: [FeedItem], timestamp: Date, completion: @escaping InsertionCompletion) {
        insertionCompletions.append(completion)
        recievedMessage.append(.insert(items, timestamp))
    }

    func completeDeletion(with error: Error, at index: Int = 0) {
        deletionCompletions[index](error)
    }

    func completeDeletionSuccessfully(at index: Int = 0) {
        deletionCompletions[index](nil)
    }

    func completeInsertion(with error: Error, at index: Int = 0) {
        insertionCompletions[index](error)
    }

    func completeInsertionSuccessfully(at index: Int = 0) {
        insertionCompletions[index](nil)
    }
}

class CasheFeedUseCaseTests: XCTestCase {
    func test_init_doesNotDeleteCasheUponCreation() {
        let (_, feedStore) = makeSUT()
        XCTAssertEqual(feedStore.recievedMessage, [])
    }

    func test_save_deleteCashe() {
        let (sut, feedStore) = makeSUT()
        let items = [uniqueItem(), uniqueItem()]

        sut.save(items) { _ in }

        XCTAssertEqual(feedStore.recievedMessage, [.deletion])
    }

    func test_save_doesNotSaveCasheUponDeletionError() {
        let (sut, feedStore) = makeSUT()
        let items = [uniqueItem(), uniqueItem()]
        let anyError = anyNSError()

        sut.save(items) { _ in }
        feedStore.completeDeletion(with: anyError)

        XCTAssertEqual(feedStore.recievedMessage, [.deletion])
    }

    func test_save_saveCasheWithTimeStampUponDeletionSuccessfully() {
        let timestamp = Date()
        let (sut, feedStore) = makeSUT(currentTimestamp: { timestamp } )
        let items = [uniqueItem(), uniqueItem()]

        sut.save(items) { _ in }
        feedStore.completeDeletionSuccessfully()

        XCTAssertEqual(feedStore.recievedMessage, [.deletion, .insert(items, timestamp)])
    }

    func test_save_failsUponDeletionError() {
        let (sut, feedStore) = makeSUT()
        let items = [uniqueItem(), uniqueItem()]
        let anyError = anyNSError()

        let exp = expectation(description: "Wait for completion")
        var recivedError: Error?
        sut.save(items) { error in
            recivedError = error
            exp.fulfill()
        }
        feedStore.completeDeletion(with: anyError)

        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(feedStore.recievedMessage, [.deletion])
        XCTAssertEqual(recivedError as NSError?, anyError)
    }

    func test_save_failsUponInsertionError() {
        let (sut, feedStore) = makeSUT()
        let items = [uniqueItem(), uniqueItem()]
        let anyError = anyNSError()

        let exp = expectation(description: "Wait for completion")
        var recivedError: Error?
        sut.save(items) { error in
            recivedError = error
            exp.fulfill()
        }

        feedStore.completeDeletionSuccessfully()
        feedStore.completeInsertion(with: anyError)
        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(recivedError as NSError?, anyError)
    }

    func test_save_succedsOnSuccessfulCasheInsertion() {
        let (sut, feedStore) = makeSUT()
        let items = [uniqueItem(), uniqueItem()]

        let exp = expectation(description: "Wait for completion")
        var recivedError: Error?
        sut.save(items) { error in
            recivedError = error
            exp.fulfill()
        }

        feedStore.completeDeletionSuccessfully()
        feedStore.completeInsertionSuccessfully()
        wait(for: [exp], timeout: 1.0)

        XCTAssertNil(recivedError)
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
