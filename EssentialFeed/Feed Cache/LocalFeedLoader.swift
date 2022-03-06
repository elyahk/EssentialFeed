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
    public typealias LoadResult = LoadFeedResult

    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }

    public func save(_ feed: [FeedImage], completion: @escaping (SaveResult) -> Void) {
        store.deleteCashedFeed() { [weak self] deletionError in
            guard let self = self else { return }
            if deletionError == nil {
                self.cache(feed, timestamp: self.currentDate(), with: completion)
            } else {
                completion(deletionError)
            }
        }
    }

    public func load(completion: @escaping (LoadResult) -> Void) {
        store.retrieve { [unowned self] result in
            switch result {
            case let .failure(error):
                completion(.failure(error))
            case let .found(feed, timestamp) where self.validate(timestamp):
                completion(.success(feed.toModels()))
            case .found, .empty:
                completion(.success([]))
            }
        }
    }

    private func cache(_ feed: [FeedImage], timestamp: Date, with completion: @escaping (SaveResult) -> Void) {
        self.store.insert(feed.toLocal(), timestamp: timestamp) { [weak self] error in
            guard let _ = self else { return }
            completion(error)
        }
    }

    private func validate(_ timestamp: Date) -> Bool {
        let calendar = Calendar(identifier: .gregorian)
        guard let maxCacheAge = calendar.date(byAdding: .day, value: 7, to: timestamp) else { return false }

        return currentDate() < maxCacheAge
    }
}

private extension Array where Element == FeedImage {
    func toLocal() -> [LocalFeedImage] {
        return map { LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url)}
    }
}

private extension Array where Element == LocalFeedImage {
    func toModels() -> [FeedImage] {
        return map { FeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url)}
    }
}
