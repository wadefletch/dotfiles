import Cocoa
import CoreLocation
import CoreWLAN

// Prints the current Wi-Fi SSID to stdout.
//
// macOS treats the SSID as location data: CoreWLAN returns nil (and the stock
// CLIs print "<redacted>") unless the calling app holds a Location Services
// grant. This helper is that app — first run pops the one-time permission
// prompt; every run after that answers instantly. It must run as a real
// NSApplication from an .app bundle: TCC won't attribute a location grant
// (or show the prompt) for a bare CLI binary.
//
// Exit codes:
//   0 — authorized; stdout is the SSID, or empty when Wi-Fi is disconnected
//   1 — Location Services denied/restricted for this app
//   2 — timed out waiting for an authorization decision (prompt unanswered)

final class AppDelegate: NSObject, NSApplicationDelegate, CLLocationManagerDelegate {
    private var location: CLLocationManager?

    func applicationDidFinishLaunching(_ note: Notification) {
        location = CLLocationManager()
        // Setting the delegate fires locationManagerDidChangeAuthorization
        // with the current status, so all paths start there.
        location?.delegate = self
        // Cap the wait so an unanswered permission prompt can't wedge callers.
        DispatchQueue.main.asyncAfter(deadline: .now() + 20) { exit(2) }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestAlwaysAuthorization()
        case .restricted, .denied:
            exit(1)
        default:
            if let ssid = CWWiFiClient.shared().interface()?.ssid() {
                print(ssid)
            }
            exit(0)
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
