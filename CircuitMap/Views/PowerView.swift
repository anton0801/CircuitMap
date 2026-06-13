//
//  PowerView.swift
//  CircuitMap
//
//  Tab 3 — Power. Hosts Main Balance (08) and Cost Estimate (09) behind a
//  segmented switch.
//

import SwiftUI

struct PowerView: View {
    @State private var segment = 0

    var body: some View {
        NavigationView {
            ZStack {
                CircuitBackground()
                VStack(spacing: 0) {
                    Picker("", selection: $segment) {
                        Text("Main Balance").tag(0)
                        Text("Cost Estimate").tag(1)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(Theme.Space.m)

                    ScrollView(showsIndicators: false) {
                        Group {
                            if segment == 0 { MainBalanceView() }
                            else { CostEstimateView() }
                        }
                        .padding(.horizontal, Theme.Space.m)
                        .padding(.bottom, Theme.Space.m)
                    }
                }
            }
            .navigationBarTitle("Power", displayMode: .inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
