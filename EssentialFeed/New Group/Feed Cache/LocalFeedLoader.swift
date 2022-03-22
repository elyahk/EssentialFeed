//
//  File.swift
//  EssentialFeed
//
//  Created by Eldorbek on 22/03/22.
//

import Foundation

public class LocalFeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date

    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }

    public func save(_ feed: [FeedImage], completion: @escaping (Error?) -> Void) {
        store.deleteCache() { [weak self] cacheDeletionError in
            guard let self = self else { return }

            if let cacheDeletionError = cacheDeletionError {
                completion(cacheDeletionError)
            } else {
                self.cache(feed, completion: completion)
            }
        }
    }

    private func cache(_ feed: [FeedImage], completion: @escaping (Error?) -> Void) {
        store.insert(feed, timestamp: currentDate()) { [weak self] error in
            guard self != nil else { return }

            completion(error)
        }
    }
}
