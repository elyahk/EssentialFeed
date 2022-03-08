//
//  FeedStore.swift
//  EssentialFeed
//
//  Created by Eldorbek on 06/03/22.
//

import Foundation

public enum RetrievalResult {
    case failure(Error)
    case found([LocalFeedImage], Date)
    case empty
}

public protocol FeedStore {
    typealias DeletionCompletion = (Error?) -> Void
    typealias InsertionCompletion = (Error?) -> Void
    typealias RetrievalCompletion = (RetrievalResult) -> Void

    /// The completion handler can be invoked in any thread
    /// Clients are responsible to dispatch to approporiate threads, if needed
    func deleteCashedFeed(completion: @escaping DeletionCompletion)

    /// The completion handler can be invoked in any thread
    /// Clients are responsible to dispatch to approporiate threads, if needed
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion)

    /// The completion handler can be invoked in any thread
    /// Clients are responsible to dispatch to approporiate threads, if needed
    func retrieve(completion: @escaping RetrievalCompletion)
}


