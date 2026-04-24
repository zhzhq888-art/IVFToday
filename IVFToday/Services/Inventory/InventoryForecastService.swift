import Foundation

enum InventoryForecastService {
    private static let defaultForecastHorizonDays: Double = 7

    static func projections(
        for medications: [MedicationPlan],
        inventoryItems: [InventoryItem],
        forecastHorizonDays: Double = defaultForecastHorizonDays
    ) -> [InventoryProjection] {
        inventoryItems.compactMap { item in
            let dailyDose = medications
                .filter { $0.name == item.medicationName && $0.isActive && $0.route != "Instruction" && $0.doseAmount > 0 }
                .reduce(0) { $0 + $1.doseAmount }

            guard dailyDose > 0 else {
                return nil
            }

            let remainingAfterToday = item.remainingAmount - dailyDose
            let remainingAfterForecastHorizon = item.remainingAmount - (dailyDose * max(1, forecastHorizonDays))
            let daysLeft = item.remainingAmount / dailyDose
            let isCritical = remainingAfterToday < 0
            let isProjectedLowWithinHorizon = remainingAfterForecastHorizon <= item.alertThreshold
            let isLowStock = isCritical || remainingAfterToday <= item.alertThreshold || isProjectedLowWithinHorizon

            return InventoryProjection(
                id: item.id,
                medicationName: item.medicationName,
                unit: item.unit,
                remainingAmount: item.remainingAmount,
                alertThresholdAmount: item.alertThreshold,
                dailyDoseAmount: dailyDose,
                remainingAfterToday: remainingAfterToday,
                daysLeft: daysLeft.isFinite ? daysLeft : nil,
                isLowStock: isLowStock,
                isCritical: isCritical
            )
        }
    }

    static func alerts(
        for medications: [MedicationPlan],
        inventoryItems: [InventoryItem],
        forecastHorizonDays: Double = defaultForecastHorizonDays
    ) -> [InventoryAlert] {
        projections(
            for: medications,
            inventoryItems: inventoryItems,
            forecastHorizonDays: forecastHorizonDays
        )
            .compactMap { projection in
                guard projection.isLowStock else {
                    return nil
                }

                let projectedRemainingAmount = projection.remainingAmount - (projection.dailyDoseAmount * max(1, forecastHorizonDays))
                let isProjectedShortage = projectedRemainingAmount <= 0
                let isProjectedLowWithinHorizon = projectedRemainingAmount <= projection.alertThresholdAmount

                if projection.isCritical {
                    return InventoryAlert(
                        id: projection.medicationName.lowercased(),
                        medicationName: projection.medicationName,
                        message: "Current stock does not cover today's dose (\(formattedAmount(projection.dailyDoseAmount, unit: projection.unit))).",
                        daysLeft: projection.daysLeft,
                        isCritical: true
                    )
                }

                if isProjectedShortage {
                    return InventoryAlert(
                        id: projection.medicationName.lowercased(),
                        medicationName: projection.medicationName,
                        message: "Projected shortage within \(Int(max(1, forecastHorizonDays))) days. Refill now.",
                        daysLeft: projection.daysLeft,
                        isCritical: true
                    )
                }

                if isProjectedLowWithinHorizon {
                    return InventoryAlert(
                        id: projection.medicationName.lowercased(),
                        medicationName: projection.medicationName,
                        message: "Projected low stock within \(Int(max(1, forecastHorizonDays))) days: \(formattedAmount(max(0, projectedRemainingAmount), unit: projection.unit)).",
                        daysLeft: projection.daysLeft,
                        isCritical: false
                    )
                }

                return InventoryAlert(
                    id: projection.medicationName.lowercased(),
                    medicationName: projection.medicationName,
                    message: "Low stock after today: \(formattedAmount(max(0, projection.remainingAfterToday), unit: projection.unit)).",
                    daysLeft: projection.daysLeft,
                    isCritical: false
                )
            }
    }

    private static func formattedAmount(_ amount: Double, unit: MedicationUnit) -> String {
        if amount == floor(amount) {
            return "\(Int(amount)) \(unit.rawValue)"
        }

        return "\(amount.formatted()) \(unit.rawValue)"
    }
}
