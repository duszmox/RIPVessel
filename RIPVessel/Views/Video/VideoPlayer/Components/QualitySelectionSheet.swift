//
//  QualitySelectionSheet.swift
//  RIPVessel
//
//  Created by Gyula Kiri on 2024. 12. 04..
//

import SwiftUI

struct QualitySelectionSheet: View {
    let qualities: [Components.Schemas.CdnDeliveryV3Variant]
    @Binding var currentQuality: Components.Schemas.CdnDeliveryV3Variant?
    @Binding var isPresented: Bool

    var body: some View {
        VStack {
            Text("Select Quality")
                .font(.headline)
                .padding()

            Divider()

            List(qualities.filter({ q in
                q.url != ""
                
            }), id: \.self) { quality in
                Button(action: {
                    DispatchQueue.main.async {
                        self.currentQuality = quality
                    }
                    isPresented = false
                }) {
                    HStack {
                        Text(quality.label)
                        Spacer()
                        if quality == currentQuality {
                            Image(systemName: "checkmark")
                        }
                    }
                    .padding()
                }
            }
            .listStyle(PlainListStyle())
        }
        .presentationDetents([.fraction(0.4)])
        .background(Color(UIColor.systemBackground))
    }
}
