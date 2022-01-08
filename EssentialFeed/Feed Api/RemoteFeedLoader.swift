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

    public enum Result: Equatable {
        case success([FeedItem])
        case failure(Error)
    }


    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }

    public func load(completion: @escaping (Result) -> Void) {
        client.get(from: url) { [weak self] result in
            guard self != nil else { return }

            switch result {
            case let .success(data, response):
                completion(FeedItemMapper.map(data: data, response: response))
            case .failure:
                completion(.failure(.connectivity))
            }
        }
    }
}


