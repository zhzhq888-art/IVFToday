import SwiftUI

struct ParsedProtocolView: View {
    @Environment(ThemeController.self) private var themeController
    let payload: ImportedDocumentPayload
    @Bindable var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var reviewText: String
    @State private var excludedParsedLineIndices: Set<Int> = []
    @State private var editableParsedLines: [Int: EditableParsedLine] = [:]
    @State private var expandedEditorLineIndices: Set<Int> = []
    @State private var excludedParsedAppointmentLineIndices: Set<Int> = []
    @State private var editableParsedAppointments: [Int: EditableParsedAppointment] = [:]
    @State private var expandedAppointmentEditorLineIndices: Set<Int> = []
    private let draftValidationService = MedicationDraftValidationService()

    init(payload: ImportedDocumentPayload, appState: AppState) {
        self.payload = payload
        self.appState = appState
        _reviewText = State(initialValue: payload.normalizedText)
    }

    private var extractedLines: [String] {
        reviewText
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private var parserResults: [MedicationLineParser.LineResult] {
        MedicationLineParser().parseLines(extractedLines)
    }

    private var appointmentParserResults: [AppointmentLineParser.LineResult] {
        AppointmentLineParser().parseLines(extractedLines)
    }

    private var parsedLineIndices: [Int] {
        parserResults.enumerated().compactMap { index, result in
            result.state == .parsed ? index : nil
        }
    }

    private var unparsedCandidates: [MedicationLineParser.LineResult] {
        parserResults.filter { $0.state == .unparsed }
    }

    private var parsedAppointmentLineIndices: [Int] {
        appointmentParserResults.enumerated().compactMap { index, result in
            result.state == .parsed ? index : nil
        }
    }

    private var includedParsedCandidates: [(index: Int, result: MedicationLineParser.LineResult)] {
        parserResults.enumerated().compactMap { index, result in
            guard result.state == .parsed, !excludedParsedLineIndices.contains(index) else {
                return nil
            }
            return (index, result)
        }
    }

    private var mappedMedications: [MedicationPlan] {
        includedParsedCandidates.compactMap { index, result in
            let editable = editableParsedLines[index] ?? defaultEditableLine(for: result)
            return medicationPlan(from: editable, fallbackLine: result)
        }
    }

    private var includedParsedAppointmentCandidates: [(index: Int, result: AppointmentLineParser.LineResult)] {
        appointmentParserResults.enumerated().compactMap { index, result in
            guard result.state == .parsed, !excludedParsedAppointmentLineIndices.contains(index) else {
                return nil
            }
            return (index, result)
        }
    }

    private var mappedAppointments: [AppointmentItem] {
        includedParsedAppointmentCandidates.map { index, result in
            let editable = editableParsedAppointments[index] ?? defaultEditableAppointment(for: result)
            return appointmentItem(from: editable, fallbackResult: result)
        }
    }

    private var validationIssuesByLine: [Int: [String]] {
        var issues: [Int: [String]] = [:]

        for candidate in includedParsedCandidates {
            let editable = editableParsedLines[candidate.index] ?? defaultEditableLine(for: candidate.result)
            let lineIssues = validationIssues(for: editable)
            if !lineIssues.isEmpty {
                issues[candidate.index] = lineIssues
            }
        }

        return issues
    }

    private var hasValidationIssues: Bool {
        !validationIssuesByLine.isEmpty
    }

    private var inactiveInstructionMedications: [MedicationPlan] {
        mappedMedications.filter { !$0.isActive }
    }

    private var activeMedications: [MedicationPlan] {
        mappedMedications.filter(\.isActive)
    }

    private var activeSummaryMedications: [MedicationPlan] {
        Array(activeMedications.prefix(4))
    }

    private var instructionSummaryMedications: [MedicationPlan] {
        Array(inactiveInstructionMedications.prefix(3))
    }

    private var appointmentSummaryItems: [AppointmentItem] {
        Array(mappedAppointments.prefix(4))
    }

    private var theme: AppTheme.Palette {
        themeController.palette
    }

    var body: some View {
        List {
            Section("Review Summary") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Local-only extraction review")
                        .font(.headline)
                    Text("Review and edit extracted lines before applying structured medications.")
                        .font(.caption)
                        .foregroundColor(theme.mutedText)

                    HStack {
                        Label("\(extractedLines.count) lines", systemImage: "text.alignleft")
                        Spacer()
                        Label("\(reviewText.count) chars", systemImage: "character")
                    }
                    .font(.caption)
                    .foregroundColor(theme.mutedText)

                    HStack {
                        Label("\(includedParsedCandidates.count) selected", systemImage: "checkmark.circle")
                        Spacer()
                        Label("\(unparsedCandidates.count) unparsed", systemImage: "questionmark.circle")
                    }
                    .font(.caption)
                    .foregroundColor(theme.mutedText)

                    HStack {
                        Label("\(mappedAppointments.count) appointments", systemImage: "calendar")
                        Spacer()
                        Label("\(includedParsedAppointmentCandidates.count) selected lines", systemImage: "line.3.horizontal.decrease.circle")
                    }
                    .font(.caption)
                    .foregroundColor(theme.mutedText)
                }
                .padding(.vertical, 4)
                .listRowBackground(theme.sectionBackground)
            }

            Section("Source") {
                LabeledContent("Name", value: payload.displayName)
                LabeledContent("Type", value: sourceTypeName(payload.sourceType))
                LabeledContent("Captured", value: dateString(payload.capturedAt))
            }
            .listRowBackground(theme.sectionBackground)

            Section("Normalized Text (Editable)") {
                if reviewText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("No extracted text is available yet. Try re-importing a clearer image/PDF.")
                        .foregroundColor(theme.mutedText)
                        .italic()
                }

                TextEditor(text: $reviewText)
                    .frame(minHeight: 160)
            }
            .listRowBackground(theme.sectionBackground)

