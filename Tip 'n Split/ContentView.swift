//
//  ContentView.swift
//  Tip 'n Split
//
//  Created by Coal Cooper on 7/16/24.
//
//  Based on Paul Hudson's "WeSplit" SwiftUI tutorial set
//  https://www.youtube.com/watch?v=u8UOmfYmpoE&list=PLuoeXyslFTuZRi4q4VT6lZKxYbr7so1Mr
//

import SwiftUI

enum FocusedField: String {
    case subtotal = "Subtotal"
    case tax = "Tax"
    case tipPercent = "Tip Percentage"
    case tipValue = "Tip Amount"
}

struct ContentView: View {
    
    @FocusState private var isSubtotalFocused: Bool
    @FocusState private var isTaxFocused: Bool
    @FocusState private var isTipPercentageFocused: Bool
    @FocusState private var isTipAmountFocused: Bool
    
    @State private var subtotal: Double = 10
    @State private var tax: Double = 2
    @State private var splitCountIndex: Int = 1
    
    @State private var tipPercentage: Double = 0.20
    @State private var tip: Double = 2.0
    @State private var tipOnTax: Bool = false
    
    private var total: Double {
        subtotal + tax + tip
    }
    
    private var tipBase: Double {
        tipOnTax ? subtotal + tax : subtotal
    }
    
    private var splitCount: Int {
        splitCountIndex + 1
    }
    
    private var perPersonSubtotal: Double {
        (100 * ( subtotal / Double(splitCount) )).rounded() / 100
    }
    
    private var perPersonTax: Double {
        (100 * ( tax / Double(splitCount) )).rounded() / 100
    }
    
    private var perPersonTip: Double {
        (100 * ( tip / Double(splitCount) )).rounded() / 100
    }
    
    private var perPersonTotal: Double {
        perPersonSubtotal + perPersonTax + perPersonTip
    }
    
    private var roundingError: Double {
        let paidTotal = (100 * Double(splitCount) * perPersonTotal).rounded() / 100
        return paidTotal - total
    }
    
    private let currencyCode = Locale.current.currency?.identifier ?? "USD"
    
    private let tipPercentages = [ 0, 0.15, 0.18, 0.20, 0.25 ]
    
    func getCurrentFocusedField() -> FocusedField? {
        if(isSubtotalFocused) {
            return .subtotal
        }
        if(isTaxFocused) {
            return .tax
        }
        if(isTipPercentageFocused) {
            return .tipPercent
        }
        if(isTipAmountFocused) {
            return .tipValue
        }
        return nil
    }
    
    func getNextFieldFromFocus() -> FocusedField? {
        switch(getCurrentFocusedField()) {
        case .subtotal: return .tax
        case .tax: return .tipPercent
        case .tipPercent: return .tipValue
        case .tipValue: return nil
        default: return nil
        }
    }
    
    func getPreviousFieldFromFocus() -> FocusedField? {
        switch(getCurrentFocusedField()) {
        case .subtotal: return nil
        case .tax: return .subtotal
        case .tipPercent: return .tax
        case .tipValue: return .tipPercent
        default: return nil
        }
    }
    
    func clearFocus() {
        isSubtotalFocused = false
        isTaxFocused = false
        isTipPercentageFocused = false
        isTipAmountFocused = false
    }
    
