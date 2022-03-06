//
//  FeedCacheTestHelpers.swift
//  EssentialFeedTests
//
//  Created by Eldorbek on 06/03/22.
//

import Foundation
import EssentialFeed

func uniqueImage() -> FeedImage {
    return FeedImage(id: UUID(), description: "any description", location: "any location", url: anyURL())
}

func uniqueImageFeed() -> (models: [FeedImage], locals: [LocalFeedImage]) {
    let feed = [uniqueImage()]
    let localFeed = feed.map { LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url)}

    return (feed, localFeed)
}

extension Date {
    func adding(days: Int) -> Date {
        Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
    }

    func adding(seconds: TimeInterval) -> Date {
        self + seconds
    }
}
