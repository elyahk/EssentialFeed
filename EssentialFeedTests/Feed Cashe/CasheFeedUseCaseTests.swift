//
//  CasheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Eldorbek on 24/02/22.
//

import XCTest
import EssentialFeed

class CasheFeedUseCaseTests: XCTestCase {
    func test_init_doesNotDeleteCasheUponCreation() {
        let (_, feedStore) = makeSUT()
        XCTAssertEqual(feedStore.recievedMessage, [])
    }

    func test_save_deleteCashe() {
        let (sut, feedStore) = makeSUT()

        sut.save(uniqueImageFeed().models) { _ in }

        XCTAssertEqual(feedStore.recievedMessage, [.deletion])
    }

    func test_save_doesNotSaveCasheUponDeletionError() {
        let (sut, feedStore) = makeSUT()
        let anyError = anyNSError()

        sut.save(uniqueImageFeed().models) { _ in }
        feedStore.completeDeletion(with: anyError)

        XCTAssertEqual(feedStore.recievedMessage, [.deletion])
    }

    func test_save_saveCasheWithTimeStampUponDeletionSuccessfully() {
        let timestamp = Date()
        let (sut, feedStore) = makeSUT(currentTimestamp: { timestamp } )
        let uniuqueImageFeed = uniqueImageFeed()

        sut.save(uniuqueImageFeed.models) { _ in }
        feedStore.completeDeletionSuccessfully()

        XCTAssertEqual(feedStore.recievedMessage, [.deletion, .insert(uniuqueImageFeed.local, timestamp)])
    }

    func test_save_failsUponDeletionError() {
        let (sut, feedStore) = makeSUT()
        let anyError = anyNSError()

        assert(sut, toCompleteWith: anyError, when: {
            feedStore.completeDeletion(with: anyError)
        })
    }

    func test_save_failsUponInsertionError() {
        let (sut, feedStore) = makeSUT()
        let anyError = anyNSError()

        assert(sut, toCompleteWith: anyError, when: {
            feedStore.completeDeletionSuccessfully()
            feedStore.completeInsertion(with: anyError)
        })
    }

    func test_save_succedsOnSuccessfulCasheInsertion() {
        let (sut, feedStore) = makeSUT()

        assert(sut, toCompleteWith: nil, when: {
            feedStore.completeDeletionSuccessfully()
            feedStore.completeInsertionSuccessfully()
        })
    }

    func test_save_doesNotDeliverDeletionErrorAfterSUTInstanceHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(feedStore: store, currentTimestamp: Date.init)

        var recieveResults: [LocalFeedLoader.SaveResult] = []
        sut?.save(uniqueImageFeed().models) { recieveResults.append($0) }
        sut = nil

        store.completeDeletion(with: anyNSError())

        XCTAssertTrue(recieveResults.isEmpty)
    }

    func test_save_doesNotDeliverInsertionErrorAfterSUTInstanceHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(feedStore: store, currentTimestamp: Date.init)

        var recieveResults: [Error?] = []
        sut?.save(uniqueImageFeed().models) { recieveResults.append($0) }

        store.completeDeletionSuccessfully()
        sut = nil
        store.completeInsertion(with: anyNSError())

        XCTAssertTrue(recieveResults.isEmpty)
    }


    // MARK: - Helpers

    private func makeSUT(currentTimestamp: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (LocalFeedLoader, FeedStoreSpy) {
        let feedStore = FeedStoreSpy()
        let sut = LocalFeedLoader(feedStore: feedStore, currentTimestamp: currentTimestamp)

        trackForMemoryLeak(sut, file: file, line: line)
        trackForMemoryLeak(feedStore, file: file, line: line)

        return (sut, feedStore)
    }

    private func assert(_ sut: LocalFeedLoader, toCompleteWith expectedError: NSError?, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "Wait for completion")
        var recivedError: Error?
        sut.save(uniqueImageFeed().models) { error in
            recivedError = error
            exp.fulfill()
        }

        action()
        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(recivedError as NSError?, expectedError)
    }

    private func uniqueImageFeed() -> (local: [LocalFeedImage], models: [FeedImage]) {
        let feed = [uniqueFeedImage(), uniqueFeedImage()]
        let localFeed = feed.map { LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.imageUrl) }

        return (localFeed, feed)
    }

    private func uniqueFeedImage() -> FeedImage {
        FeedImage(id: UUID(), description: "any", location: "any", url: anyURL())
    }

    private func anyURL() -> URL {
        return URL(string: "https://a-url.com")!
    }

    private func anyNSError() -> NSError {
        return NSError(domain: "any error", code: 0)
    }

    // MARK: - FeedStoreSpy

    private class FeedStoreSpy: FeedStore {
        enum Message: Equatable {
            case deletion
            case insert([LocalFeedImage], Date)
        }

        var deletionCompletions: [DeletionCompletion] = []
        var insertionCompletions: [InsertionCompletion] = []

        var recievedMessage: [Message] = []

        func deleteCashedFeed(completion: @escaping DeletionCompletion) {
            deletionCompletions.append(completion)
            recievedMessage.append(.deletion)
        }

        func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
            insertionCompletions.append(completion)
            recievedMessage.append(.insert(feed, timestamp))
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
}
