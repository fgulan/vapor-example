//
//  UserController.swift
//  Planner
//
//  Created by Filip Gulan on 09/11/2016.
//
//

import Vapor
import HTTP
import Routing
import BCrypt

class UserController: ResourceRepresentable, BaseController {

    /**
     * @api {get} /users Returns all registered users
     * @apiName Users
     * @apiGroup User
     *
     * @apiSuccess {Object[]} users List of all active users.
     */
    func index(request: Request) throws -> ResponseRepresentable {
        let nodes = try User.all().map { (user) -> Node in
            return try user.makeResponseNode()
        }
        return try JSON(node: [
            "users":  nodes.makeNode().converted(to: JSON.self)
        ])
    }

    /**
     * @api {get} /users/:id Returns details for user with given id
     * @apiName User details
     * @apiGroup User
     *
     * @apiParam {Number} id User's unique ID.
     *
     * @apiSuccess {String} first_name List of all active users.
     * @apiSuccess {String} last_name List of all active users.
     * @apiSuccess {String} email List of all active users.
     */
    func show(request: Request, user: User) throws -> ResponseRepresentable {
        return try user.makeResponseNode().converted(to: JSON.self)
    }

    /**
     * @api {delete} /users/:id Deletes user with given id
     * @apiName Delete user
     * @apiGroup User
     *
     * @apiParam {Number} id User's unique ID.
    */
    func delete(request: Request, user: User) throws -> ResponseRepresentable {
        if !request.isAuthenticated(user: user) {
            throw Abort.custom(status: .forbidden, message: "You cannot delete this user!")
        }
        try user.delete()
        return JSON([:])
    }

    /**
     * @api {put} /users/:id Update details for user with given id
     * @apiName Update user details
     * @apiGroup User
     *
     * @apiParam {String} old_password Current password (only if changing it)
     * @apiParam {String} password New password (only if changing it)
     * @apiParam {String} last_name User's new last name (only if changing it).
     * @apiParam {String} first_name User's new first_name (only if changing it).
     *
     * @apiSuccess {Object} user Updated user.
     */
    func update(request: Request, user: User) throws -> ResponseRepresentable {
        if !request.isAuthenticated(user: user) {
            throw Abort.custom(status: .forbidden, message: "You cannot update this user!")
        }

        var user = user
        guard let node = request.json?.makeNode() else { throw Abort.badRequest }
        if let password: String = try? node.extract("password"), let oldPassword: String = try? node.extract("old_password") {
            if let matches = try? BCrypt.verify(password: oldPassword, matchesHash: user.password), matches {
                user.password = BCrypt.hash(password: password)
            } else {
                throw Abort.custom(status: .unauthorized , message: "Invalid old password.")
            }
        }
        if let firstName: String = try? node.extract("first_name") {
            user.firstName = firstName
        }
        if let lastName: String = try? node.extract("last_name") {
            user.lastName = lastName
        }

        try user.save()
        return try user.makeResponseNode().converted(to: JSON.self)
    }

    func makeResource() -> Resource<User> {
        let res : Resource = Resource(
            index: index,
            show: show,
            replace: update,
            destroy: delete
        )
        return res
    }

    func setupRoutes(for group: RouteGroup<Responder, Droplet>, baseRoute: String) -> Self {
        /**
         * @api {get} /users/:id/plans Returns all plans created by given user
         * @apiName User's plans
         * @apiGroup User
         *
         * @apiParam {Number} id User's unique ID.
         *
         * @apiSuccess {Object[]} plans List of all plans created by given user.
         */
        group.grouped(baseRoute).get(":id", "plans") { request in
            guard let userId = request.parameters["id"]?.int else {
                throw Abort.badRequest
            }
            guard let user = try User.query().filter("id", userId).first() else {
                throw Abort.badRequest
            }

            let plans = try user.children("user_id", Plan.self).all().sorted(by: { (first, second) -> Bool in
                return first.date.compare(second.date) == .orderedAscending
            })

            let nodes = try plans.map { (plan) -> Node in
                return try plan.makeResponseNode()
            }
            return try JSON(node: [
                "plans":  nodes.makeNode().converted(to: JSON.self)
                ])
        }
        return self
    }
}

extension Request {
    func isAuthenticated(user: User) -> Bool {
        if let authUser = authenticatedUser() {
            return authUser.email == user.email
        }
        return false
    }
}
