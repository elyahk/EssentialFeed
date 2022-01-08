//
//  File.swift
//  EssentialFeed
//
//  Created by Eldorbek on 08/01/22.
//

import Foundation

internal final class FeedItemMapper {
    private struct Root: Decodable {
        var items: [Item]

        var feedItems: [FeedItem] {
            return items.map { $0.feedItem }
        }
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

    private static var OK_200: Int { return 200 }

    internal static func map(data: Data, response: HTTPURLResponse) -> RemoteFeedLoader.Result {
        guard response.statusCode == OK_200,
              let root = try? JSONDecoder().decode(Root.self, from: data) else {
            return .failure(RemoteFeedLoader.Error.invalidData)
        }

        return .success(root.feedItems)
    }
}
