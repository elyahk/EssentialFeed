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

    public typealias SaveResult = Error?
    public typealias LoadResult = LoadFeedResult

    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }

    public func save(_ feed: [FeedImage], completion: @escaping (SaveResult) -> Void) {
        store.deleteCache() { [weak self] cacheDeletionError in
            guard let self = self else { return }

            if let cacheDeletionError = cacheDeletionError {
                completion(cacheDeletionError)
            } else {
                self.cache(feed, completion: completion)
            }
        }
    }

    private func cache(_ feed: [FeedImage], completion: @escaping (SaveResult) -> Void) {
        store.insert(feed.toLocals(), timestamp: currentDate()) { [weak self] error in
            guard self != nil else { return }

            completion(error)
        }
    }

    public func load(completion: @escaping (LoadResult) -> Void) {
        store.retrieve { retrievalError in
            if let retrievalError = retrievalError {
                completion(.failure(retrievalError))
            } else {
                completion(.success([]))
            }
        }
    }
}

private extension Array where Element == FeedImage {
    func toLocals() -> [LocalFeedImage] {
        map { LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url) }
    }
}
