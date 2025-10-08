//import SwiftUI
import Charts

struct TransitView: View {
    @State private var selectedDate = Date()
    @State private var transits: [TransitResult] = []
    
    var body: some View {
        VStack(spacing: 0) {
            
            // --- HAUT DE PAGE : BOUTONS ---
            HStack {
                Text("📅 Période :")
                    .font(.headline)
                
                DatePicker("Date", selection: $selectedDate, displayedComponents: [.date])
                    .labelsHidden()
                    .datePickerStyle(.stepperField)
                
                Button("Lancer l'analyse") {
                    lancerCalcul()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(.blue)
                
                Spacer()
                
                Button("Exporter CSV") {
                    exportCSV()
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            
            // --- GRAPHIQUE (MOOD CHART) ---
            if !transits.isEmpty {
                VStack(alignment: .leading) {
                    Text("Mood Chart")
                        .font(.headline)
                        .padding(.leading)
                    
                    Chart {
                        ForEach(transits) { item in
                            BarMark(
                                x: .value("Jour", item.date, unit: .day),
                                y: .value("Intensité", item.score)
                            )
                            .foregroundStyle(item.score > 0 ? Color.green : Color.red)
                        }
                    }
                    .frame(height: 150)
                    .padding()
                }
                .background(Color.white)
                .cornerRadius(10)
                .padding()
            }
            
            // --- LISTE DES RÉSULTATS ---
            List(transits) { transit in
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text("\(transit.planetTransit) \(transit.aspect) \(transit.planetNatal)")
                            .font(.title3)
                            .bold()
                            .foregroundColor(.blue)
                        Spacer()
                        Text(transit.date.formatted(date: .numeric, time: .omitted))
                            .font(.caption)
                            .padding(5)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(5)
                    }
                    Divider()
                    Text(transit.text)
                        .font(.body)
                        .foregroundColor(.primary)
                }
                .padding(.vertical, 5)
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }
    
    func lancerCalcul() {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: selectedDate)
        let year = calendar.component(.year, from: selectedDate)
        
        // Appel au moteur
        transits = AstrologyEngine.shared.calculateTransits(month: month, year: year)
    }
    
    func exportCSV() {
        let fileName = "MesTransits.csv"
        var csvText = "Date;Aspect;Interpretation\n"
        
        for t in transits {
            let d = t.date.formatted(date: .numeric, time: .omitted)
            let a = "\(t.planetTransit) \(t.aspect) \(t.planetNatal)"
            let i = t.text.replacingOccurrences(of: "\n", with: " ")
            csvText.append("\(d);\(a);\(i)\n")
        }
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.commaSeparatedText]
        savePanel.nameFieldStringValue = fileName
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                try? csvText.write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }
}
//  TransitView.swift
//  Astrozee
//
//  Created by Carl  Ozee on 06/01/2026.
//