    func setFocus(_ field: FocusedField?) {
        switch(field) {
        case .subtotal:
            isSubtotalFocused = true
            return
        case .tax:
            isTaxFocused = true
            return
        case .tipPercent:
            isTipPercentageFocused = true
            return
        case .tipValue:
            isTipAmountFocused = true
            return
        default: return
        }
    }
    
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    LabeledContent {
                        TextField(
                            "Check Subtotal",
                            value: $subtotal,
                            format: .currency(code: currencyCode)
                        )
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.decimalPad)
                        .focused($isSubtotalFocused)
                        .onChange(of: subtotal) {(_, _) in
                            tip = tipPercentage * tipBase
                        }
                    } label: {
                        Text("Subtotal")
                    }
                    
                    LabeledContent {
                        TextField(
                            "Check Tax",
                            value: $tax,
                            format: .currency(code: currencyCode)
                        )
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.decimalPad)
                        .focused($isTaxFocused)
                        .onChange(of: tax) {(_, _) in
                            tip = tipPercentage * tipBase
                        }
                    } label: {
                        HStack {
                            Text("Tax")
                            
                            Text(tax / subtotal, format: .percent)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Picker(
                        "Split Between",
                        selection: $splitCountIndex
                    ) {
                        ForEach(1..<101) {
                            if($0 == 1) {
                                Text("Just myself")
                            } else {
                                Text("\($0) people")
                            }
                        }
                    }
                    
                }
                
                Section {
                    HStack {
                        Picker(
                            "Tip Percentage",
                            selection: $tipPercentage
                        ) {
                            ForEach(tipPercentages, id: \.self) {
                                Text($0, format: .percent)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/)
                        .layoutPriority(1)
                        .onChange(of: tipPercentage) {(_, next) in
                            let tipValueUpdate = next * tipBase
                            if tip == tipValueUpdate {
                                return
                            }
                            tip = tipValueUpdate
                        }
                        
                        TextField(
                            "Tip Percentage",
                            value: $tipPercentage,
                            format: .percent
                        )
                        .frame(minWidth: 50)
                        .keyboardType(.decimalPad)
                        .focused($isTipPercentageFocused)
                    }
                    
                    Toggle("Tip on Tax", isOn: $tipOnTax)
                        .onChange(of: tipOnTax) {(_, _) in
                            let tipValueUpdate = tipPercentage * tipBase
                            if tip == tipValueUpdate {
                                return
                            }
                            tip = tipValueUpdate
                        }
                    
                    LabeledContent {
                        TextField(
                            "Tip",
                            value: $tip,
                            format: .currency(
                                code: currencyCode
                            )
                        )
                        .keyboardType(.decimalPad)
                        .focused($isTipAmountFocused)
                        .multilineTextAlignment(.trailing)
                        .onChange(of: tip) {(_, next) in
                            let tipPercentageUpdate = (100 * (next / tipBase)).rounded() / 100
                            if tipPercentage == tipPercentageUpdate {
                                return
                            }
                            tipPercentage = tipPercentageUpdate
                        }
                    } label: {
                        Text("Tip Amount")
                    }
                    
                } header: {
                    HStack {
                        Text("Tip Amount for")
                        Text(tipBase, format: .currency(code: currencyCode))
                    }
                }
                
                Section {
                    LabeledContent {
                        Text(total, format: .currency(code: currencyCode))
                            .bold()
                            .font(.largeTitle)
                    } label: {
                        Text("Total")
                            .bold()
                            .font(.title)
                    }
                }
                .background(Color.green)
                .cornerRadius(10)
                .listRowBackground(Color.green)
                .foregroundColor(.white)
                
                if(splitCount > 1) {
                    if(roundingError != 0) {
                        Section {
                            Label {
                                Text("This split will \(roundingError > 0 ? "overpay" : "underpay") the check by \(abs(roundingError), format: .currency(code: currencyCode))")
                            } icon: {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundColor(.red)
                                    .overlay(
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.yellow)
                                            .mask(Image(systemName: "exclamationmark.triangle"))
                                    )
                            }
                        }
                        .cornerRadius(10)
                        .listRowBackground(Color.clear)
                    }
                    
                    Section {
                        LabeledContent {
                            Text(perPersonTotal, format: .currency(code: currencyCode))
                                .foregroundStyle(Color.green)
                        } label: {
                            Text("Each Pays")
                        }
                        .bold()
                        .font(.title2)
                        
                        LabeledContent {
                            Text(perPersonSubtotal, format: .currency(code: currencyCode))
                        } label: {
                            Text("Subtotal")
                        }
                        .foregroundStyle(.secondary)
                        
                        LabeledContent {
                            Text(perPersonTax, format: .currency(code: currencyCode))
                        } label: {
                            Text("Tax")
                        }
                        .foregroundStyle(.secondary)
                        
                        LabeledContent {
                            Text(perPersonTip, format: .currency(code: currencyCode))
                        } label: {
                            Text("Tip")
                        }
                        .foregroundStyle(.secondary)
                        
                    } header: {
                        Text("Split \(splitCount) Ways")
                    }
                    
                }
            }
            .navigationTitle("Tip 'n Split")
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    HStack {
                        HStack {
                            let previousState = getPreviousFieldFromFocus()
                            
                            Button(action: {
                                setFocus(previousState)
                            }) {
                                Image(systemName: "chevron.up")
                                    .font(.system(size: 16)) // Adjust the size as needed
                                    .buttonStyle(PlainButtonStyle())
                                    .foregroundColor(previousState == nil ? .gray : .blue) // Change the icon color based on the disabled state
                                    .disabled(previousState == nil)
                            }
                            
                            let nextState = getNextFieldFromFocus()
                            
                            Button(action: {
                                setFocus(nextState)
                            }) {
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 16)) // Adjust the size as needed
                                    .buttonStyle(PlainButtonStyle())
                                    .foregroundColor(nextState == nil ? .gray : .blue) // Change the icon color based on the disabled state
                                    .disabled(nextState == nil)
                            }
                        }
                        
                        Spacer()
                        
                        if let focusedField = getCurrentFocusedField() {
                            Text(focusedField.rawValue)
                                .multilineTextAlignment(.center)
                        }
                        
                        Spacer()
                        
                        Button("Done") {
                            clearFocus()
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
