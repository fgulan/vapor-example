//
//  User.swift
//  Planner
//
//  Created by Filip Gulan on 08/11/2016.
//
//

import Vapor
import Fluent
import HTTP
import Auth
import BCrypt

final class User: Model {

    var exists: Bool = false

    var id: Node?
    var firstName: String
    var lastName: String
    var email: String
    var password: String

    init(firstName: String, lastName: String, email: String, password: String) {
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.password = password
    }

    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        firstName = try node.extract("first_name")
        lastName = try node.extract("last_name")
        email = try node.extract("email")
        password = try node.extract("password")
    }

    func makeResponseNode() throws -> Node {
        return try Node(node: [
            "id" : id,
            "first_name" : firstName,
            "last_name" : lastName,
            "email" : email
        ])
    }

    func willDelete() {
        if let plans = try? children("user_id", Plan.self).all() {
            for plan in plans {
                let _ = try? plan.delete()
            }
        }
    }
}

extension User: Auth.User {
    static func authenticate(credentials: Credentials) throws -> Auth.User {
        let user: User?

        switch credentials {
        case let accessToken as AccessToken:
            user = try User.query().filter("access_token", accessToken.string).first()
        case let apiKey as APIKey:
            user = try User.query().filter("email", apiKey.id).first()
            if let password = user?.password, let matches = try? BCrypt.verify(password: apiKey.secret, matchesHash: password), matches {
                // Do nothing
            } else {
                throw Abort.custom(status: .unauthorized, message: "Invalid password")
            }
        default:
            throw Abort.custom(status: .unauthorized, message: "Invalid credentials.")
        }

        guard let u = user else {
            throw Abort.custom(status: .unauthorized, message: "User not found.")
        }

        return u
    }

    static func register(credentials: Credentials) throws -> Auth.User {
        throw Abort.notFound
    }
}

extension User: NodeRepresentable {

    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "id" : id,
            "first_name" : firstName,
            "last_name" : lastName,
            "email" : email,
            "password" : password
        ])
    }
}

extension User: Preparation {

    static func prepare(_ database: Database) throws {
        try database.create("users") { users in
            users.id()
            users.string("first_name")
            users.string("last_name")
            users.string("email")
            users.string("password")
        }
    }

    static func revert(_ database: Database) throws {
        try database.delete("users")
    }
}
