//
//  ContentView.swift
//  QuickBudg
//
//  Created by Chris Hudson on 10/21/24.
//

import SwiftUI
import RealmSwift

// Configure Realm migration in a global context
func configureRealmMigration() {
    let config = Realm.Configuration(
        schemaVersion: 2,
        migrationBlock: { migration, oldSchemaVersion in
            if oldSchemaVersion < 2 {
                migration.enumerateObjects(ofType: BudgetTotal.className()) { oldObject, newObject in
                    newObject?["budgetType"] = nil
                }
            }
        }
    )
    Realm.Configuration.defaultConfiguration = config
}

var realm: Realm!

struct ContentView: View {
    @State private var selectedYear: Int
    @State private var selectedMonth: Int
    @State private var showBudgetTypeSheet = false
    @State private var selectedBudgetId: String = ""

    @ObservedResults(BudgetTotal.self) var budgetTotals

    var filteredBudgetTotals: Results<BudgetTotal> {
        // Create a predicate to filter budget totals based on the selected year and month
        let predicate = NSPredicate(format: "year == %d AND month == %d", selectedYear, selectedMonth)
        return budgetTotals.filter(predicate) // Apply the predicate to the observed results
    }

    let years: [Int]

    init() {
        configureRealmMigration()
        do {
            realm = try Realm()  // Initialize the Realm instance
        } catch {
            print("Error initializing Realm: \(error.localizedDescription)")
        }
        let currentYear = Calendar.current.component(.year, from: Date())
        let currentMonth = Calendar.current.component(.month, from: Date())
        self._selectedYear = State(initialValue: currentYear)  // Initialize the selectedYear to the current year
        self._selectedMonth = State(initialValue: currentMonth) // Initialize the selectedMonth
        self.years = (0...4).map { currentYear - $0 } // Generate an array with the current year and the previous 4
    }
    let months =
    [
        (1, "January"),
        (2,"February"),
        (3,"March"),
        (4,"April"),
        (5,"May"),
        (6,"June"),
        (7,"July"),
        (8,"August"),
        (9,"September"),
        (10,"October"),
        (11,"November"),
        (12,"December")
    ]
    
    var body: some View {
        
        VStack {
            Label("Select Year/Month", systemImage: "calendar")
            HStack {
                Picker("Month",selection: $selectedMonth) {
                    ForEach(months, id: \.0) { month in
                        Text(month.1).tag(month.0)
                    }
                }
                Picker("Year",selection: $selectedYear) {
                    ForEach(years, id: \.self) { year in
                        Text("\(year)").tag(year)
                    }
                }.pickerStyle(.menu)
            }
            
            if !filteredBudgetTotals.isEmpty {
                BudgetListView(bt: filteredBudgetTotals, selectedBudgetId: $selectedBudgetId)
            } else {
                Spacer()
                Text("No budgets found!  Add a budget using the button below!")
                Spacer()
            }
        }
        
        
        Button("Add Budget Line", systemImage: "plus") {
            showBudgetTypeSheet = true
        }
        .padding()
        .sheet(isPresented: $showBudgetTypeSheet) {
            CreateBudgetView(showBudgetTypeSheet: $showBudgetTypeSheet, selectedYear: selectedYear, selectedMonth: selectedMonth)
        }
    }
    
}

struct BudgetListView: View {
    var bt: Results<BudgetTotal>
    @State var showAddExpenseSheet: Bool = false;
    @Binding var selectedBudgetId: String
    
    var body: some View {
        List {
            ForEach(bt, id: \.id) { budgetTotal in
                let percentage: Int = Int((Double(budgetTotal.totalExpenses) / Double(budgetTotal.totalAmount))*100)
                HStack {
                    VStack(alignment: .leading) {
                        Text("\(budgetTotal.budgetType?.name ?? "UNKNOWN")")
                            .font(.headline)        // Set the title font
                        Text("$\(budgetTotal.totalExpenses) of  $\(Int(budgetTotal.totalAmount))")
                            .font(.subheadline)     // Set the subtitle font
                            .foregroundColor(.gray) // Set subtitle color
                    }// Left-justified text
                    
                    Spacer()              // Pushes buttons to the right
                    
                    Text("\(percentage)%")
                        .font(.title)
                        .foregroundColor(colorForPercentage(percentage))

                    Spacer()

                    Button (action: {
                        selectedBudgetId = budgetTotal.id
                        print(budgetTotal.id)
                        print(selectedBudgetId)
                        showAddExpenseSheet = true
                    }) {
                            Image(systemName: "plus")
                                .frame(width: 30, height: 30)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .clipShape(Circle())
                        }
                        .sheet(isPresented: $showAddExpenseSheet) {
                        CreateExpenseView(showSheet: $showAddExpenseSheet, budgetTotalId: $selectedBudgetId)
                        }
                    
                }
                .padding(.vertical, 8)  // Optional padding to space out the rows
                .swipeActions {
                    Button(role: .destructive) {
                        selectedBudgetId = budgetTotal.id
                        deleteBudgetTotal(budgetTotalId: selectedBudgetId)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                
            }
        }
    }
    
    func deleteBudgetTotal(budgetTotalId: String) {
        guard let realm = try? Realm(),
              let budgetTotalToDelete = realm.object(ofType: BudgetTotal.self, forPrimaryKey: budgetTotalId)
        else { return }
        
        print("Attempting to delete budget: \(budgetTotalId)")
        do {
            try realm.write {
                // Delete all related expenses
                realm.delete(budgetTotalToDelete.expenses)
                // Delete the budget total itself
                realm.delete(budgetTotalToDelete)
            }
        } catch {
            print("Error deleting item from Realm: \(error)")
        }
        print("Budget deleted!")
        realm.refresh()
        print("Realm refreshed!")
    }
    
    func colorForPercentage(_ value: Int) -> Color {
        let opacity: Double = 0.9  // Adjust the opacity level (0.0 to 1.0)
        
        switch value {
        case 0...50:
            return Color.green.opacity(opacity)
        case 51...75:
            return Color.yellow.opacity(opacity)
        default:
            return Color.red.opacity(opacity)
        }
    }
}


#Preview {
    ContentView()
}
