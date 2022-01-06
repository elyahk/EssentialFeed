//
//  FeedFeatureLoader.swift
//  EssentialFeedTests
//
//  Created by Eldorbek on 06/01/22.
//

import Foundation
import XCTest

class FeedFeatureLoader {
    private var client: HTTPClient
    var url: URL

    init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }

    func load() {
       client.get(from: url)
    }
}

protocol HTTPClient {
    func get(from url: URL)
}

class HTTPClientSpy: HTTPClient {
    var requestedUrl: URL?

    func get(from url: URL) {
        requestedUrl = url
    }

}

class FeedFeatureLoaderTests: XCTestCase {
    func test_init_doesNotRequestDataFromUrl() {
        let url = URL(string: "https://a-given-url.com")!
        let client = HTTPClientSpy()
        let _ = FeedFeatureLoader(url: url, client: client)

        XCTAssertNil(client.requestedUrl)
    }

    func test_init_requestDataFromUrl() {
        let url = URL(string: "https://a-given-url.com")!
        let client = HTTPClientSpy()
        let sut = FeedFeatureLoader(url: url, client: client)

        sut.load()

        XCTAssertEqual(client.requestedUrl, url)
    }
}
