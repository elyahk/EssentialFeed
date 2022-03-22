//
//  File.swift
//  EssentialFeed
//
//  Created by Eldorbek on 22/03/22.
//

import Foundation

public protocol FeedStore {
    typealias DeletionCompletion = (Error?) -> Void
    typealias InsertionCompletion = (Error?) -> Void

    func deleteCache(completion: @escaping DeletionCompletion)
    func insert(_ items: [FeedImage], timestamp: Date, completion: @escaping InsertionCompletion)
}
