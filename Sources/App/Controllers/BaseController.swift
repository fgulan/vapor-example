//
//  BaseController.swift
//  Planner
//
//  Created by Filip Gulan on 19/11/2016.
//
//

import Vapor
import Routing
import HTTP

protocol BaseController {
    func setupRoutes(for group: RouteGroup<Responder, Droplet>, baseRoute: String) -> Self
}
