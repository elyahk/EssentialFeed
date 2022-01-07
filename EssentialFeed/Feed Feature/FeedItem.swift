//
//  FeedItem.swift
//  EssentialFeed
//
//  Created by Eldorbek on 05/01/22.
//

import Foundation

public struct FeedItem: Equatable {
    let id: UUID
    let description: String?
    let locaation: String?
    let imageUrl: URL
}
