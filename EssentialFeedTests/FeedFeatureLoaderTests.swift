//
//  FeedFeatureLoader.swift
//  EssentialFeedTests
//
//  Created by Eldorbek on 06/01/22.
//

import Foundation
import XCTest

class RemoteFeedLoader {
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

class FeedFeatureLoaderTests: XCTestCase {
    func test_init_doesNotRequestDataFromUrl() {
        let (_, client) = makeSUT()

        XCTAssertNil(client.requestedUrl)
    }

    func test_init_requestDataFromUrl() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)

        sut.load()

        XCTAssertEqual(client.requestedUrl, url)
    }

    // MARK: - Helpers
    
    private func makeSUT(url: URL = URL(string: "https://a-url.com")!) -> (RemoteFeedLoader, HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        return (sut, client)
    }

    private class HTTPClientSpy: HTTPClient {
        var requestedUrl: URL?

        func get(from url: URL) {
            requestedUrl = url
        }

    }

}
