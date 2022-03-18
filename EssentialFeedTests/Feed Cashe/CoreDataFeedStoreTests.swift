//
//  CoreDataFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by Eldorbek on 08/03/22.
//

import Foundation
import XCTest
import EssentialFeed

final class CoreDataFeedStoreTests: XCTestCase, FeedStoreSpecs {
    func test_retrieve_delieversEmptyOnEmptyCache() {
        let sut = makeSUT()

        assertThatDeliversEmptyOnEmptyCache(on: sut)
    }

    func test_retrieve_hasNoSideEffectOnEmptyCache() {
        let sut = makeSUT()

        assertThatHasNoSideEffectOnEmptyCache(on: sut)
    }

    func test_retrieve_deliversFoundValuesOnNonEmptyCache() {
        let sut = makeSUT()

//        assertThatRetrieveDeliversFoundValuesOnNonEmptyCache(on: sut)
    }

    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {

    }

    func test_insert_overridesPreviouslyInsertedCacheValues() {

    }

    func test_delete_hasNoSideEffectsOnEmptyCache() {

    }

    func test_delete_nonEmptyCacheI() {

    }

    func test_storeSideEffects_runSerially() {

    }


    // MARK: - Helpers

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> CoreDataFeedStore {
        let storeBundle = Bundle(for: CoreDataFeedStore.self)
        let sut = try! CoreDataFeedStore(bundle: storeBundle)

        trackForMemoryLeak(sut, file: file, line: line)
        return sut
    }
}
