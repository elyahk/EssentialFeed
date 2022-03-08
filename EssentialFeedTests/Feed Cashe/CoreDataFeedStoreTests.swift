//
//  CoreDataFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by Eldorbek on 08/03/22.
//

import Foundation
import XCTest
import EssentialFeed

final class CoreDataFeedStore: FeedStore {
    func retrieve(completion: @escaping RetrievalCompletion) {
        completion(.empty)
    }

    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {

    }

    func deleteCashedFeed(completion: @escaping DeletionCompletion) {

    }
}

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

    private func makeSUT() -> CoreDataFeedStore {
        let sut = CoreDataFeedStore()
        return sut
    }
}
