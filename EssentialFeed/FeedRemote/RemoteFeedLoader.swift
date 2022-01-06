//
//  File.swift
//  EssentialFeed
//
//  Created by Eldorbek on 06/01/22.
//

import Foundation

final public class RemoteFeedLoader {
    private var url: URL
    private var client: HTTPClient

    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }

    public func load() {
       client.get(from: url)
    }
}

public protocol HTTPClient {
    func get(from url: URL)
}
