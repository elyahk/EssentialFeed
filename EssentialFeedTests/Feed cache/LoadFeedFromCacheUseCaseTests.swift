//
//  LoadFeedCacheUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Eldorbek on 23/03/22.
//


import XCTest
import EssentialFeed

class LoadFeedFromCacheUseCaseTests: XCTestCase {
//    func test_init_doesNotDeleteCacheUponCreation() {
//        let (_, store) = makeSUT()
//
//        XCTAssertEqual(store.recievedMessages, [])
//    }
//
//    func test_load_requestCacheRetrieval() {
//        let (sut, store) = makeSUT()
//
//        sut.load() { _ in }
//
//        XCTAssertEqual(store.recievedMessages, [.retrieve])
//    }
//
//    func test_load_failsOnRetrievalError() {
//        let (sut, store) = makeSUT()
//        let retrievalError = anyNSError()
//
//        expect(sut, toCompleteWith: .failure(retrievalError), when: {
//            store.completeRetrieval(with: retrievalError)
//        })
//    }
//
//    func test_load_deliversNoImagesOnEmptyCache() {
//        let (sut, store) = makeSUT()
//
//        expect(sut, toCompleteWith: .success([]), when: {
//            store.completeRetrievalWithEmptyCache()
//        })
//    }
//
//    func test_load_deliversImagesWithTimeStampOnNonEmptyCacheNonExpired() {
//        let currentDate = Date()
//        let (sut, store) = makeSUT(currentDate: { currentDate })
//        let feed = uniqueFeed()
//        let lessThanSevenDays = currentDate.adding(days: -7).adding(seconds: 1)
//
//        expect(sut, toCompleteWith: .success(feed.model), when: {
//            store.completeRetrieval(with: feed.local, timestamp: lessThanSevenDays)
//        })
//    }

//    func test_load_deliversNoImagesOnNonEmptyCacheExpiration() {
//        let currentDate = Date()
//        let (sut, store) = makeSUT(currentDate: { currentDate })
//        let feed = uniqueFeed()
//        let sevenDaysOld = currentDate.adding(days: -7)
//
//        expect(sut, toCompleteWith: .success([]), when: {
//            store.completeRetrieval(with: feed.local, timestamp: sevenDaysOld)
//        })
//    }
//
//    func test_load_deliversNoImagesOnNonEmptyCacheExpired() {
//        let currentDate = Date()
//        let (sut, store) = makeSUT(currentDate: { currentDate })
//        let feed = uniqueFeed()
//        let moreThanSevenDaysOld = currentDate.adding(days: -7).adding(seconds: -1)
//
//        expect(sut, toCompleteWith: .success([]), when: {
//            store.completeRetrieval(with: feed.local, timestamp: moreThanSevenDaysOld)
//        })
//    }

    func test_load_hasNoSideEffectsOnRetrievalError() {
        let (sut, store) = makeSUT()

        sut.load { _ in }
        store.completeRetrieval(with: anyNSError())

        XCTAssertEqual(store.recievedMessages, [.retrieve])
    }

    func test_load_doesNotDeleteCacheOnEmptyCache() {
        let (sut, store) = makeSUT()

        sut.load { _ in }
        store.completeRetrievalWithEmptyCache()

        XCTAssertEqual(store.recievedMessages, [.retrieve])
    }

    func test_load_doesNotDeleteCacheOnLessThanSevenDaysOldCache() {
        let currentDate = Date()
        let (sut, store) = makeSUT(currentDate: { currentDate })
        let feed = uniqueFeed()
        let lessThanSevenDays = currentDate.adding(days: -7).adding(seconds: 1)

        sut.load { _ in }
        store.completeRetrieval(with: feed.local, timestamp: lessThanSevenDays)

        XCTAssertEqual(store.recievedMessages, [.retrieve])
    }
//
    func test_load_deleteCacheOnSevenDaysOldCache() {
        let currentDate = Date()
        let (sut, store) = makeSUT(currentDate: { currentDate })
        let feed = uniqueFeed()
        let sevenDaysOld = currentDate.adding(days: -7)

        sut.load { _ in }
        store.completeRetrieval(with: feed.local, timestamp: sevenDaysOld)

        XCTAssertEqual(store.recievedMessages, [.retrieve, .deleteCacheFeed])
    }

    func test_load_deleteCacheOnMoreThanSevenDaysOldCache() {
        let currentDate = Date()
        let (sut, store) = makeSUT(currentDate: { currentDate })
        let feed = uniqueFeed()
        let moreThanSevenDaysOld = currentDate.adding(days: -7).adding(seconds: -1)

        sut.load { _ in }
        store.completeRetrieval(with: feed.local, timestamp: moreThanSevenDaysOld)

        XCTAssertEqual(store.recievedMessages, [.retrieve, .deleteCacheFeed])
    }

    // MARK: - Helpers

    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (LocalFeedLoader, FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)

        trackForMemoryLeak(sut, file: file, line: line)
        trackForMemoryLeak(store, file: file, line: line)

        return (sut, store)
    }

    private func expect(_ sut: LocalFeedLoader, toCompleteWith expectedResult: LocalFeedLoader.LoadResult, when action: () -> Void) {
        let exp = expectation(description: "Wait for loading")

        sut.load() { recievedResult in
            switch (recievedResult, expectedResult) {
            case let (.success(recievedImages), .success(expectedImages)):
                XCTAssertEqual(recievedImages, expectedImages)
            case let (.failure(recievedError as NSError), .failure(expectedError as NSError)):
                XCTAssertEqual(recievedError, expectedError)
            default:
                XCTFail("Expected \(expectedResult), but got \(recievedResult) instead")
            }
            exp.fulfill()
        }

        action()
        wait(for: [exp], timeout: 1.0)
    }

    private func feedImage() -> FeedImage {
        return FeedImage(id: UUID(), description: "any", location: "any", url: anyURL())
    }

    private func uniqueFeed() -> (model: [FeedImage], local: [LocalFeedImage]) {
        let feed = [feedImage()]
        let localFeed = feed.toLocals()

        return (feed, localFeed)
    }
}

private extension Date {
    func adding(days: Int) -> Date {
        return Calendar.init(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
    }

    func adding(seconds: TimeInterval) -> Date {
        return self + seconds
    }
}
