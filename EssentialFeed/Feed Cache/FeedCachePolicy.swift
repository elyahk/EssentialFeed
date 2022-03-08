//
//  File.swift
//  EssentialFeed
//
//  Created by Eldorbek on 08/03/22.
//

import Foundation

internal final class FeedCachePolicy {
    private static let calendar = Calendar(identifier: .gregorian)

    private init() { }

    private static var maxAgeDays: Int { return 7 }

    static func validate(_ timestamp: Date, against date: Date) -> Bool {
        guard let maxCacheAge = calendar.date(byAdding: .day, value: maxAgeDays, to: timestamp) else { return false }
        return date < maxCacheAge
    }
}
