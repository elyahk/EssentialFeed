//
//  File.swift
//  EssentialFeed
//
//  Created by Eldorbek on 26/02/22.
//

import Foundation

public final class LocalFeedLoader {
    private var feedStore: FeedStore
    private var currentTimestamp: () -> Date

    public typealias SaveResult = Error?

    public init(feedStore: FeedStore, currentTimestamp: @escaping () -> Date) {
        self.feedStore = feedStore
        self.currentTimestamp = currentTimestamp
    }

    public func save(_ feed: [FeedImage], completion: @escaping (SaveResult) -> Void) {
        feedStore.deleteCashedFeed { [weak self] deletionError in
            guard let self = self else { return }

            if let deletionError = deletionError {
                completion(deletionError)
            } else {
                self.cashe(feed, timeStamp: self.currentTimestamp(), completion: completion)
            }
        }
    }

    private func cashe(_ feed: [FeedImage], timeStamp: Date, completion: @escaping (SaveResult) -> Void) {
        feedStore.insert(feed.toLocal(), timestamp: timeStamp) { [weak self] insertionError in
            guard self != nil else { return }
            completion(insertionError)
        }
    }
}

private extension Array where Element == FeedImage {
    func toLocal() -> [LocalFeedImage] {
        return self.map { LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.imageUrl) }
    }
}
