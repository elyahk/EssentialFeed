//
//  File.swift
//  EssentialFeed
//
//  Created by Eldorbek on 08/01/22.
//

import Foundation

internal final class FeedItemMapper {
    private static var OK_200: Int { return 200 }

    internal static func map(_ data: Data, _ response: HTTPURLResponse) throws -> [FeedItem] {
        guard response.statusCode == OK_200 else { throw RemoteFeedLoader.Error.invalidData }
        return try JSONDecoder().decode(Root.self, from: data).items.map { $0.feedItem }
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
}
