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

    private func anyNSError() -> NSError {
        return NSError(domain: "any error", code: 0)
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
}
