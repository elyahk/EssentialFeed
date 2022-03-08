//
//  CodableFeedStore.swift
//  EssentialFeedTests
//
//  Created by Eldorbek on 08/03/22.
//

import Foundation
import XCTest
import EssentialFeed

class CodableFeedStoreTests: XCTestCase, FailableFeedStore {
    override func setUp() {
        super.setUp()

        setUpEmptyState()
    }

    override func tearDown() {
        super.tearDown()
        undoStoreSideEffects()
    }

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

        assertThatRetrieveDeliversFoundValuesOnNonEmptyCache(on: sut)
    }

    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
        let sut = makeSUT()

        assertThatRetrieveHasNoSideEffectsOnNonEmptyCache(on: sut)
    }

    func test_retrieve_deliversErrorOnInvalidCache() {
        let storeURL = testSpecificStoreURL
        let sut = makeSUT(storeURL: storeURL)

        assertThatRetriveDeliversErrorOnInvalidCache(on: sut, for: storeURL)
    }

    func test_retrieve_hasNoSideEffectsOnInvalidCache() {
        let storeURL = testSpecificStoreURL
        let sut = makeSUT(storeURL: storeURL)

        assertThatRetriveHasNoSideEffectsOnIvalidCache(on: sut, for: storeURL)
    }

    func test_insert_overridesPreviouslyInsertedCacheValues() {
        let sut = makeSUT()

        assertThatInsertOverridesPreviouslyInsertedCacheValues(on: sut)
    }

    func test_insert_deliversErrorOnInsertionError() {
        let invalidStoreURL = URL(string: "invalid://store-url")!
        let sut = makeSUT(storeURL: invalidStoreURL)

        assertThatInsertDeliversErrorOnInsertionError(on: sut)
    }

    func test_insert_noSideEffectsOnInsertionError() {
        let invalidStoreURL = URL(string: "invalid://store-url")!
        let sut = makeSUT(storeURL: invalidStoreURL)

        assertThatInsertNoSideEffectsOnInsertionError(on: sut)
    }

    func test_delete_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()

        assertThatDeleteHasNoSideEffectsOnEmptyCache(on: sut)
    }

    func test_delete_nonEmptyCacheI() {
        let sut = makeSUT()

        assertThatDeleteNonEmptyCache(on: sut)
    }

    func test_delete_deliversErrorOnDeletionError() {
        let nonDeletePermissionURL = documentStoreURL
        let sut = makeSUT(storeURL: nonDeletePermissionURL)
        assertThatDeleteDeliversErrorOnDeletionError(on: sut)
    }

    func test_delete_noSideEffectsOnDeletionError() {
        let nonDeletePermissionURL = documentStoreURL
        let sut = makeSUT(storeURL: nonDeletePermissionURL)

        assertThatDeleteNoSideEffectsOnDeletionError(on: sut)
    }

    func test_storeSideEffects_runSerially() {
        let sut = makeSUT()

        assertThatStoreSideEffectsRunSerially(on: sut)
    }


    // MARK: - Helpers

    private var testSpecificStoreURL: URL { FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("\(type(of: self)).store") }
    private var documentStoreURL: URL { FileManager.default.urls(for: .cachesDirectory, in: .systemDomainMask).first! }

    private func makeSUT(storeURL: URL? = nil, file: StaticString = #filePath, line: UInt = #line) -> FeedStore {
        let sut = CodableFeedStore(storeURL: storeURL ?? testSpecificStoreURL)
        trackForMemoryLeak(sut, file: file, line: line)

        return sut
    }

    private func setUpEmptyState() {
        deleteStoreSideEffects()
    }

    private func undoStoreSideEffects() {
        deleteStoreSideEffects()
    }

    private func deleteStoreSideEffects() {
        try? FileManager.default.removeItem(at: testSpecificStoreURL)
    }
}
