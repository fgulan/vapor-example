//
//  Comment.swift
//  Plnnr
//
//  Created by Filip Gulan on 05/12/2016.
//
//

import Vapor
import Fluent
import HTTP
import Foundation

final class Comment: Model {
    var exists: Bool = false

    var id: Node?
    var planID: String
    var userID: String
    var comment: String
    var date: String

    init(planID: String, userID: String, comment: String, date: String) {
        self.planID = planID
        self.comment = comment
        self.date = date
        self.userID = userID
    }

    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        planID = try node.extract("plan_id")
        comment = try node.extract("comment")
        date = try node.extract("date")
        userID = try node.extract("user_id")
    }

    func makeResponseNode() throws -> Node {
        if let user = try User.query().filter("id", userID).first() {
            return try Node(node: [
                "id" : id,
                "comment" : comment,
                "plan_id" : planID,
                "date" : date,
                "user" : user.makeResponseNode()
                ])
        } else {
            return try Node(node: [
                "id": id,
                "plan_id": planID,
                "comment" : comment,
                "date": date,
                "user_id": userID,
                ])
        }
    }
}

extension Comment: NodeRepresentable {
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "id": id,
            "plan_id": planID,
            "comment" : comment,
            "date": date,
            "user_id": userID,
            ])
    }
}

extension Comment: Preparation {

    static func prepare(_ database: Database) throws {
        try database.create("comments") { comments in
            comments.id()
            comments.parent(Plan.self, optional: false)
            comments.string("user_id")
            comments.string("comment")
            comments.string("date")
        }
    }

    static func revert(_ database: Database) throws {
        try database.delete("comments")
    }
}


