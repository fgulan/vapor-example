//
//  Plan.swift
//  Planner
//
//  Created by Filip Gulan on 19/11/2016.
//
//

import Vapor
import Fluent
import HTTP
import Foundation

final class Plan: Model {
    var exists: Bool = false

    var id: Node?
    var userID: String
    var activity: String
    var date: String

    init(userID: String, activity: String, date: String) {
        self.userID = userID
        self.activity = activity
        self.date = date
    }

    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        userID = try node.extract("user_id")
        activity = try node.extract("activity")
        date = try node.extract("date")
    }

    func makeResponseNode() throws -> Node {
        let authorNode = Node.init(userID)
        if let author = try self.parent(authorNode, "id", User.self).get() {
            var comments: [Comment] = []
            if let unwarpedComments = try? children("plan_id", Comment.self).all() {
                comments = unwarpedComments
            }
            return try Node(node: [
                "id" : id,
                "activity" : activity,
                "date" : date,
                "author" : author.makeResponseNode(),
                "comments" : comments.makeNode()
                ])
        }
        return try Node(node: [
            "id" : id,
            "activity" : activity,
            "date" : date,
            "user_id" : userID
            ])
    }

    func willDelete() {
        if let comments = try? children("plan_id", Comment.self).all() {
            for comment in comments {
                let _ = try? comment.delete()
            }
        }
    }
}

extension Plan: NodeRepresentable {
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "id": id,
            "user_id": userID,
            "activity" : activity,
            "date": date
            ])
    }
}

extension Plan: Preparation {

    static func prepare(_ database: Database) throws {
        try database.create("plans") { plans in
            plans.id()
            plans.parent(User.self, optional: false)
            plans.string("activity")
            plans.string("date")
        }
    }

    static func revert(_ database: Database) throws {
        try database.delete("plans")
    }
}


