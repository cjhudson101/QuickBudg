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
    @State private var showDetailsSheet = false
    @State private var showAddExpenseSheet = false
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
        ZStack (alignment: .bottom) {
            VStack {
                Label("Select Year/Month", systemImage: "calendar")
                HStack {
                    Button("", systemImage: "chevron.left") {
                        previousMonth()
                    }
                    
                    Picker("Month",selection: $selectedMonth) {
                        ForEach(months, id: \.0) { month in
                            Text(month.1).tag(month.0)
                        }
                    }
                    
                    Picker("Year",selection: $selectedYear) {
                        ForEach(years, id: \.self) { year in
                            Text("\(String(year))").tag(year)
                        }
                    }.pickerStyle(.menu)
                    
                    Button("", systemImage: "chevron.right") {
                        nextMonth()
                    }
                }
                //add padding on bottom by 5
                .padding(.bottom, 5)
                
                if !filteredBudgetTotals.isEmpty {
                    BudgetListView(bt: filteredBudgetTotals, showAddExpenseSheet: $showAddExpenseSheet, showDetailsSheet: $showDetailsSheet, selectedBudgetId: $selectedBudgetId)
                } else {
                    Spacer()
                    Text("No budgets found!")
                    Text("Add a budget using the button below!")
                    Spacer()
                }
            }
            .sheet(isPresented: $showBudgetTypeSheet) {
                CreateBudgetView(showBudgetTypeSheet: $showBudgetTypeSheet, selectedYear: selectedYear, selectedMonth: selectedMonth)
            }

            if (!self.showBudgetTypeSheet && !self.showDetailsSheet && !self.showAddExpenseSheet) {
                Button("Add Budget", systemImage: "plus") {
                    showBudgetTypeSheet = true
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
        }
    }
    
    func previousMonth() {
        if (selectedMonth == 1) {
            selectedMonth = 12;
            selectedYear -= 1;
        } else {
            selectedMonth -= 1;
        }
    }
    
    func nextMonth() {
        if (selectedMonth == 12) {
            selectedMonth = 1;
            selectedYear += 1;
        } else {
            selectedMonth += 1;
        }
    }
    
}

struct BudgetListView: View {
    var bt: Results<BudgetTotal>
    @Binding var showAddExpenseSheet: Bool;
    @Binding var showDetailsSheet: Bool
    @Binding var selectedBudgetId: String
    @State var selectedBudgetTotal: BudgetTotal? = nil
    
    var body: some View {
        ZStack {
            
            List {
                ForEach(bt, id: \.id) { budgetTotal in
                    BudgetRowView(budgetTotal: budgetTotal, selectedBudgetId: $selectedBudgetId, showAddExpenseSheet: $showAddExpenseSheet, showDetailsSheet: $showDetailsSheet, selectedBudgetTotal: $selectedBudgetTotal)
                }
            }
            .blur(radius: showAddExpenseSheet ? 5 : 0)
            
            if (showAddExpenseSheet) {
                Color.black.opacity(0.3) // Darken and blur the background
                    .edgesIgnoringSafeArea(.all)
                    .blur(radius: 5)
                
                GroupBox {
                    CreateExpenseView(showSheet: $showAddExpenseSheet, budgetTotalId: $selectedBudgetId)
                } label: {
                    Text("Add Expense")
                        .font(.title)
                        .padding()
                        
                }
                .padding(.horizontal, 25)
                //veritcally align the groupbox to the top
                .padding(.top, 10)
                .offset(y: -100)
            }
            
            if showDetailsSheet, let budgetTotal = selectedBudgetTotal {
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                    .blur(radius: 5)
                
                ExpenseListView(budgetTotal: budgetTotal, showDetailsSheet: $showDetailsSheet)
            }
        }
    }
    
    func deleteBudgetTotal(budgetTotalId: String) {
        guard let realm = try? Realm(),
              let budgetTotalToDelete = realm.object(ofType: BudgetTotal.self, forPrimaryKey: budgetTotalId)
        else { return }
        
//        print("Attempting to delete budget: \(budgetTotalId)")
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
        case 0:
            return Color.gray.opacity(opacity)
        case 1...25:
            return Color.green.opacity(opacity)
        case 26...50:
            return Color.yellow.opacity(opacity)
        case 51...75:
            return Color.orange.opacity(opacity)
        default:
            return Color.red.opacity(opacity)
        }
    }
}

struct BudgetRowView: View {
    var budgetTotal: BudgetTotal
    @Binding var selectedBudgetId: String
    @Binding var showAddExpenseSheet: Bool
    @Binding var showDetailsSheet: Bool
    @Binding var selectedBudgetTotal: BudgetTotal?

