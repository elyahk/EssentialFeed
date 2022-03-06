//
//  LoadFeedFromCacheUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Eldorbek on 06/03/22.
//

import Foundation
import XCTest
import EssentialFeed

class LoadFeedFromCacheUseCaseTests: XCTestCase {
    func test_init_doesNotMessageUponCreation() {
        let (store, _) = makeSUT()

        XCTAssertEqual(store.recievedMessages, [])
    }

    func test_load_requestsCacheRetrieval() {
        let (store, sut) = makeSUT()

        sut.load() { _ in }

        XCTAssertEqual(store.recievedMessages, [.retrieve])
    }

    func test_load_failsOnRetrievalError() {
        let (store, sut) = makeSUT()
        let retrievalError = anyNSError()

        expect(sut, toCompleteWith: .failure(retrievalError), when: {
            store.completeRetrieval(with: retrievalError)
        })
    }

    func test_load_delieverEmptyFeedOnEmptyCache() {
        let (store, sut) = makeSUT()

        expect(sut, toCompleteWith: .success([]), when: {
            store.completeRetrievalWithEmptyCache()
        })
    }

    func test_load_delieversCachedImagesOnLessThanSevenDaysOldCache() {
        let currentDate = Date()
        let (store, sut) = makeSUT(currentDate: { currentDate})
        let feed = uniqueImageFeed()
        let lessThanSeveDaysOldTimestamp = currentDate.adding(days: -7).adding(seconds: 1)

        expect(sut, toCompleteWith: .success(feed.models), when: {
            store.completeRetrieval(with: feed.locals, timestamp: lessThanSeveDaysOldTimestamp)
        })
    }

    func test_load_delieversNoImagesOnExactSevenDaysOldCache() {
        let currentDate = Date()
        let (store, sut) = makeSUT(currentDate: { currentDate})
        let feed = uniqueImageFeed()
        let SeveDaysOldTimestamp = currentDate.adding(days: -7)

        expect(sut, toCompleteWith: .success([]), when: {
            store.completeRetrieval(with: feed.locals, timestamp: SeveDaysOldTimestamp)
        })
    }

    func test_load_delieversNoImagesOnMoreThanSevenDaysOldCache() {
        let currentDate = Date()
        let (store, sut) = makeSUT(currentDate: { currentDate})
        let feed = uniqueImageFeed()
        let SeveDaysOldTimestamp = currentDate.adding(days: -7).adding(seconds: -1)

        expect(sut, toCompleteWith: .success([]), when: {
            store.completeRetrieval(with: feed.locals, timestamp: SeveDaysOldTimestamp)
        })
    }

    func test_load_deletesCacheOnRetrievalError() {
        let (store, sut) = makeSUT()

        sut.load() { _ in }

        store.completeRetrieval(with: anyNSError())

        XCTAssertEqual(store.recievedMessages, [.retrieve, .deleteCachedFeed])
    }


    // MARK: - Helper

    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (store: FeedStoreSpy, sut: LocalFeedLoader) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        trackForMemoryLeak(sut, file: file, line: line)
        trackForMemoryLeak(store, file: file, line: line)

        return (store, sut)
    }

    private func expect(_ sut: LocalFeedLoader, toCompleteWith expectedResult: LocalFeedLoader.LoadResult, when action: () -> Void) {
        let exp = expectation(description: "Wait for load completion")

        sut.load() { recievedResult in
            switch (recievedResult, expectedResult) {
            case (let .success(recievedImages), let .success(expectedImages)):
                XCTAssertEqual(recievedImages, expectedImages)

            case (let .failure(recievedError as NSError), let .failure(expectedError as NSError)):
                XCTAssertEqual(recievedError, expectedError)

            default: XCTFail("Expected \(expectedResult), got \(recievedResult)")
            }

            exp.fulfill()
        }

        action()
        wait(for: [exp], timeout: 1.0)
    }

    private func uniqueImage() -> FeedImage {
        return FeedImage(id: UUID(), description: "any description", location: "any location", url: anyURL())
    }

    private func uniqueImageFeed() -> (models: [FeedImage], locals: [LocalFeedImage]) {
        let feed = [uniqueImage()]
        let localFeed = feed.map { LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url)}

        return (feed, localFeed)
    }

    private func anyNSError() -> NSError {
        return NSError(domain: "any error", code: 0)
    }

    private func anyURL() -> URL {
        return URL(string: "https://a-url.com")!
    }
}

private extension Date {
    func adding(days: Int) -> Date {
        Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
    }

    func adding(seconds: TimeInterval) -> Date {
        self + seconds
    }
}
