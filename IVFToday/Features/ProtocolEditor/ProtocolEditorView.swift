import SwiftUI

struct ProtocolEditorView: View {
    @Environment(ThemeController.self) private var themeController
    @Bindable var appState: AppState

    private var theme: AppTheme.Palette {
        themeController.palette
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text(appState.treatmentCase.title)
                        .font(.headline)
                    Text("Update today's manual protocol to validate the workflow before OCR is built.")
                        .font(.caption)
                        .foregroundColor(theme.mutedText)
                }
                .padding(.vertical, 4)
                .listRowBackground(theme.sectionBackground)
            }

            Section("Medications") {
                ForEach($appState.medications) { $medication in
                    VStack(alignment: .leading, spacing: 10) {
                        TextField("Medication", text: $medication.name)
                            .font(.headline)

                        HStack {
                            Text("Dose")
                                .font(.caption)
                                .foregroundColor(theme.mutedText)
                            Spacer()
                            TextField("Dose", value: $medication.doseAmount, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 90)
                            Picker("Unit", selection: $medication.unit) {
                                ForEach(MedicationUnit.allCases, id: \.self) { unit in
                                    Text(unit.rawValue).tag(unit)
                                }
                            }
                            .pickerStyle(.menu)
                        }

                        HStack {
                            Text("Time")
                                .font(.caption)
                                .foregroundColor(theme.mutedText)
                            Spacer()
                            TextField("8:00 PM", text: $medication.scheduledTime)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 120)
                        }

                        HStack {
                            Text("Route")
                                .font(.caption)
                                .foregroundColor(theme.mutedText)
                            Spacer()
                            TextField("Subcutaneous", text: $medication.route)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 160)
                        }

                        TextField("Instructions", text: $medication.instructions, axis: .vertical)
                        Toggle("Mark as critical", isOn: $medication.isCritical)
                    }
                    .padding(.vertical, 6)
                    .listRowBackground(theme.sectionBackground)
                }
                .onDelete(perform: appState.removeMedication)
            }
        }
        .scrollContentBackground(.hidden)
        .background(theme.background)
        .navigationTitle("Edit Protocol")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    appState.addMedication()
                } label: {
                    Label("Add", systemImage: "plus")
                }
            }
        }
        .onChange(of: appState.medications) { _, medications in
            appState.currentDocument = DemoDataFactory.createCurrentProtocolDocument(
                for: appState.treatmentCase.id,
                medications: medications,
                appointments: appState.appointments
            )
        }
    }
}
