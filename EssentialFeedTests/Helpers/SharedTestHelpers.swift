//
//  SharedTestHelpers.swift
//  EssentialFeedTests
//
//  Created by Eldorbek on 06/03/22.
//

import Foundation

func anyNSError() -> NSError {
    return NSError(domain: "any error", code: 0)
}

func anyURL() -> URL {
    return URL(string: "https://a-url.com")!
}
