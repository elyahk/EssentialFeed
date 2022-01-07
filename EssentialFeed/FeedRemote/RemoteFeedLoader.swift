//
//  File.swift
//  EssentialFeed
//
//  Created by Eldorbek on 06/01/22.
//

import Foundation

public enum HTTPClientResult {
    case success(Data, HTTPURLResponse)
    case failure(Error)
}

public protocol HTTPClient {
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void)
}

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
        client.get(from: url) { result in
            switch result {
            case let .success(data, response):
                if let items = try? FeedItemMapper.map(data, response) {
                    completion(.success(items))
                } else {
                    completion(.failure(.invalidData))
                }
            case .failure:
                completion(.failure(.connectivity))
            }
        }
    }
}

private class FeedItemMapper {
    static func map(_ data: Data, _ response: HTTPURLResponse) throws -> [FeedItem] {
        guard response.statusCode == 200 else { throw RemoteFeedLoader.Error.invalidData }
        return try JSONDecoder().decode(Root.self, from: data).items.map { $0.feedItem }
    }
}

private struct Root: Decodable {
    var items: [Item]
}

private struct Item: Decodable {
    let id: UUID
    let description: String?
    let location: String?
    let image: URL

    var feedItem: FeedItem {
        FeedItem(id: id, description: description, location: location, imageUrl: image)
    }
}



