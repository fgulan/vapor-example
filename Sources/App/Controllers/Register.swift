//
//  Register.swift
//  Planner
//
//  Created by Filip Gulan on 13/11/2016.
//
//

import Foundation
import Vapor
import Fluent
import HTTP
import Routing
import BCrypt

func setupRegisterRoute(for drop: RouteGroup<Responder, Droplet>) {

    /**
     * @api {post} /register Register new user
     * @apiName Register
     * @apiGroup User
     *
     * @apiParam {String} email User's email address.
     * @apiParam {String} fist_name User's first name.
     * @apiParam {String} last_name User's last name.
     * @apiParam {String} password User's password.
     *
     * @apiSuccess {Object} user Created user.
     */
    drop.post("register") { (request) -> ResponseRepresentable in
        guard let email = request.data["email"]?.string else {
            throw Abort.custom(status: .badRequest, message: "Please provide email")
        }
        if let _ = try User.query().filter("email", email).first() {
            throw Abort.custom(status: .badRequest, message: "User with given email already exist")
        }
        do {
            guard let json = request.json else { throw Abort.badRequest }
            var user = try User(node: json)
            user.password = BCrypt.hash(password: user.password)
            try user.save()
            return try JSON(node: [
                "user": user.makeResponseNode()
            ])
        } catch _ {
            throw Abort.custom(status: .badRequest, message: "Invalid user data!")
        }
    }
}
