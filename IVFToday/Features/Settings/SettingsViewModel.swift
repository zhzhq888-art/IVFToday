import Observation

@Observable
final class SettingsViewModel {
    let notificationTitle = "Enable local reminders"
    let notificationSubtitle = "When stock is low, schedule local alerts on this device."

    let onboardingTitle = "Replay Quick Walkthrough"
    let onboardingSubtitle = "Re-open the first-run guidance and safety positioning at any time."

    let resetTitle = "Reset Demo Data"
    let resetSubtitle = "Replace current local state with the default demo cycle and clear completion logs."
    let resetConfirmationTitle = "Reset local demo data?"
    let resetConfirmationMessage = "This replaces current local app data on this device and cannot be undone."

    let safetyDisclaimer = "IVFToday is an organization aid. It does not provide medical advice, diagnosis, or treatment recommendations."
    let privacyStatement = "All processing is local-first. No backend or cloud sync is required in this prototype."
}