            Section("Line-by-line Review") {
                if parserResults.isEmpty {
                    Text("No extracted lines to review.")
                        .foregroundColor(theme.mutedText)
                        .italic()
                } else {
                    HStack {
                        Button("Include All Parsed") {
                            excludedParsedLineIndices.removeAll()
                        }
                        .font(.caption.weight(.semibold))

                        Spacer()

                        Button("Exclude All Parsed") {
                            excludedParsedLineIndices = Set(parsedLineIndices)
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundColor(theme.caution)
                    }

                    ForEach(Array(parserResults.enumerated()), id: \.offset) { index, result in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Line \(index + 1)")
                                    .font(.caption)
                                    .foregroundColor(theme.mutedText)
                                Spacer()
                                if result.state == .parsed {
                                    HStack(spacing: 12) {
                                        Button {
                                            toggleInlineEditor(index)
                                        } label: {
                                            Text(expandedEditorLineIndices.contains(index) ? "Done" : "Edit")
                                                .font(.caption.weight(.semibold))
                                                .foregroundColor(theme.primary)
                                        }
                                        .buttonStyle(.plain)

                                        Button {
                                            toggleParsedLine(index)
                                        } label: {
                                            Text(excludedParsedLineIndices.contains(index) ? "Excluded" : "Will Apply")
                                                .font(.caption.weight(.semibold))
                                                .foregroundColor(
                                                    excludedParsedLineIndices.contains(index)
                                                    ? theme.caution
                                                    : theme.success
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                } else {
                                    Text("Unparsed")
                                        .font(.caption)
                                        .foregroundColor(theme.caution)
                                }
                            }
                            Text(result.rawLine)
                                .font(.body)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            if result.state == .unparsed {
                                Text("This line will not be applied.")
                                    .font(.caption)
                                    .foregroundColor(theme.mutedText)
                            }

                            if result.state == .parsed {
                                VStack(alignment: .leading, spacing: 2) {
                                    if let directive = result.directive {
                                        Text("Directive: \(directive.displayText)")
                                    }
                                    if let medicationName = result.medicationName {
                                        Text("Medication: \(medicationName)")
                                    }
                                    if let dose = result.doseAmount, let unit = result.unit {
                                        Text("Dose: \(dose) \(unit)")
                                    }
                                    if let time = result.scheduledTime {
                                        Text("Time: \(time)")
                                    }
                                    if result.directive?.isActiveDirective == false {
                                        Text("Outcome: Will be imported as an inactive instruction")
                                    } else if result.directive != nil && result.doseAmount == nil {
                                        Text("Outcome: Will be imported as an active instruction")
                                    }
                                    if excludedParsedLineIndices.contains(index) {
                                        Text("This parsed line is currently excluded from apply.")
                                    }
                                }
                                .font(.caption)
                                .foregroundColor(theme.mutedText)

                                if expandedEditorLineIndices.contains(index) {
                                    inlineEditor(for: index, result: result)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .listRowBackground(theme.sectionBackground)

            Section("Appointment Review") {
                if appointmentParserResults.isEmpty {
                    Text("No extracted lines to review.")
                        .foregroundColor(theme.mutedText)
                        .italic()
                } else {
                    HStack {
                        Button("Include All Parsed") {
                            excludedParsedAppointmentLineIndices.removeAll()
                        }
                        .font(.caption.weight(.semibold))

                        Spacer()

                        Button("Exclude All Parsed") {
                            excludedParsedAppointmentLineIndices = Set(parsedAppointmentLineIndices)
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundColor(theme.caution)
                    }

                    ForEach(Array(appointmentParserResults.enumerated()), id: \.offset) { index, result in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Line \(index + 1)")
                                    .font(.caption)
                                    .foregroundColor(theme.mutedText)
                                Spacer()
                                if result.state == .parsed {
                                    HStack(spacing: 12) {
                                        Button {
                                            toggleAppointmentInlineEditor(index)
                                        } label: {
                                            Text(expandedAppointmentEditorLineIndices.contains(index) ? "Done" : "Edit")
                                                .font(.caption.weight(.semibold))
                                                .foregroundColor(theme.primary)
                                        }
                                        .buttonStyle(.plain)

                                        Button {
                                            toggleParsedAppointmentLine(index)
                                        } label: {
                                            Text(excludedParsedAppointmentLineIndices.contains(index) ? "Excluded" : "Will Apply")
                                                .font(.caption.weight(.semibold))
                                                .foregroundColor(
                                                    excludedParsedAppointmentLineIndices.contains(index)
                                                    ? theme.caution
                                                    : theme.success
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                } else {
                                    Text("Unparsed")
                                        .font(.caption)
                                        .foregroundColor(theme.caution)
                                }
                            }
                            Text(result.rawLine)
                                .font(.body)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            if result.state == .parsed {
                                VStack(alignment: .leading, spacing: 2) {
                                    if let title = result.title {
                                        Text("Title: \(title)")
                                    }
                                    if let kind = result.kind {
                                        Text("Kind: \(kind.capitalized)")
                                    }
                                    if let time = result.scheduledTimeText {
                                        Text("Time: \(time)")
                                    }
                                    if let location = result.locationText {
                                        Text("Location: \(location)")
                                    }
                                    if result.isCritical {
                                        Text("Critical event")
                                    }
                                }
                                .font(.caption)
                                .foregroundColor(theme.mutedText)

                                if expandedAppointmentEditorLineIndices.contains(index) {
                                    appointmentInlineEditor(for: index, result: result)
                                }
                            } else {
                                Text("This line will not be applied as an appointment.")
                                    .font(.caption)
                                    .foregroundColor(theme.mutedText)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .listRowBackground(theme.sectionBackground)
        }
        .navigationTitle("Extracted Text Review")
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(theme.background)
        .onAppear {
            rebuildEditableParsedLines()
            rebuildEditableParsedAppointments()
        }
        .onChange(of: reviewText) { _, _ in
            excludedParsedLineIndices.removeAll()
            excludedParsedAppointmentLineIndices.removeAll()
            rebuildEditableParsedLines()
            rebuildEditableParsedAppointments()
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Apply Summary")
                            .font(.headline)
                            .foregroundColor(theme.primary)

                        Text(mappedMedications.isEmpty
                             ? "No structured medications will be applied yet."
                             : "Review the structured medications below before applying them to Today, Changes, and Inventory.")
                            .font(.caption)
                            .foregroundColor(theme.mutedText)
                    }

                    HStack(spacing: 12) {
                        summaryMetric(title: "Active", value: "\(activeMedications.count)")
                        summaryMetric(title: "Inactive", value: "\(inactiveInstructionMedications.count)")
                        summaryMetric(title: "Appointments", value: "\(mappedAppointments.count)")
                    }

                    if !excludedParsedLineIndices.isEmpty {
                        Text("\(excludedParsedLineIndices.count) parsed \(excludedParsedLineIndices.count == 1 ? "line is" : "lines are") excluded from apply.")
                            .font(.caption)
                            .foregroundColor(theme.caution)
                    }

                    if hasValidationIssues {
                        Text("Fix \(validationIssuesByLine.count) line \(validationIssuesByLine.count == 1 ? "issue" : "issues") before apply.")
                            .font(.caption)
                            .foregroundColor(theme.critical)
                    }

                    if !activeSummaryMedications.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Active medications")
                                .font(.caption)
                                .foregroundColor(theme.mutedText)

                            ForEach(Array(activeSummaryMedications.enumerated()), id: \.offset) { index, medication in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(index + 1). \(medication.name)")
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                    Text("\(medication.formattedDose) • \(medication.scheduledTime) • \(medication.route)")
                                        .font(.caption)
                                        .foregroundColor(theme.mutedText)
                                    if !medication.instructions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        Text(medication.instructions)
                                            .font(.caption2)
                                            .foregroundColor(theme.mutedText)
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }

                    if !instructionSummaryMedications.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Inactive instructions")
                                .font(.caption)
                                .foregroundColor(theme.mutedText)

                            ForEach(Array(instructionSummaryMedications.enumerated()), id: \.offset) { index, medication in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(index + 1). \(medication.name)")
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                    Text("\(medication.scheduledTime) • \(medication.route)")
                                        .font(.caption)
                                        .foregroundColor(theme.mutedText)
                                    Text(medication.instructions)
                                        .font(.caption2)
                                        .foregroundColor(theme.mutedText)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }

                    if !appointmentSummaryItems.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Appointments")
                                .font(.caption)
                                .foregroundColor(theme.mutedText)

                            ForEach(Array(appointmentSummaryItems.enumerated()), id: \.offset) { index, appointment in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(index + 1). \(appointment.title)")
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                    Text("\(appointment.kind.capitalized)\(appointment.scheduledTimeText.map { " • \($0)" } ?? "")\(appointment.locationText.map { " • \($0)" } ?? "")")
                                        .font(.caption)
                                        .foregroundColor(theme.mutedText)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }

                    if !unparsedCandidates.isEmpty {
                        Text("Warning: \(unparsedCandidates.count) extracted \(unparsedCandidates.count == 1 ? "line was" : "lines were") not mapped and will not be applied.")
                            .font(.caption)
                            .foregroundColor(theme.critical)
                    }
                }
                .padding(.horizontal)

                Button {
                    appState.applyImportedProtocol(
                        sourceType: payload.sourceType,
                        sourceFilename: payload.displayName,
                        rawText: payload.rawText,
                        normalizedText: reviewText,
                        medications: mappedMedications,
                        appointments: mappedAppointments
                    )
                    dismiss()
                } label: {
                    Text(applyButtonTitle)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled((mappedMedications.isEmpty && mappedAppointments.isEmpty) || hasValidationIssues)
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .padding(.top, 8)
            .background(.thinMaterial)
        }
    }

    private func summaryMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundColor(theme.mutedText)
            Text(value)
                .font(.headline)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(theme.sectionBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func toggleParsedLine(_ index: Int) {
        if excludedParsedLineIndices.contains(index) {
            excludedParsedLineIndices.remove(index)
        } else {
            excludedParsedLineIndices.insert(index)
        }
    }

    private func toggleParsedAppointmentLine(_ index: Int) {
        if excludedParsedAppointmentLineIndices.contains(index) {
            excludedParsedAppointmentLineIndices.remove(index)
        } else {
            excludedParsedAppointmentLineIndices.insert(index)
        }
    }

    @ViewBuilder
    private func inlineEditor(for index: Int, result: MedicationLineParser.LineResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Edit parsed values before apply")
                .font(.caption.weight(.semibold))
                .foregroundColor(theme.mutedText)

            TextField("Medication name", text: textBinding(for: index, keyPath: \.medicationName))
                .textInputAutocapitalization(.words)

            HStack(spacing: 8) {
                TextField("Dose", text: textBinding(for: index, keyPath: \.doseAmount))
                    .keyboardType(.decimalPad)
                Picker("Unit", selection: unitBinding(for: index)) {
                    ForEach(MedicationUnit.allCases, id: \.self) { unit in
                        Text(unit.rawValue).tag(unit)
                    }
                }
                .pickerStyle(.menu)
            }

            TextField("Time", text: textBinding(for: index, keyPath: \.scheduledTime))
            TextField("Route", text: textBinding(for: index, keyPath: \.route))
            TextField("Instructions", text: textBinding(for: index, keyPath: \.instructions), axis: .vertical)
                .lineLimit(2...4)

            Toggle("Active medication", isOn: isActiveBinding(for: index))
                .toggleStyle(.switch)

            HStack {
                Spacer()
                Button("Reset") {
                    editableParsedLines[index] = defaultEditableLine(for: result)
                }
                .font(.caption.weight(.semibold))
            }

            if let issues = validationIssuesByLine[index], !issues.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(issues, id: \.self) { issue in
                        Text("• \(issue)")
                            .font(.caption)
                            .foregroundColor(theme.critical)
                    }
                }
            }
        }
        .padding(10)
        .background(theme.sectionBackground.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func toggleInlineEditor(_ index: Int) {
        if expandedEditorLineIndices.contains(index) {
            expandedEditorLineIndices.remove(index)
        } else {
            expandedEditorLineIndices.insert(index)
        }
    }

    @ViewBuilder
    private func appointmentInlineEditor(for index: Int, result: AppointmentLineParser.LineResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Edit appointment values before apply")
                .font(.caption.weight(.semibold))
                .foregroundColor(theme.mutedText)

            TextField("Title", text: appointmentTextBinding(for: index, keyPath: \.title))
                .textInputAutocapitalization(.words)
            TextField("Kind", text: appointmentTextBinding(for: index, keyPath: \.kind))
            TextField("Time", text: appointmentTextBinding(for: index, keyPath: \.scheduledTimeText))
            TextField("Location", text: appointmentTextBinding(for: index, keyPath: \.locationText))
            Toggle("Critical event", isOn: appointmentCriticalBinding(for: index))
                .toggleStyle(.switch)

            HStack {
                Spacer()
                Button("Reset") {
                    editableParsedAppointments[index] = defaultEditableAppointment(for: result)
                }
                .font(.caption.weight(.semibold))
            }
        }
        .padding(10)
        .background(theme.sectionBackground.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func toggleAppointmentInlineEditor(_ index: Int) {
        if expandedAppointmentEditorLineIndices.contains(index) {
            expandedAppointmentEditorLineIndices.remove(index)
        } else {
            expandedAppointmentEditorLineIndices.insert(index)
        }
    }

    private func rebuildEditableParsedLines() {
        editableParsedLines = Dictionary(uniqueKeysWithValues: parserResults.enumerated().compactMap { index, result in
            guard result.state == .parsed else {
                return nil
            }
            return (index, defaultEditableLine(for: result))
        })
        expandedEditorLineIndices = expandedEditorLineIndices.intersection(Set(editableParsedLines.keys))
    }

    private func rebuildEditableParsedAppointments() {
        editableParsedAppointments = Dictionary(uniqueKeysWithValues: appointmentParserResults.enumerated().compactMap { index, result in
            guard result.state == .parsed else {
                return nil
            }
            return (index, defaultEditableAppointment(for: result))
        })
        expandedAppointmentEditorLineIndices = expandedAppointmentEditorLineIndices.intersection(Set(editableParsedAppointments.keys))
    }

    private func defaultEditableLine(for result: MedicationLineParser.LineResult) -> EditableParsedLine {
        let defaultPlan = ImportedProtocolMapper().mapToMedicationPlans(from: [result]).first
        let defaultName = result.medicationName?.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallbackName = (defaultName?.isEmpty == false) ? defaultName! : (defaultPlan?.name ?? "Imported Medication")
        let fallbackDose = result.doseAmount ?? doseString(from: defaultPlan?.doseAmount)
        let fallbackTime = result.scheduledTime ?? defaultPlan?.scheduledTime ?? ""
        let fallbackRoute = defaultPlan?.route ?? "Instruction"
        let fallbackInstructions = defaultPlan?.instructions ?? result.remainingText ?? "Imported from extracted protocol line"
        let fallbackActive = defaultPlan?.isActive ?? (result.directive?.isActiveDirective ?? true)

        return EditableParsedLine(
            medicationName: fallbackName,
            doseAmount: fallbackDose,
            unit: defaultPlan?.unit ?? mapUnit(result.unit),
            scheduledTime: fallbackTime,
            route: fallbackRoute,
            instructions: fallbackInstructions,
            isActive: fallbackActive
        )
    }

    private func medicationPlan(
        from editable: EditableParsedLine,
        fallbackLine: MedicationLineParser.LineResult
    ) -> MedicationPlan {
        let name = nonEmpty(editable.medicationName) ?? "Imported Medication"
        let instructions = nonEmpty(editable.instructions) ?? "Imported from extracted protocol line"
        let lower = "\(name) \(instructions)".lowercased()
        let isCritical = lower.contains("trigger") || lower.contains("urgent")
        let defaultPlan = ImportedProtocolMapper().mapToMedicationPlans(from: [fallbackLine]).first

        return MedicationPlan(
            name: name,
            doseAmount: Double(editable.doseAmount) ?? 0,
            unit: editable.unit,
            route: nonEmpty(editable.route) ?? defaultPlan?.route ?? "Instruction",
            scheduledTime: nonEmpty(editable.scheduledTime) ?? defaultPlan?.scheduledTime ?? "As needed",
            instructions: instructions,
            isCritical: isCritical,
            isActive: editable.isActive
        )
    }

    private func defaultEditableAppointment(for result: AppointmentLineParser.LineResult) -> EditableParsedAppointment {
        EditableParsedAppointment(
            title: result.title ?? "Appointment",
            kind: result.kind ?? "appointment",
            scheduledTimeText: result.scheduledTimeText ?? "",
            locationText: result.locationText ?? "",
            isCritical: result.isCritical
        )
    }

    private func appointmentItem(
        from editable: EditableParsedAppointment,
        fallbackResult: AppointmentLineParser.LineResult
    ) -> AppointmentItem {
        AppointmentItem(
            title: nonEmpty(editable.title) ?? fallbackResult.title ?? "Appointment",
            scheduledDate: nil,
            scheduledTimeText: nonEmpty(editable.scheduledTimeText),
            locationText: nonEmpty(editable.locationText),
            kind: nonEmpty(editable.kind) ?? fallbackResult.kind ?? "appointment",
            isCritical: editable.isCritical,
            sourceLine: fallbackResult.rawLine
        )
    }

    private func textBinding(
        for index: Int,
        keyPath: WritableKeyPath<EditableParsedLine, String>
    ) -> Binding<String> {
        Binding(
            get: {
                editableParsedLines[index]?[keyPath: keyPath] ?? ""
            },
            set: { newValue in
                guard var editable = editableParsedLines[index] else {
                    return
                }
                editable[keyPath: keyPath] = newValue
                editableParsedLines[index] = editable
            }
        )
    }

    private func unitBinding(for index: Int) -> Binding<MedicationUnit> {
        Binding(
            get: {
                editableParsedLines[index]?.unit ?? .mg
            },
            set: { newUnit in
                guard var editable = editableParsedLines[index] else {
                    return
                }
                editable.unit = newUnit
                editableParsedLines[index] = editable
            }
        )
    }

    private func isActiveBinding(for index: Int) -> Binding<Bool> {
        Binding(
            get: {
                editableParsedLines[index]?.isActive ?? true
            },
            set: { newValue in
                guard var editable = editableParsedLines[index] else {
                    return
                }
                editable.isActive = newValue
                editableParsedLines[index] = editable
            }
        )
    }

    private func appointmentTextBinding(
        for index: Int,
        keyPath: WritableKeyPath<EditableParsedAppointment, String>
    ) -> Binding<String> {
        Binding(
            get: {
                editableParsedAppointments[index]?[keyPath: keyPath] ?? ""
            },
            set: { newValue in
                guard var editable = editableParsedAppointments[index] else {
                    return
                }
                editable[keyPath: keyPath] = newValue
                editableParsedAppointments[index] = editable
            }
        )
    }

    private func appointmentCriticalBinding(for index: Int) -> Binding<Bool> {
        Binding(
            get: {
                editableParsedAppointments[index]?.isCritical ?? false
            },
            set: { newValue in
                guard var editable = editableParsedAppointments[index] else {
                    return
                }
                editable.isCritical = newValue
                editableParsedAppointments[index] = editable
            }
        )
    }

    private func nonEmpty(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func validationIssues(for editable: EditableParsedLine) -> [String] {
        draftValidationService.validate(
            .init(
                medicationName: editable.medicationName,
                doseAmount: editable.doseAmount,
                scheduledTime: editable.scheduledTime,
                route: editable.route,
                instructions: editable.instructions,
                isActive: editable.isActive
            )
        )
    }

    private var applyButtonTitle: String {
        if mappedMedications.isEmpty && mappedAppointments.isEmpty {
            return "No Structured Items to Apply"
        }
        if hasValidationIssues {
            return "Fix \(validationIssuesByLine.count) Issue\(validationIssuesByLine.count == 1 ? "" : "s") to Apply"
        }
        let medicationCount = mappedMedications.count
        let appointmentCount = mappedAppointments.count
        if appointmentCount == 0 {
            return "Apply \(medicationCount) Medications"
        }
        return "Apply \(medicationCount) Medications + \(appointmentCount) Appointments"
    }

    private func mapUnit(_ value: String?) -> MedicationUnit {
        switch value?.lowercased() {
        case "iu", "unit", "units":
            return .iu
        case "mg":
            return .mg
        case "mcg", "μg":
            return .mcg
        case "ml", "m1":
            return .ml
        default:
            return .mg
        }
    }

    private func doseString(from value: Double?) -> String {
        guard let value else {
            return ""
        }
        if value == floor(value) {
            return "\(Int(value))"
        }
        return value.formatted()
    }

    private func sourceTypeName(_ type: DocumentSourceType) -> String {
        switch type {
        case .screenshot:
            return "Screenshot"
        case .photo:
            return "Photo"
        case .pdf:
            return "PDF"
        case .manualEntry:
            return "Manual Entry"
        }
    }

    private func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

private struct EditableParsedLine {
    var medicationName: String
    var doseAmount: String
    var unit: MedicationUnit
    var scheduledTime: String
    var route: String
    var instructions: String
    var isActive: Bool
}

private struct EditableParsedAppointment {
    var title: String
    var kind: String
    var scheduledTimeText: String
    var locationText: String
    var isCritical: Bool
}

#Preview("With text") {
    NavigationStack {
        ParsedProtocolView(
            payload: ImportedDocumentPayload(
                id: UUID(),
                sourceType: .pdf,
                displayName: "IVF_Protocol.pdf",
                rawText: "Gonal-F 150 IU 8:00 PM\nCetrotide 0.25 mg 7:00 AM\nCall clinic after meds",
                normalizedText: "Gonal-F 150 IU 8:00 PM\nCetrotide 0.25 mg 7:00 AM\nCall clinic after meds",
                capturedAt: Date(),
                previewImageData: nil,
                sourceURL: nil
            ),
            appState: DemoDataFactory.createAppState()
        )
        .environment(ThemeController())
    }
}

#Preview("Empty") {
    NavigationStack {
        ParsedProtocolView(
            payload: ImportedDocumentPayload(
                id: UUID(),
                sourceType: .screenshot,
                displayName: "IMG_1234.png",
                rawText: "",
                normalizedText: "",
                capturedAt: Date(),
                previewImageData: nil,
                sourceURL: nil
            ),
            appState: DemoDataFactory.createAppState()
        )
        .environment(ThemeController())
    }
}
