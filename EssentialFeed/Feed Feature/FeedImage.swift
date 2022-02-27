//
//  FeedItem.swift
//  EssentialFeed
//
//  Created by Eldorbek on 05/01/22.
//

import Foundation

public struct FeedImage: Equatable {
    public let id: UUID
    public let description: String?
    public let location: String?
    public let imageUrl: URL

    public init(id: UUID, description: String?, location: String?, url: URL) {
        self.id = id
        self.description = description
        self.location = location
        self.imageUrl = url
    }
}
