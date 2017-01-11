//
//  LogMiddleware.swift
//  Plnnr
//
//  Created by Filip Gulan on 02/12/2016.
//
//

import Foundation
import HTTP
import SwiftyBeaver

final class LogMiddleware: Middleware {

    private var _log = SwiftyBeaver.self

    init(path: String) {
        let file = FileDestination()
        file.logFileURL = URL(fileURLWithPath: path)
        file.format = "$M"
        _log.addDestination(file)
    }

    public func respond(to request: Request, chainingTo next: Responder) throws -> Response {
        if let userAgent = request.headers["User-Agent"] {
            var browser: String = "unknown"
            if userAgent.contains("Chrome") {
                browser = "chrome"
            } else if userAgent.contains("Firefox") {
                browser = "firefox"
            } else if userAgent.contains("Safari") {
                browser = "safari"
            } else if userAgent.contains("Paw") {
                browser = "paw"
            }
            _log.info("\(request.uri.path) \(browser)")
        }
        return try next.respond(to: request)
    }
}
