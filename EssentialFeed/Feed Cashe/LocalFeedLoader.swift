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

    public func save(_ items: [FeedItem], completion: @escaping (SaveResult) -> Void) {
        feedStore.deleteCashedFeed { [weak self] deletionError in
            guard let self = self else { return }

            if let deletionError = deletionError {
                completion(deletionError)
            } else {
                self.cashe(items, timeStamp: self.currentTimestamp(), completion: completion)
            }
        }
    }

    private func cashe(_ items: [FeedItem], timeStamp: Date, completion: @escaping (SaveResult) -> Void) {
        feedStore.insert(items.toLocal(), timestamp: timeStamp) { [weak self] insertionError in
            guard self != nil else { return }
            completion(insertionError)
        }
    }
}

private extension Array where Element == FeedItem {
    func toLocal() -> [LocalFeedItem] {
        return self.map { LocalFeedItem(id: $0.id, description: $0.description, location: $0.location, imageUrl: $0.imageUrl) }
    }
}
