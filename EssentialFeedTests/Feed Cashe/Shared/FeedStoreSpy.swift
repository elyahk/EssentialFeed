//
//  File.swift
//  EssentialFeedTests
//
//  Created by Eldorbek on 27/02/22.
//

import Foundation
import EssentialFeed

class FeedStoreSpy: FeedStore {
    enum Message: Equatable {
        case deletion
        case insert([LocalFeedImage], Date)
    }

    var deletionCompletions: [DeletionCompletion] = []
    var insertionCompletions: [InsertionCompletion] = []

    var recievedMessage: [Message] = []

    func deleteCashedFeed(completion: @escaping DeletionCompletion) {
        deletionCompletions.append(completion)
        recievedMessage.append(.deletion)
    }

    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        insertionCompletions.append(completion)
        recievedMessage.append(.insert(feed, timestamp))
    }

    func completeDeletion(with error: Error, at index: Int = 0) {
        deletionCompletions[index](error)
    }

    func completeDeletionSuccessfully(at index: Int = 0) {
        deletionCompletions[index](nil)
    }

    func completeInsertion(with error: Error, at index: Int = 0) {
        insertionCompletions[index](error)
    }

    func completeInsertionSuccessfully(at index: Int = 0) {
        insertionCompletions[index](nil)
    }
}
