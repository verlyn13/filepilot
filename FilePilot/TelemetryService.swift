//
//  TelemetryService.swift
//  FilePilot
//
//  Telemetry service for tracking app usage and events
//

import Foundation

class TelemetryService: ObservableObject {
    static let shared = TelemetryService()

    private let serverURL = "http://localhost:3000/api/swift/telemetry"
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 2.0
        self.session = URLSession(configuration: config)
    }

    func recordAppLaunch() {
        recordAction("app_launch", metadata: [
            "version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        ])
    }

    func recordAction(_ action: String, metadata: [String: Any] = [:]) {
        // Record action to telemetry backend
        #if DEBUG
        print("[Telemetry] Action: \(action), Metadata: \(metadata)")
        #endif

        // Send to observability server
        sendToServer(action: action, metadata: metadata)
    }

    private func sendToServer(action: String, metadata: [String: Any]) {
        guard let url = URL(string: serverURL) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Map action to event type for server
        let eventType: String
        switch action {
        case "navigation", "navigated":
            eventType = "navigation"
        case let action where action.hasSuffix("_error") || action.contains("error"):
            eventType = "error"
        default:
            eventType = "user_action"
        }

        var enrichedMetadata = metadata
        enrichedMetadata["action"] = action
        enrichedMetadata["app"] = "FilePilot"

        let payload: [String: Any] = [
            "event": eventType,
            "metadata": enrichedMetadata,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload) else {
            return
        }

        request.httpBody = jsonData

        // Send asynchronously, don't block UI
        session.dataTask(with: request) { data, response, error in
            #if DEBUG
            if let error = error {
                print("[Telemetry] Failed to send: \(error.localizedDescription)")
            } else if let httpResponse = response as? HTTPURLResponse {
                print("[Telemetry] Sent successfully: \(httpResponse.statusCode)")
                if let data = data, let responseStr = String(data: data, encoding: .utf8) {
                    print("[Telemetry] Response: \(responseStr)")
                }
            }
            #endif
        }.resume()
    }

    func recordNavigation(to url: URL) {
        recordAction("navigation", metadata: ["path": url.path])
    }

    func recordError(_ error: Error, context: String) {
        recordAction("error", metadata: [
            "error": error.localizedDescription,
            "context": context
        ])
    }
}
