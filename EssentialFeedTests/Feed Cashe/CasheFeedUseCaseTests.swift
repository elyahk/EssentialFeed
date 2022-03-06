//
//  CasheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Eldorbek on 05/03/22.
//

import Foundation
import XCTest
@testable import EssentialFeed

class CasheFeedUseCaseTests: XCTestCase {
    func test_init_doesNotMessageUponCreation() {
        let (store, _) = makeSUT()

        XCTAssertEqual(store.recievedMessages, [])
    }

    func test_save_requestCacheDeletion() {
        let (store, sut) = makeSUT()

        sut.save(uniqueImageFeed().models) { _ in }

        XCTAssertEqual(store.recievedMessages, [.deleteCachedFeed])
    }

    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let (store, sut) = makeSUT()
        let deletionError = anyNSError()

        sut.save(uniqueImageFeed().models) { _ in }
        store.completeDeletion(with: deletionError)

        XCTAssertEqual(store.recievedMessages, [.deleteCachedFeed])
    }

    func test_save_requestNewCacheInsertionWithTimeStampOnSuccessfulDeletion() {
        let currentDate = Date()
        let (store, sut) = makeSUT(currentDate: { currentDate })
        let feed = uniqueImageFeed()

        sut.save(feed.models) { _ in }
        store.completeDeletionSuccessfully()

        XCTAssertEqual(store.recievedMessages, [.deleteCachedFeed, .insert(feed: feed.locals, timestamp: currentDate)])
    }

    func test_save_failsOnDeletionError() {
        let (store, sut) = makeSUT()
        let deletionError = anyNSError()

        expect(sut, toCompleteWith: deletionError, when: {
            store.completeDeletion(with: deletionError)
        })
    }

    func test_save_failsOnInsertionError() {
        let (store, sut) = makeSUT()
        let insertionError = anyNSError()

        expect(sut, toCompleteWith: insertionError, when: {
            store.completeDeletionSuccessfully()
            store.completeInsertion(with: insertionError)
        })
    }

    func test_save_succedsOnSuccessfully() {
        let (store, sut) = makeSUT()

        expect(sut, toCompleteWith: nil, when: {
            store.completeDeletionSuccessfully()
            store.completeInsertionSuccessfully()
        })
    }

    func test_save_doesNotDeliverDeletionErrorAfterSUTInstanceHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)

        var recievedResults: [LocalFeedLoader.SaveResult] = []
        sut?.save(uniqueImageFeed().models, completion: { error in
            recievedResults.append(error)
        })

        sut = nil
        store.completeDeletion(with: anyNSError())

        XCTAssertTrue(recievedResults.isEmpty)
    }

    func test_save_doesNotDeliverInsertionErrorAfterSUTInstanceHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)

        var recievedResults: [LocalFeedLoader.SaveResult] = []
        sut?.save(uniqueImageFeed().models, completion: { error in
            recievedResults.append(error)
        })

        store.completeDeletionSuccessfully()
        sut = nil
        store.completeInsertion(with: anyNSError())

        XCTAssertTrue(recievedResults.isEmpty)
    }

    // MARK: - Helper

    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (store: FeedStoreSpy, sut: LocalFeedLoader) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        trackForMemoryLeak(sut, file: file, line: line)
        trackForMemoryLeak(store, file: file, line: line)

        return (store, sut)
    }

    private func expect(_ sut: LocalFeedLoader, toCompleteWith expectedError: NSError?, when action: () -> Void) {
        let exp = expectation(description: "Wait for deletion error")

        var recievedError: Error?
        sut.save(uniqueImageFeed().models) { error in
            recievedError = error
            exp.fulfill()
        }

        action()
        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(recievedError as NSError?, expectedError)
    }

    private class FeedStoreSpy: FeedStore {
        enum RecievedMessage: Equatable {
            case deleteCachedFeed
            case insert(feed: [LocalFeedImage], timestamp: Date)
        }

        private(set) var recievedMessages: [RecievedMessage] = []

        private var deletionCompletions: [DeletionCompletion] = []
        private var insertionCompletions: [InsertionCompletion] = []

        func deleteCashedFeed(completion: @escaping DeletionCompletion) {
            deletionCompletions.append(completion)
            recievedMessages.append(.deleteCachedFeed)
        }

        func completeDeletion(with error: Error, at index: Int = 0) {
            deletionCompletions[index](error)
        }

        func completeDeletionSuccessfully(at index: Int = 0) {
            deletionCompletions[index](nil)
        }

        func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
            insertionCompletions.append(completion)
            recievedMessages.append(.insert(feed: feed, timestamp: timestamp))
        }

        func completeInsertion(with error: Error, at index: Int = 0) {
            insertionCompletions[index](error)
        }

        func completeInsertionSuccessfully(at index: Int = 0) {
            insertionCompletions[index](nil)
        }
    }

    private func uniqueImage() -> FeedImage {
        return FeedImage(id: UUID(), description: "any description", location: "any location", url: anyURL())
    }

    private func uniqueImageFeed() -> (models: [FeedImage], locals: [LocalFeedImage]) {
        let feed = [uniqueImage()]
        let localFeed = feed.map { LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url)}

        return (feed, localFeed)
    }

    private func anyURL() -> URL {
        return URL(string: "https://a-url.com")!
    }

    private func anyNSError() -> NSError {
        return NSError(domain: "any error", code: 0)
    }
}
