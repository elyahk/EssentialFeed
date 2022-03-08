//
//  File.swift
//  EssentialFeedTests
//
//  Created by Eldorbek on 08/03/22.
//

import Foundation
import XCTest
import EssentialFeed

extension FailableRetrieveFeedStoreSpecs where Self: XCTestCase {
    func assertThatRetriveDeliversErrorOnInvalidCache(on sut: FeedStore, for url: URL, file: StaticString = #filePath, line: UInt = #line) {
        try! "Invalid data".write(to: url, atomically: false, encoding: .utf8)

        expect(sut, toRetrieve: .failure(anyNSError()), file: file, line: line)
    }

    func assertThatRetriveHasNoSideEffectsOnIvalidCache(on sut: FeedStore, for url: URL, file: StaticString = #filePath, line: UInt = #line) {
        try! "Invalid data".write(to: url, atomically: false, encoding: .utf8)

        expect(sut, toRetrieveTwice: .failure(anyNSError()), file: file, line: line)
    }
}
