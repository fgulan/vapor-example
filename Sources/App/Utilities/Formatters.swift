//
//  Formatters.swift
//  Plnnr
//
//  Created by Filip Gulan on 05/12/2016.
//
//

import Foundation

struct Formatters {
    static var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter
    }
}
