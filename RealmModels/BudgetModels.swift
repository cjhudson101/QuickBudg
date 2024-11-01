//
//  BudgetModels.swift
//  QuickBudg
//
//  Created by Chris Hudson on 10/22/24.
//

import RealmSwift
import Foundation

class BudgetType: Object, Identifiable {
    @objc dynamic var id: String = UUID().uuidString
    @objc dynamic var name: String = ""  // e.g., Groceries, Rent
    let budgetTotals = List<BudgetTotal>()  // One-to-many relationship with BudgetTotal

    override static func primaryKey() -> String? {
        return "id"
    }

    // Method to fetch BudgetType by name
    static func fetchBudgetType(named name: String) -> BudgetType? {
        let realm = try! Realm()
        return realm.objects(BudgetType.self).filter("name == %@", name).first
    }

    static func fetchBudgetTypeById(_ id: String, in realm: Realm = try! Realm()) -> BudgetType? {
        return realm.object(ofType: BudgetType.self, forPrimaryKey: id)
    }
}

class BudgetTotal: Object, Identifiable {
    @objc dynamic var id: String = UUID().uuidString
    @objc dynamic var year: Int = 0
    @objc dynamic var month: Int = 0
    @objc dynamic var totalAmount: Double = 0.0  // Total budget for the month
    let expenses = List<Expense>()  // One-to-many relationship with expenses

    // Reference back to BudgetType
    @objc dynamic var budgetType: BudgetType?

    override static func primaryKey() -> String? {
        return "id"
    }

    var totalExpenses: Int {
        Int(expenses.reduce(0) { $0 + $1.amount })
    }

    var budgetConsumed: Int {
        Int(expenses.reduce(0) { $0 + $1.amount } / totalAmount)*100
    }

    static func fetchBudgetTotalById(_ id: String, in realm: Realm = try! Realm()) -> BudgetTotal? {
        return realm.object(ofType: BudgetTotal.self, forPrimaryKey: id)
    }
}

class Expense: Object, Identifiable {
    @objc dynamic var id: String = UUID().uuidString
    @objc dynamic var amount: Double = 0.0  // Expense amount
    @objc dynamic var descriptionText: String = ""  // Description of the expense
    @objc dynamic var dateEntered: Date = Date()  // When the expense was added
    @objc dynamic var budgetType: BudgetType?  // The budget type associated with this expense
    @objc dynamic var year: Int = 0
    @objc dynamic var month: Int = 0

    override static func primaryKey() -> String? {
        return "id"
    }
}
