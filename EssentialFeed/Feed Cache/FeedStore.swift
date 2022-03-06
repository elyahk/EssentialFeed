//
//  FeedStore.swift
//  EssentialFeed
//
//  Created by Eldorbek on 06/03/22.
//

import Foundation

public enum RetrievalResult {
    case failure(Error)
    case empty
}

public protocol FeedStore {
    typealias DeletionCompletion = (Error?) -> Void
    typealias InsertionCompletion = (Error?) -> Void
    typealias RetrievalCompletion = (RetrievalResult) -> Void

    func deleteCashedFeed(completion: @escaping DeletionCompletion)
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion)
    func retrieve(completion: @escaping RetrievalCompletion)
}


