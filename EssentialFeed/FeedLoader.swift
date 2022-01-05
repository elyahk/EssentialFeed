//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Eldorbek on 05/01/22.
//

import Foundation

enum LoadFeedResult {
    case success([FeedItem])
    case error(Error)
}

protocol FeedLoader {
    func load(completion: @escaping (LoadFeedResult) -> Void)
}
