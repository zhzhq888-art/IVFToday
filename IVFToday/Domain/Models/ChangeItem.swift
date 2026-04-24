import Foundation

struct ChangeItem: Identifiable, Hashable, Codable {
    let id: String
    let type: ChangeType
    let subjectType: ChangeSubjectType
    let subjectName: String
    let oldValue: String?
    let newValue: String?
    let isCritical: Bool

    init(
        id: String,
        type: ChangeType,
        subjectType: ChangeSubjectType = .medication,
        subjectName: String,
        oldValue: String? = nil,
        newValue: String? = nil,
        isCritical: Bool = false
    ) {
        self.id = id
        self.type = type
        self.subjectType = subjectType
        self.subjectName = subjectName
        self.oldValue = oldValue
        self.newValue = newValue
        self.isCritical = isCritical
    }

    var medicationName: String {
        subjectName
    }
}
