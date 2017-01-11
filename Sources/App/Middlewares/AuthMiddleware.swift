//
//  AuthMiddleware.swift
//  Plnnr
//
//  Created by Filip Gulan on 02/12/2016.
//
//

import Foundation
import HTTP
import Vapor
import Turnstile

final class AuthenticationMiddleware: Middleware {

    public func respond(to request: Request, chainingTo next: Responder) throws -> Response {
        let path = request.uri.path
        if !path.hasPrefix("/api/") || path.hasPrefix("/api/register") {
            return try next.respond(to: request)
        }
        if let header = request.headers["Authorization"], let range = header.range(of: "Basic ")  {
            let token = header.substring(from: range.upperBound)

            let decodedToken = token.base64DecodedString
            guard let separatorRange = decodedToken.range(of: ":") else {
                throw Abort.custom(status: .unauthorized, message: "API Key not provided")
            }

            let apiKeyID = decodedToken.substring(to: separatorRange.lowerBound)
            let apiKeySecret = decodedToken.substring(from: separatorRange.upperBound)
            let _ = try User.authenticate(credentials: APIKey(id: apiKeyID, secret: apiKeySecret))
            return try next.respond(to: request)
        } else {
            throw Abort.custom(status: .unauthorized, message: "API Key not provided")
        }
    }
}

extension Request {
    func authenticatedUser() -> User? {
        if let header = self.headers["Authorization"], let range = header.range(of: "Basic ")  {
            let token = header.substring(from: range.upperBound)

            let decodedToken = token.base64DecodedString
            guard let separatorRange = decodedToken.range(of: ":") else {
                return nil
            }

            let apiKeyID = decodedToken.substring(to: separatorRange.lowerBound)
            let apiKeySecret = decodedToken.substring(from: separatorRange.upperBound)
            if let user = try? User.authenticate(credentials: APIKey(id: apiKeyID, secret: apiKeySecret)) as? User {
                return user
            }
        }
        return nil
    }
}

