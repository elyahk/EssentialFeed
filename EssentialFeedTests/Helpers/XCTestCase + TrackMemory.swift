//
//  XCTestCase + TrackMemory.swift
//  EssentialFeedTests
//
//  Created by Eldorbek on 09/01/22.
//

import Foundation
import XCTest

extension XCTestCase {
    func trackForMemoryLeak(_ instance: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instance should be nil, potensial memory leak!", file: file, line: line)
        }
    }
}
