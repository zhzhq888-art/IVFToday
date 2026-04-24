import Observation

struct OnboardingFeatureItem: Identifiable {
    let id: String
    let icon: String
    let title: String
    let subtitle: String
}

@Observable
final class OnboardingViewModel {
    let headline = "See dose changes before you miss a med"
    let subheadline = "Import clinic screenshots or PDFs, compare with yesterday, and get a clear plan for today."
    let safetyTitle = "Support tool, not medical advice"
    let safetyMessage = "Always follow your clinic's direct instructions. If there is any mismatch, call your clinic immediately."
    let primaryActionTitle = "Import Today's Instructions"

    let featureItems: [OnboardingFeatureItem] = [
        OnboardingFeatureItem(
            id: "import",
            icon: "square.and.arrow.down",
            title: "Import Instructions",
            subtitle: "Bring in screenshots, photos, and PDFs locally on your device."
        ),
        OnboardingFeatureItem(
            id: "diff",
            icon: "arrow.triangle.2.circlepath",
            title: "See What Changed",
            subtitle: "Review medication and appointment changes against the previous protocol."
        ),
        OnboardingFeatureItem(
            id: "today",
            icon: "sun.max.fill",
            title: "Know What To Do Today",
            subtitle: "Follow a prioritized task list with high-risk confirmation."
        ),
        OnboardingFeatureItem(
            id: "inventory",
            icon: "shippingbox.fill",
            title: "Avoid Running Out",
            subtitle: "Track inventory days-left and get low-stock local reminders."
        )
    ]
}
