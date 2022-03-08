//
//  File.swift
//  EssentialFeed
//
//  Created by Eldorbek on 08/03/22.
//

import Foundation

public class CodableFeedStore: FeedStore {
    private struct Cache: Codable {
        let feed: [CodableFeedImage]
        let timestamp: Date

        var feedLocal: [LocalFeedImage] {
            feed.map { $0.local }
        }
    }

    private class CodableFeedImage: Codable {
        private let id: UUID
        private let description: String?
        private let location: String?
        private let url: URL

        internal init(_ image: LocalFeedImage) {
            self.id = image.id
            self.description = image.description
            self.location = image.location
            self.url = image.url
        }

        var local: LocalFeedImage { LocalFeedImage(id: id, description: description, location: location, url: url) }
    }

    private let storURL: URL

    public init(storeURL: URL) {
        self.storURL = storeURL
    }

    public func retrieve(completion: @escaping RetrievalCompletion) {
        guard let data = try? Data(contentsOf: storURL) else { return completion(.empty) }

        do {
            let decoder = JSONDecoder()
            let cache = try decoder.decode(Cache.self, from: data)
            completion(.found(cache.feedLocal, cache.timestamp))
        } catch {
            completion(.failure(error))
        }
    }

    public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        do {
            let encoder = JSONEncoder()
            let encoded = try encoder.encode(Cache(feed: feed.map(CodableFeedImage.init), timestamp: timestamp))
            try encoded.write(to: storURL)
            completion(nil)
        } catch {
            completion(error)
        }
    }

    public func deleteCashedFeed(completion: @escaping DeletionCompletion) {
        guard FileManager.default.fileExists(atPath: storURL.path) else { return completion(nil) }

        do {
            try FileManager.default.removeItem(at: storURL)
            completion(nil)
        } catch {
            completion(error)
        }
    }
}
