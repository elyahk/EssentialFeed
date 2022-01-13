//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Eldorbek on 05/01/22.
//

import Foundation

public enum LoadFeedResult {
    case success([FeedItem])
    case failure(Error)
}

protocol FeedLoader {
    func load(completion: @escaping (LoadFeedResult) -> Void)
}
