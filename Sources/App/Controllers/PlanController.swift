//
//  PlanController.swift
//  Plnnr
//
//  Created by Filip Gulan on 05/12/2016.
//
//

import Foundation
import Vapor
import HTTP
import Routing
import BCrypt

class PlanController: ResourceRepresentable, BaseController {

    /**
     * @api {get} /plans Returns all created plans
     * @apiName Plans
     * @apiGroup Plan
     *
     * @apiSuccess {Object[]} plans List of all active plans.
     */
    func index(request: Request) throws -> ResponseRepresentable {
        let nodes = try Plan.all()
            .sorted(by: { (first, second) -> Bool in
                return first.date.compare(second.date) == .orderedAscending
            })
            .map { (plan) -> Node in
                return try plan.makeResponseNode()
        }
        return try JSON(node: [
            "plans":  nodes.makeNode().converted(to: JSON.self)
            ])
    }

    /**
     * @api {get} /plans/:id Returns details for plan with given id
     * @apiName Plan details
     * @apiGroup Plan
     *
     * @apiParam {Number} id Plan unique ID.
     *
     * @apiSuccess {String} activity Plan activity.
     * @apiSuccess {String} date Date of plan.
     * @apiSuccess {User} author Plan creator.
     * @apiSuccess {Comment[]} comments Plan comments.
     */
    func show(request: Request, plan: Plan) throws -> ResponseRepresentable {
        return try JSON(node: [
            "plan" : plan.makeResponseNode()
            ])
    }

    /**
     * @api {delete} /plans/:id Deletes plan with given id
     * @apiName Delete plan
     * @apiGroup Plan
     *
     * @apiParam {Number} id Plan's unique ID.
     */
    func delete(request: Request, plan: Plan) throws -> ResponseRepresentable {
        if let user = request.authenticatedUser(), let userId = user.id?.int, plan.userID == String(userId) {
            try plan.delete()
        } else {
            throw Abort.custom(status: .unauthorized, message: "You cannot delete this plan!")
        }
        return JSON([:])
    }

    func makeResource() -> Resource<Plan> {
        let res : Resource = Resource(
            index: index,
            show: show,
            destroy: delete
        )
        return res
    }

    func setupRoutes(for group: RouteGroup<Responder, Droplet>, baseRoute: String) -> Self {

        /**
         * @api {put} /plans Create plans with given params
         * @apiName Creates plan
         * @apiGroup Plan
         *
         * @apiParam {String} activity Plan activity
         * @apiParam {String} date Plan date
         *
         * @apiSuccess {Plan} plan Created plan.
         */
        group.grouped(baseRoute).put { (request) -> ResponseRepresentable in
            guard let activity = request.data["activity"]?.string else {
                throw Abort.custom(status: .badRequest, message: "Missing plan name.")
            }
            guard let dateString = request.data["date"]?.string else {
                throw Abort.custom(status: .badRequest, message: "Missing plan date.")
            }
            guard Formatters.dateFormatter.date(from: dateString) != nil else {
                throw Abort.custom(status: .badRequest, message: "Invalid date format, please use: 'yyyy-MM-dd HH:mm'")
            }
            guard let user = request.authenticatedUser(), let userID = user.id?.string else {
                throw Abort.custom(status: .unauthorized, message: "")
            }

            var plan = Plan(userID: userID, activity: activity, date: dateString)
            try plan.save()
            return try JSON(node: [
                "plan" : plan.makeResponseNode()
                ])
        }

        /**
         * @api {post} /plans/:id Post comment on plan with given id
         * @apiName Post comment
         * @apiGroup Plan
         *
         * @apiParam {String} id Plan unique ID
         * @apiParam {String} comment Comment
         *
         * @apiSuccess {Comment} comment Created comment.
         */
        group.grouped(baseRoute).post(Plan.self) { request, plan in
            guard let user = request.authenticatedUser(), let userID = user.id?.string, let planID = plan.id?.string else {
                throw Abort.custom(status: .unauthorized, message: "")
            }
            guard let text = request.data["comment"]?.string else {
                throw Abort.custom(status: .badRequest, message: "Missing comment.")
            }

            let dateString = Formatters.dateFormatter.string(from: Date())
            var comment = Comment(planID: planID, userID: userID, comment: text, date: dateString)
            try comment.save()
            return comment
        }
        return self
    }
}
