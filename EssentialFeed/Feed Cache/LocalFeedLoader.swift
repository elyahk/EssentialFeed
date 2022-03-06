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

    public typealias SaveResult = Error?

    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }

    public func save(_ items: [FeedImage], completion: @escaping (SaveResult) -> Void) {
        store.deleteCashedFeed() { [weak self] deletionError in
            guard let self = self else { return }
            if deletionError == nil {
                self.cache(items.toLocal(), timestamp: self.currentDate(), with: completion)
            } else {
                completion(deletionError)
            }
        }
    }

    private func cache(_ items: [LocalFeedImage], timestamp: Date, with completion: @escaping (SaveResult) -> Void) {
        self.store.insert(items, timestamp: timestamp) { [weak self] error in
            guard let _ = self else { return }
            completion(error)
        }
    }
}

private extension Array where Element == FeedImage {
    func toLocal() -> [LocalFeedImage] {
        return map { LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.imageUrl)}
    }
}