//
//  File.swift
//  EssentialFeed
//
//  Created by Eldorbek on 27/02/22.
//

import Foundation

internal struct RemoteFeedItem: Decodable {
    internal let id: UUID
    internal let description: String?
    internal let location: String?
    internal let image: URL
}
