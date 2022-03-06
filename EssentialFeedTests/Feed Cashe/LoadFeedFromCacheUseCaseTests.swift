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

        let exp = expectation(description: "Wait for load completion")
        var recievedError: Error?
        sut.load() { result in
            switch result {
            case let .failure(error):
                recievedError = error
            default:
                XCTFail("Expected failure, got \(result) instead")
            }

            exp.fulfill()
        }

        store.completeRetrieval(with: retrievalError)
        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(recievedError as NSError?, retrievalError)
    }

    func test_load_delieverEmptyFeedOnEmptyCache() {
        let (store, sut) = makeSUT()
        let exp = expectation(description: "Wait for load completion")

        var recievedImages: [FeedImage] = []
        sut.load() { result in
            switch result {
            case let .success(images):
                recievedImages = images
            default:
                XCTFail("Expected success, got \(result) instead")
            }

            exp.fulfill()
        }

        store.completeRetrievalWithEmptyCache()
        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(recievedImages, [])
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
}
