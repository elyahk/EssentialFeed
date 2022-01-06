//
//  FeedFeatureLoader.swift
//  EssentialFeedTests
//
//  Created by Eldorbek on 06/01/22.
//

import Foundation
import XCTest

class FeedFeatureLoader {

    func load() {
        HTTPClient.shared.get(from: URL(string: "https://a-url.com")!)
    }
}

class HTTPClient {
    static var shared: HTTPClient = HTTPClient()

    func get(from url: URL) {}
}

class HTTPClientSpy: HTTPClient {
    var requestedUrl: URL?

    override func get(from url: URL) {
        requestedUrl = url
    }

}

class FeedFeatureLoaderTests: XCTestCase {
    func test_init_doesNotRequestDataFromUrl() {
        let client = HTTPClientSpy()
        let sut = FeedFeatureLoader()
        HTTPClient.shared = client

        XCTAssertNil(client.requestedUrl)
    }

    func test_init_requestDataFromUrl() {
        let client = HTTPClientSpy()
        let sut = FeedFeatureLoader()
        HTTPClient.shared = client

        sut.load()

        XCTAssertNotNil(client.requestedUrl)
    }
}
