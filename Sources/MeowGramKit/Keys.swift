// Sources/MeowGramKit/Keys.swift

import Foundation

/// Fixed, compiled-in key material for MeowGram.
///
/// The key-band watermark key seeds the DCT-coefficient permutation used to
/// scatter the provenance GUID. It is a *scattering* key, not a secret: the
/// app must be able to read any meowgram's GUID with no prior knowledge, so it
/// necessarily ships inside the binary. Confidentiality of user messages comes
/// from the optional passphrase (see `MeowGram.embedMessage`), not from this.
public enum MeowGramKeys {

    /// 32 fixed random bytes seeding the `.key`-band permutation. Changing
    /// these orphans every previously keyed image, so it is frozen.
    public static let keyBandKey: [UInt8] = [
        0x4d, 0x65, 0x6f, 0x77, 0x47, 0x72, 0x61, 0x6d,
        0x9a, 0x3f, 0xe1, 0x07, 0xb2, 0x5c, 0x8d, 0x44,
        0x21, 0xf6, 0x0b, 0x9e, 0x73, 0xa8, 0x1d, 0xcf,
        0x56, 0x30, 0xe9, 0x87, 0x64, 0xba, 0x12, 0xdd
    ]

    /// QIM step for the provenance-GUID band. Larger than the message band's
    /// step so the GUID keeps a wide error margin through a later message
    /// embed's pixel round-trip.
    public static let keyBandQimStep: Float = 48.0

    /// QIM step for the user-message band.
    public static let messageBandQimStep: Float = 32.0

    /// Domain-separation label mixed into the per-image message-band key.
    public static let messageKeyLabel = "meowgram-msg-v1"
}
