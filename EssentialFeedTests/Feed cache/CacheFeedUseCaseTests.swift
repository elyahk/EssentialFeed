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
    private let currentDate: () -> Date

    init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }

    public func save(_ feed: [FeedImage], completion: @escaping (Error?) -> Void) {
        store.deleteCache() { [weak self] cacheDeletionError in
            guard let self = self else { return }

            if let cacheDeletionError = cacheDeletionError {
                completion(cacheDeletionError)
            } else {
                self.cache(feed, completion: completion)
            }
        }
    }

    private func cache(_ feed: [FeedImage], completion: @escaping (Error?) -> Void) {
        store.insert(feed, timestamp: currentDate()) { [weak self] error in
            guard self != nil else { return }

            completion(error)
        }
    }
}

protocol FeedStore {
    typealias DeletionCompletion = (Error?) -> Void
    typealias InsertionCompletion = (Error?) -> Void

    func deleteCache(completion: @escaping DeletionCompletion)
    func insert(_ items: [FeedImage], timestamp: Date, completion: @escaping InsertionCompletion)
}

class CacheFeedUseCaseTests: XCTestCase {
    func test_init_doesNotDeleteCacheUponCreation() {
        let (_, store) = makeSUT()

        XCTAssertEqual(store.recievedMessages, [])
    }

    func test_save_requestsDeleteCache() {
        let (sut, store) = makeSUT()

        sut.save([uniqueItem()]){ _ in }

        XCTAssertEqual(store.recievedMessages, [.deleteCacheFeed])
    }

    func test_save_doesNotRequestInsertionOnDeletionError() {
        let (sut, store) = makeSUT()
        let deletionError = anyNSError()

        sut.save([uniqueItem()]){ _ in }
        store.completeDeletion(with: deletionError)

        XCTAssertEqual(store.recievedMessages, [.deleteCacheFeed])
    }

    func test_save_requestsInsertNewCacheWithTiemstampOnDeletionSuccessfully() {
        let timestamp = Date()
        let (sut, store) = makeSUT(currentDate: { timestamp })
        let feed = [uniqueItem()]

        sut.save(feed) { _ in }
        store.completeDeletionSuccessfully()

        XCTAssertEqual(store.recievedMessages, [.deleteCacheFeed, .insert(feed, timestamp)])
    }

    func test_save_failsOnDeletionError () {
        let (sut, store) = makeSUT()
        let deletionError = anyNSError()

        expect(sut, toCompleteWith: deletionError, when: {
            store.completeDeletion(with: deletionError)
        })
    }

    func test_save_failsOnInsertionError () {
        let (sut, store) = makeSUT()
        let insertionError = anyNSError()

        expect(sut, toCompleteWith: insertionError, when: {
            store.completeDeletionSuccessfully()
            store.completeInsertion(with: insertionError)
        })
    }

    func test_save_successedsOnSuccess () {
        let (sut, store) = makeSUT()

        expect(sut, toCompleteWith: nil, when: {
            store.completeDeletionSuccessfully()
            store.completeInsertionSuccessfully()
        })
    }

    func test_save_doesNotDeliverDeletionErrorAfterSUTInstanceHasBeenDeallocated() {
        let currentDate = Date()
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: { currentDate })

        var recievedError: Error?
        sut?.save([uniqueItem()], completion: { error in
            recievedError = error
        })

        sut = nil
        store.completeDeletion(with: anyNSError())

        XCTAssertNil(recievedError)
    }

    func test_save_doesNotDeliverInsertionErrorAfterSUTInstanceHasBeenDeallocated() {
        let currentDate = Date()
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: { currentDate })

        var recievedError: Error?
        sut?.save([uniqueItem()], completion: { error in
            recievedError = error
        })

        store.completeDeletionSuccessfully()
        sut = nil
        store.completeInsertion(with: anyNSError())

        XCTAssertNil(recievedError)
    }

    // MARK: - Helpers

    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (LocalFeedLoader, FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)

        trackForMemoryLeak(sut, file: file, line: line)
        trackForMemoryLeak(store, file: file, line: line)

        return (sut, store)
    }

    private func expect(_ sut: LocalFeedLoader, toCompleteWith expectedError: NSError?, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        var recievedError: Error?
        let exp = expectation(description: "Wait for fails")
        sut.save([uniqueItem()]) { error in
            recievedError = error
            exp.fulfill()
        }

        action()
        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(recievedError as NSError?, expectedError, file: file, line: line)
    }

    private func uniqueItem() -> FeedImage {
        return FeedImage(id: UUID(), description: "any", location: "any", url: anyURL())
    }

    private func anyURL() -> URL {
        return URL(string: "http://any-url.com")!
    }

    private func anyNSError() -> NSError {
        return NSError(domain: "any error", code: 0)
    }

    private class FeedStoreSpy: FeedStore {

        var deletionCompletions: [DeletionCompletion] = []
        var insertionCompletions: [InsertionCompletion] = []

        enum RecievedMessage: Equatable {
            case deleteCacheFeed
            case insert([FeedImage], Date)
        }

        private(set) var recievedMessages: [RecievedMessage] = []

        func deleteCache(completion: @escaping DeletionCompletion) {
            deletionCompletions.append(completion)
            recievedMessages.append(.deleteCacheFeed)
        }

        func completeDeletion(with error: NSError, at index: Int = 0) {
            deletionCompletions[index](error)
        }

        func completeDeletionSuccessfully(at index: Int = 0) {
            deletionCompletions[index](nil)
        }

        func insert(_ items: [FeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
            recievedMessages.append(.insert(items, timestamp))
            insertionCompletions.append(completion)
        }

        func completeInsertion(with error: Error, at index: Int = 0) {
            insertionCompletions[index](error)
        }

        func completeInsertionSuccessfully(at index: Int = 0) {
            insertionCompletions[index](nil)
        }
    }
}
