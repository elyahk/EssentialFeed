//
//  XCTestCase + FeedStoreSpecs.swift
//  EssentialFeedTests
//
//  Created by Eldorbek on 08/03/22.
//

import Foundation
import EssentialFeed
import XCTest

extension FeedStoreSpecs where Self: XCTestCase {
    @discardableResult
    func deleteCache(from sut: FeedStore) -> Error? {
        let exp = expectation(description: "Wait for cache deletion")
        var recievedError: Error?
        sut.deleteCashedFeed { deletionError in
            recievedError = deletionError
            exp.fulfill()

        }
        wait(for: [exp], timeout: 1.0)

        return recievedError
    }

    @discardableResult
    func insert(feed: [LocalFeedImage], timestamp: Date, to sut: FeedStore) -> Error? {
        let exp = expectation(description: "Wait for cache retrieval")
        var recievedError: Error?
        sut.insert(feed, timestamp: timestamp) { insertionError in
            recievedError = insertionError
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)

        return recievedError
    }

    func expect(_ sut: FeedStore, toRetrieveTwice expectedResult: RetrievalResult) {
        expect(sut, toRetrieve: expectedResult)
        expect(sut, toRetrieve: expectedResult)
    }

    func expect(_ sut: FeedStore, toRetrieve expectedResult: RetrievalResult) {
        let exp = expectation(description: "Wait for retrieve")
        sut.retrieve { recievedResult in
            switch (recievedResult, expectedResult) {
            case (.empty, .empty), (.failure, .failure):
                break

            case let (.found(recievedFeed, recievedTimestamp), .found(expectedFeed, expectedTimestamp)):
                XCTAssertEqual(recievedFeed, expectedFeed)
                XCTAssertEqual(recievedTimestamp, expectedTimestamp)

            default:
                XCTFail("Expected to retrieve \(expectedResult), got \(recievedResult) instead")
            }

            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
    }
}