    var body: some View {
        let percentage: Int = Int((Double(budgetTotal.totalExpenses) / Double(budgetTotal.totalAmount)) * 100)
        
        HStack {
            Button(action: {
                selectedBudgetTotal = budgetTotal
                showDetailsSheet.toggle()
            }) {
                HStack {
                    Gauge(value: Double(percentage), in: 0...100) {
                    } currentValueLabel: {
                        Text("\(percentage)%")
                            .foregroundColor(colorForPercentage(percentage))
                    }
                    .tint(colorForPercentage(percentage))
                    .gaugeStyle(.accessoryCircular)
                    
                    Spacer()
                        .frame(width: 20)
                    
                    VStack(alignment: .leading) {
                        Text("\(budgetTotal.budgetType?.name ?? "UNKNOWN")")
                            .font(.headline)
                        Text("$\(budgetTotal.totalExpenses) of  $\(Int(budgetTotal.totalAmount))")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }.buttonStyle(.borderless)
            
            Spacer()
            
            Button(action: {
                selectedBudgetId = budgetTotal.id
                showAddExpenseSheet.toggle()
            }) {
                Image(systemName: "plus")
                    .frame(width: 40, height: 40)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .clipShape(Circle())
            }
            .contentShape(Rectangle())
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 8)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                selectedBudgetId = budgetTotal.id
                deleteBudgetTotal(budgetTotalId: selectedBudgetId)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    func deleteBudgetTotal(budgetTotalId: String) {
        guard let realm = try? Realm(),
              let budgetTotalToDelete = realm.object(ofType: BudgetTotal.self, forPrimaryKey: budgetTotalId) else { return }
        
        do {
            try realm.write {
                realm.delete(budgetTotalToDelete.expenses)
                realm.delete(budgetTotalToDelete)
            }
        } catch {
            print("Error deleting item from Realm: \(error)")
        }
        realm.refresh()
    }
    
    func colorForPercentage(_ value: Int) -> Color {
        let opacity: Double = 0.9
        
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

struct ExpenseListView: View {
    var budgetTotal: BudgetTotal
    @Binding var showDetailsSheet: Bool
    @State private var budgetAmount: Double?
    @State private var savedSuccess: Bool = false
    
    //initialize the budget amount to the total amount of the budget total
    init(budgetTotal: BudgetTotal, showDetailsSheet: Binding<Bool>) {
        self.budgetTotal = budgetTotal
        self._showDetailsSheet = showDetailsSheet
        self._budgetAmount = State(initialValue: budgetTotal.totalAmount)
        self.savedSuccess = false
    }
    
    var body: some View {
        
        GroupBox {
            VStack {
                HStack {
                    //TODO budgetTotal var is not binding or state so the if condition for disabled button is not updating real time
                    TextField("Enter budget amount", value: $budgetAmount, formatter: NumberFormatter())
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .keyboardType(.numberPad)
                    
                    Button("Update") {
                        savedSuccess = updateBudgetTotal()
                        //set savedsuccess to false after 2 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            savedSuccess = false
                        }
                    }
                    .buttonStyle(BorderedProminentButtonStyle())
                    .disabled(  budgetAmount == nil || budgetAmount == budgetTotal.totalAmount)
                }
                
                if savedSuccess {
                    //TODO make this look a little better or replace it with a snackbar
                    
                    Text("Budget total updated successfully!")
                        .foregroundColor(.white)
                        .font(.subheadline)
                        .background(.green)
                }
                
                
                //if there are expenses in the budget total, show them
                if budgetTotal.expenses.count > 0 {

                    
                    //create a label for the list that is close to the top of the groupbox
                    Label("Expenses", systemImage: "list.bullet")
                        .font(.title2)
                        .padding(.top, 10)
                        .padding(.bottom,-10)
                    
                    
                    List {
                        ForEach(budgetTotal.expenses, id: \.id) { expense in
                            HStack {
                                VStack (alignment: .leading) {
                                    //show the description of the expense
                                    Text(expense.descriptionText == "" ? "N/A" : expense.descriptionText).font(.headline)
                                    //show a formatted date for the expense
                                    Text(formatDate(date: expense.dateEntered)).font(.caption)
                                }
                                Spacer()
                                Text("\(currencyFormatted(expense.amount))")
                            }
                        }
                    }.padding(5)
                } else {
                    //if there are no expenses, show a message
                    Text("No expenses found for this budget!")
                }
                
                Button(action: {showDetailsSheet.toggle()}) { Text("Close")}
                    .padding(.top, 10)
            }
        } label: {
            Text("\(budgetTotal.budgetType?.name ?? "UNKNOWN")")
                .font(.title2)
                .padding()
        }
        .padding(.horizontal, 25)
        //veritcally align the groupbox to the top
        .padding(.top, 10)
        .offset(y: -100)
        
    }
    
    func formatDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        return formatter.string(from: date)
    }
    
    func currencyFormatted(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(for: amount) ?? ""
    }
    
    func updateBudgetTotal() -> Bool{
        //Update budgetTotal.totalamount to the new value
        guard let realm = try? Realm() else {
            print("Error initializing Realm instance")
            return false
        }
        do {
            var existingBudgetTotal: BudgetTotal
            if let budgetFromRealm: BudgetTotal = realm.object(ofType: BudgetTotal.self, forPrimaryKey: budgetTotal.id) {
                existingBudgetTotal = budgetFromRealm
                print("Found realm budget for update: \(existingBudgetTotal)")
                try realm.write {
                    budgetFromRealm.totalAmount = budgetAmount!
                }
            }
        } catch {
            print("Error updating budget total: \(error)")
            return false
        }
        return true
    }
    
}


#Preview {
    ContentView()
}
