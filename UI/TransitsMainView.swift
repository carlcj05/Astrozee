import SwiftUI
import UniformTypeIdentifiers

// MARK: - 1. LE VIEWMODEL (Le cerveau qui partage les données)
class TransitViewModel: ObservableObject {
    @Published var selectedDate = Date()
    @Published var transits: [Transit] = []
    @Published var isCalculating = false
    @Published var calculationDone = false // Pour savoir si on affiche les résultats
    
    func calculate(for profile: Profile) {
        isCalculating = true
        calculationDone = false
        
        // Petit délai pour l'effet UI
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let calendar = Calendar.current
            let month = calendar.component(.month, from: self.selectedDate)
            let year = calendar.component(.year, from: self.selectedDate)
            
            let results = TransitService.computeTransitsForMonth(profile: profile, month: month, year: year)
            
            withAnimation {
                self.transits = results
                self.isCalculating = false
                self.calculationDone = true
            }
        }
    }
}

// MARK: - 2. LA VUE PRINCIPALE (Le conteneur avec les onglets)
struct TransitsMainView: View {
    let profile: Profile
    @StateObject private var viewModel = TransitViewModel()
    @State private var activeTab = 0 // 0 = Profil, 1 = Période, 2 = Résultats
    
    var body: some View {
        TabView(selection: $activeTab) {
            
            // --- ONGLET 1 : PROFIL ---
            TransitProfileView(profile: profile)
                .tabItem {
                    Label("Profil", systemImage: "person.crop.circle")
                }
                .tag(0)
            
            // --- ONGLET 2 : SÉLECTION ---
            TransitDateSelectionView(profile: profile, viewModel: viewModel, activeTab: $activeTab)
                .tabItem {
                    Label("Période", systemImage: "calendar")
                }
                .tag(1)
            
            // --- ONGLET 3 : RÉSULTATS ---
            TransitResultsView(viewModel: viewModel)
                .tabItem {
                    Label("Résultats", systemImage: "list.star")
                }
                .tag(2)
        }
        .navigationTitle("Météo Astrale")
        // FIX MAC: On applique .inline uniquement sur iOS
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

// MARK: - 3. ONGLET PROFIL
struct TransitProfileView: View {
    let profile: Profile
    
    var body: some View {
        ZStack {
            #if os(iOS)
            Color.gray.opacity(0.1).ignoresSafeArea() // Fond gris clair sur iOS
            #endif
            
            VStack(spacing: 30) {
                
                // Carte d'info Profil
                VStack(spacing: 8) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.indigo)
                        .padding(.bottom, 5)
                    
                    Text("Analyse pour \(profile.name)")
                        .font(.title2).bold()
                    
                    Text("Né(e) le \(profile.birthLocalDate.formatted(date: .abbreviated, time: .shortened))")
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                // FIX MAC: Fond blanc sur iOS, transparent ou adapté sur Mac
                .background(Color.white.opacity(0.8))
                .cornerRadius(15)
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top)
        }
    }
}

// MARK: - 4. ONGLET SÉLECTION (Mois + Calcul)
struct TransitDateSelectionView: View {
    let profile: Profile
    @ObservedObject var viewModel: TransitViewModel
    @Binding var activeTab: Int
    
    var body: some View {
        ZStack {
            #if os(iOS)
            Color.gray.opacity(0.1).ignoresSafeArea()
            #endif
            
            VStack(spacing: 30) {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Période d'analyse")
                        .font(.headline)
                    
                    DatePicker("Choisir le mois", selection: $viewModel.selectedDate, displayedComponents: [.date])
                        .datePickerStyle(.graphical)
                        .environment(\.locale, Locale(identifier: "fr_FR"))
                }
                .padding()
                .background(Color.white.opacity(0.8))
                .cornerRadius(15)
                .padding(.horizontal)
                
                Spacer()
                
                Button(action: {
                    viewModel.calculate(for: profile)
                    withAnimation {
                        activeTab = 2
                    }
                }) {
                    HStack {
                        if viewModel.isCalculating {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "sparkles")
                            Text("Lancer le Calcul")
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.indigo)
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .padding(.top)
        }
    }
}

// MARK: - 5. ONGLET RÉSULTATS (La liste)
struct TransitResultsView: View {
    @ObservedObject var viewModel: TransitViewModel
    @State private var isExportingCSV = false
    
    var body: some View {
        VStack {
            if viewModel.isCalculating {
                ProgressView("Calcul des positions planétaires...")
                    .scaleEffect(1.5)
                    .padding()
            } else if !viewModel.calculationDone {
                // État initial avant calcul
                ContentUnavailableView(
                    "En attente",
                    systemImage: "arrow.left.circle",
                    description: Text("Allez dans l'onglet 'Période' pour lancer une analyse.")
                )
            } else if viewModel.transits.isEmpty {
                // Calcul fait mais rien trouvé
                ContentUnavailableView(
                    "Aucun transit majeur",
                    systemImage: "moon.stars",
                    description: Text("Le ciel est calme pour cette période.")
                )
            } else {
                // Affichage des résultats
                List {
                    Section(header: Text("Analyse de \(monthTitle)")) {
                        ForEach(viewModel.transits) { transit in
                            TransitRow(transit: transit) // Utilise ta ligne existante
                        }
                    }
                }
                // FIX MAC: Utiliser un style compatible Mac et iOS
                #if os(macOS)
                .listStyle(.inset)
                #else
                .listStyle(.insetGrouped)
                #endif
            }
        }
    }
    
    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: viewModel.selectedDate).capitalized
    }
}
