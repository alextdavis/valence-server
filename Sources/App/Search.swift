//
// Created by alex on 7/25/17.
//

import Foundation
import Vapor
import FluentProvider

class Search: Model {
    let storage = Storage()
    let queryString: String?

    init(string: String) {

    }

    init(row: Row) throws {
        name = try row.get("name")
    }

    func makeRow() throws -> Row {
        var row = Row()
        try row.set("name", name)
        return row
    }


}
