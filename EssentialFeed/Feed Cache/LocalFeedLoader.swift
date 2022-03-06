//
//  LocalFeedLoader.swift
//  EssentialFeed
//
//  Created by Eldorbek on 06/03/22.
//

import Foundation

public class LocalFeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date

    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }

    public func save(_ items: [FeedImage], completion: @escaping (Error?) -> Void) {
        store.deleteCashedFeed() { [weak self] deletionError in
            guard let self = self else { return }
            if deletionError == nil {
                self.cache(items, timestamp: self.currentDate(), with: completion)
            } else {
                completion(deletionError)
            }
        }
    }

    private func cache(_ items: [FeedImage], timestamp: Date, with completion: @escaping (Error?) -> Void) {
        self.store.insert(items, timestamp: timestamp) { [weak self] error in
            guard let _ = self else { return }
            completion(error)
        }
    }
}
