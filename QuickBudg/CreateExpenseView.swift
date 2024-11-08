//
//  CreateExpenseView.swift
//  QuickBudg
//
//  Created by Chris Hudson on 10/26/24.
//

import SwiftUI
import RealmSwift

struct CreateExpenseView: View {
    
    var realm: Realm!
    
    @Binding var showSheet: Bool
    @Binding var budgetTotalId: String
    
    @State private var newExpenseDescription: String = ""
    @State private var newExpenseAmount: Double?
    
    
    var body: some View {
        VStack(alignment: .leading) {
            Label {
                Text("Enter expense description")
            } icon: {
                Image(systemName: "text.alignleft")
            }

            TextField("Enter description", text: $newExpenseDescription)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            
            Label {
                Text("Enter expense amount")
            } icon: {
                Image(systemName: "dollarsign.circle")
            }.padding(.top, 10)
            
            TextField("Enter amount", value: $newExpenseAmount, formatter: NumberFormatter())
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad) // Allows for decimal input
            
            HStack {
                Spacer()
                Button("Save") {
                    addExpense(id: budgetTotalId)
                    newExpenseAmount = nil
                    newExpenseDescription = ""
                    showSheet.toggle();
                }.buttonStyle(.borderedProminent)
                .disabled(newExpenseAmount == nil)
                Spacer()
                Button("Cancel") {
                    newExpenseAmount = nil
                    newExpenseDescription = ""
                    showSheet.toggle();
                }.buttonStyle(.bordered)
                Spacer()
            }
            .padding()
        }
    }

    func addExpense(id: String) {
        guard let realm = try? Realm() else {
            print("Error initializing Realm instance")
            return
        }
        print("Adding expense for budget total id \(id)")
        var existingBudgetTotal: BudgetTotal
        if let budgetFromRealm: BudgetTotal = realm.object(ofType: BudgetTotal.self, forPrimaryKey: id) {
            existingBudgetTotal = budgetFromRealm
            print("Found realm budget: \(existingBudgetTotal)")
            let newExpense: Expense = Expense();
            newExpense.amount = newExpenseAmount ?? 0.0;
            newExpense.descriptionText = newExpenseDescription;
            newExpense.budgetType = existingBudgetTotal.budgetType
            
            do {
                try realm.write {
                    // add expense to budgetTotal
                    existingBudgetTotal.expenses.append(newExpense)
                }
            } catch {
                print("Error added expense: \(error)")
            }
        }
    }
}
