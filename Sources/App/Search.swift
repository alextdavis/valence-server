//
// Created by alex on 7/25/17.
//

import Foundation
import Vapor
import FluentProvider

final class Search: Model {
    let storage = Storage()
    let query: String?
    let predicate: SearchClause

    init(parse str: String) {
        self.queryString = str
        //do stuff
    }

    init(row: Row) throws {
        query = try row.get("query")
    }

    func makeRow() throws -> Row {
        var row = Row()
        try row.set("query", query)
        return row
    }

    private static func parse(_ str: String) -> SearchClause {
        if
    }

}


protocol SearchClause {
    func makeSQL() -> String
}

class AndClause: SearchClause {
    let lhs: SearchClause
    let rhs: SearchClause

    func makeSQL() -> String {
        return "(\(lhs.makeSQL()) AND \(rhs.makeSQL()))"
    }
}

class OrClause: SearchClause {
    let lhs: SearchClause
    let rhs: SearchClause

    func makeSQL() -> String {
        return "(\(lhs.makeSQL()) OR \(rhs.makeSQL()))"
    }
}

class NotClause: SearchClause {
    let inner: SearchClause

    func makeSQL() -> String {
        return "(NOT \(inner.makeSQL()))"
    }
}
