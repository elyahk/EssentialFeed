//
//  File.swift
//  EssentialFeedTests
//
//  Created by Eldorbek on 08/03/22.
//

import Foundation
import XCTest
import EssentialFeed

extension FailableInsertFeedStoreSpecs where Self: XCTestCase {
    func assertThatInsertDeliversErrorOnInsertionError(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {

        let feed = uniqueImageFeed().locals
        let timestamp = Date()

        let firstInsertionError = insert(feed: feed, timestamp: timestamp, to: sut)

        XCTAssertNotNil(firstInsertionError, "Expected insertion error", file: file, line: line)
    }

    func assertThatInsertNoSideEffectsOnInsertionError(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        let feed = uniqueImageFeed().locals
        let timestamp = Date()

        insert(feed: feed, timestamp: timestamp, to: sut)

        expect(sut, toRetrieve: .empty, file: file, line: line)
    }
}
