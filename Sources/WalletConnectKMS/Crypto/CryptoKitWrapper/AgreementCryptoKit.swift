import Foundation
import CryptoKit

// MARK: - CryptoKit extensions

extension Curve25519.KeyAgreement.PublicKey: Equatable {
    public static func == (lhs: Curve25519.KeyAgreement.PublicKey, rhs: Curve25519.KeyAgreement.PublicKey) -> Bool {
        lhs.rawRepresentation == rhs.rawRepresentation
    }
}

extension Curve25519.KeyAgreement.PrivateKey: Equatable {
    public static func == (lhs: Curve25519.KeyAgreement.PrivateKey, rhs: Curve25519.KeyAgreement.PrivateKey) -> Bool {
        lhs.rawRepresentation == rhs.rawRepresentation
    }
}

// MARK: - Public Key

public struct AgreementPublicKey: GenericPasswordConvertible, Equatable {
    enum Errors: Error {
        case invalidBase64urlString
    }

    fileprivate let key: Curve25519.KeyAgreement.PublicKey

    fileprivate init(publicKey: Curve25519.KeyAgreement.PublicKey) {
        self.key = publicKey
    }

    public init<D>(rawRepresentation data: D) throws where D: ContiguousBytes {
        self.key = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: data)
    }

    public init(hex: String) throws {
        let data = Data(hex: hex)
        try self.init(rawRepresentation: data)
    }

    public init(base64url: String) throws {
        guard let raw = Data(base64url: base64url) else { throw Errors.invalidBase64urlString }
        try self.init(rawRepresentation: raw)
    }

    public var rawRepresentation: Data {
        key.rawRepresentation
    }

    public var hexRepresentation: String {
        key.rawRepresentation.toHexString()
    }

    public var did: String {
        let key = DIDKey(rawData: rawRepresentation)
        return key.did(variant: .X25519)
    }
}

extension AgreementPublicKey: Codable {

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(key.rawRepresentation)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let buffer = try container.decode(Data.self)
        try self.init(rawRepresentation: buffer)
    }
}

// MARK: - Private Key

public struct AgreementPrivateKey: GenericPasswordConvertible, Equatable {

    private let key: Curve25519.KeyAgreement.PrivateKey

    public init() {
        self.key = Curve25519.KeyAgreement.PrivateKey()
    }

    public init<D>(rawRepresentation: D) throws where D: ContiguousBytes {
        self.key = try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: rawRepresentation)
    }

    public var rawRepresentation: Data {
        key.rawRepresentation
    }

    public var publicKey: AgreementPublicKey {
        AgreementPublicKey(publicKey: key.publicKey)
    }

    func sharedSecretFromKeyAgreement(with publicKeyShare: AgreementPublicKey) throws -> SharedSecret {
        let sharedSecret = try key.sharedSecretFromKeyAgreement(with: publicKeyShare.key)
        return SharedSecret(sharedSecret: sharedSecret)
    }
}
