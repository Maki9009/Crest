import Foundation
import Security

/// A server's certificate WebKit was asked to judge, kept so the person can
/// trust it if it fails.
///
/// Reading the certificate makes Security evaluate the trust, a synchronous
/// trip to `securityd` that can take tens of milliseconds, so the identity is
/// read only when something needs it rather than on every connection.
struct BrowserServerTrustChallenge {
    // MARK: - Variables

    let trust: SecTrust
    let host: String
    let port: Int

    /// The identity of the certificate, read when asked for.
    var identity: BrowserServerTrustIdentity? {
        BrowserServerTrustIdentity.identity(for: trust, host: host, port: port)
    }

    // MARK: - Initializers

    /// The challenge `challenge` puts, or nil when it asks about something
    /// other than a server's certificate.
    init?(_ challenge: URLAuthenticationChallenge) {
        let protectionSpace = challenge.protectionSpace
        guard protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
            let trust = protectionSpace.serverTrust
        else { return nil }
        self.trust = trust
        host = protectionSpace.host
        port = protectionSpace.port
    }
}
