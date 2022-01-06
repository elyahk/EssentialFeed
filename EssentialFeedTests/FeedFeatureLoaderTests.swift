//
//  FeedFeatureLoader.swift
//  EssentialFeedTests
//
//  Created by Eldorbek on 06/01/22.
//

import EssentialFeed
import XCTest

class FeedFeatureLoaderTests: XCTestCase {
    func test_init_doesNotRequestDataFromUrl() {
        let (_, client) = makeSUT()

        XCTAssertNil(client.requestedUrl)
    }

    func test_load_requestsDataFromUrl() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)

        sut.load()

        XCTAssertEqual(client.requestedUrl, url)
    }

    func test_loadTwice_requestsDataFromUrlTwice() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)

        sut.load()
        sut.load()

        XCTAssertEqual(client.requestedUrls, [url, url])
    }

    // MARK: - Helpers
    
    private func makeSUT(url: URL = URL(string: "https://a-url.com")!) -> (RemoteFeedLoader, HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        return (sut, client)
    }

    private class HTTPClientSpy: HTTPClient {
        var requestedUrl: URL?
        var requestedUrls = [URL]()

        func get(from url: URL) {
            requestedUrl = url
            requestedUrls.append(url)
        }

    }

}
