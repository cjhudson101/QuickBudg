//
//  CreateBudgetView.swift
//  QuickBudg
//
//  Created by Chris Hudson on 10/26/24.
//

import SwiftUI
import RealmSwift

struct CreateBudgetView: View {
    
    @State private var selectedBudgetType: BudgetType? // Holds the selected budget type
    @State private var newBudgetTypeName: String = ""
    @State private var newBudgetAmount: Double?
    
    @Binding var showBudgetTypeSheet: Bool
    
    @State var selectedYear: Int;
    @State var selectedMonth: Int;
    
    // Assuming budgetTypes is a list of BudgetType objects, populated from Realm
    @ObservedResults(BudgetType.self) var budgetTypes
    
var body: some View {
        
        VStack {
            Text("Select an existing budget type, or enter the name of a new type.")
                .font(.headline)
                .padding()
            
            Picker("Select Budget Type", selection: $selectedBudgetType) {
                Text("Select type") // Placeholder item
                    .tag(nil as BudgetType?) // Nil tag for placeholder
                ForEach(budgetTypes, id: \.self) { budgetType in
                    Text(budgetType.name) // Display name of each budget type
                        .tag(budgetType as BudgetType?)
                }
            }
            .pickerStyle(MenuPickerStyle())
            
            TextField("Enter budget amount", value: $newBudgetAmount, formatter: NumberFormatter())
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .keyboardType(.numberPad) // Allows for decimal input
            
            Text("OR")
            
            TextField("Enter new type", text: $newBudgetTypeName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .onChange(of: newBudgetTypeName) { oldValue, newValue in
                    // Validate that the new input is a valid number
                    if !newValue.isEmpty {
                        // If we start to type in here, clear the selected option...
                        selectedBudgetType = nil
                    }
                }
            
            HStack {
                Spacer()
                Button("Save") {
                    addBudgetType()
                    newBudgetTypeName = "";
                    showBudgetTypeSheet = false
                }.disabled(newBudgetAmount == nil || (selectedBudgetType == nil && newBudgetTypeName.isEmpty))
                Spacer()
                Button("Cancel") {
                    newBudgetTypeName = "";
                    showBudgetTypeSheet = false
                }
                Spacer()
            }
            .padding()
        }
        
    }
    
    // Function to add a new budget type
    func addBudgetType() {
        guard (!newBudgetTypeName.isEmpty || selectedBudgetType != nil) && newBudgetAmount != nil else { return }
        var budgetType: BudgetType = BudgetType();
        
        if selectedBudgetType != nil {
            let selectedBudgetTypeId: String = selectedBudgetType!.id
            if let existingBudgetType: BudgetType = BudgetType.fetchBudgetTypeById(selectedBudgetTypeId) {
                budgetType = existingBudgetType
                print("Found existing budget type from Realm!")
            }
        } else if !newBudgetTypeName.isEmpty {
            if let existingBudgetType: BudgetType = BudgetType.fetchBudgetType(named: newBudgetTypeName) {
                budgetType = existingBudgetType // Use existing BudgetType
            } else {
                // Create a new BudgetType if it doesn't exist
                budgetType = BudgetType()
                budgetType.name = newBudgetTypeName
                
                let realm = try! Realm()
                try! realm.write {
                    realm.add(budgetType) // Save the new BudgetType to Realm
                }
            }
        }

            
        // Create a BudgetTotal for the current year and month
        let budgetTotal: BudgetTotal = BudgetTotal()
        budgetTotal.year = selectedYear
        budgetTotal.month = selectedMonth
        budgetTotal.totalAmount = newBudgetAmount ?? 0 // Example amount
        budgetTotal.budgetType = budgetType
        
        // Save to Realm
        try! realm.write {
            realm.add(budgetTotal)
            budgetType.budgetTotals.append(budgetTotal)
        }
        
        // Clear the input field
        newBudgetTypeName = "";
        selectedBudgetType = nil;
        newBudgetAmount = nil;
        
        print("Added budget type: \(budgetType.name)")
    }
}
