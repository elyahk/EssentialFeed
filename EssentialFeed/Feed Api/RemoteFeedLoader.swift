//
//  File.swift
//  EssentialFeed
//
//  Created by Eldorbek on 06/01/22.
//

import Foundation

final public class RemoteFeedLoader {
    private var url: URL
    private var client: HTTPClient
 
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }

    public typealias Result = LoadFeedResult

    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
        
    }

    public func load(completion: @escaping (Result) -> Void) {
        client.get(from: url) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case let .success(data, response):
                completion(self.map(data, from: response))
            case .failure:
                completion(.failure(Error.connectivity))
            }
        }
    }

    private func map(_ data: Data, from response: HTTPURLResponse) -> RemoteFeedLoader.Result {
        do {
            let items = try FeedItemMapper.map(data: data, response: response)
            return .success(items.toModels())
        } catch {
            return .failure(error)
        }
    }
}

private extension Array where Element == RemoteFeedItem {
    func toModels() -> [FeedItem] {
        return map { FeedItem(id: $0.id, description: $0.description, location: $0.location, imageUrl: $0.image) }
    }
}
