// Sources/MeowStego/ECC.swift
// Reed-Solomon RS(255, 255-nsym) error-correcting code over GF(2^8).
// Primitive polynomial: x^8 + x^4 + x^3 + x^2 + 1  (0x11D)

// MARK: – GF(2^8) arithmetic

/// Galois Field GF(2^8) arithmetic over the primitive polynomial
/// x^8 + x^4 + x^3 + x^2 + 1 (0x11D).
///
/// All operations use precomputed log/antilog tables for O(1) multiply.
public enum GF256 {
    static let prim = 0x11D

    /// Antilog (power) table: `gfExp[i] = α^i`; indices 0–511 with period 255.
    public static let gfExp: [UInt8] = {
        var t = [UInt8](repeating: 0, count: 512)
        var x = 1
        for i in 0..<255 {
            t[i] = UInt8(x)
            x <<= 1
            if x & 0x100 != 0 { x ^= prim }
        }
        for i in 255..<512 { t[i] = t[i - 255] }
        return t
    }()

    /// Log table: `gfLog[x] = i` such that `α^i = x` (index 0 is irrelevant).
    public static let gfLog: [Int] = {
        var t = [Int](repeating: 0, count: 256)
        var x = 1
        for i in 0..<255 {
            t[x] = i
            x <<= 1
            if x & 0x100 != 0 { x ^= prim }
        }
        return t
    }()

    @inline(__always)
    public static func mul(_ a: UInt8, _ b: UInt8) -> UInt8 {
        if a == 0 || b == 0 { return 0 }
        return gfExp[gfLog[Int(a)] + gfLog[Int(b)]]
    }

    @inline(__always)
    public static func div(_ a: UInt8, _ b: UInt8) -> UInt8 {
        if a == 0 { return 0 }
        return gfExp[(gfLog[Int(a)] - gfLog[Int(b)] + 255) % 255]
    }

    public static func pow(_ base: UInt8, _ exp: Int) -> UInt8 {
        if base == 0 { return exp == 0 ? 1 : 0 }
        return gfExp[(gfLog[Int(base)] * exp) % 255]
    }

    public static func inv(_ x: UInt8) -> UInt8 {
        return gfExp[255 - gfLog[Int(x)]]
    }

    // MARK: – Polynomial helpers
    // Convention: polynomials are stored **highest-degree first** (index 0 = leading coeff).

    static func polyMul(_ p: [UInt8], _ q: [UInt8]) -> [UInt8] {
        var r = [UInt8](repeating: 0, count: p.count + q.count - 1)
        for (i, a) in p.enumerated() {
            if a == 0 { continue }
            for (j, b) in q.enumerated() {
                r[i + j] ^= mul(a, b)
            }
        }
        return r
    }

    // Element-wise XOR with zero-padding to match lengths.
    static func polyAdd(_ p: [UInt8], _ q: [UInt8]) -> [UInt8] {
        let n = max(p.count, q.count)
        var r = [UInt8](repeating: 0, count: n)
        for (i, v) in p.enumerated() { r[n - p.count + i] ^= v }
        for (i, v) in q.enumerated() { r[n - q.count + i] ^= v }
        return r
    }

    static func polyScale(_ p: [UInt8], _ s: UInt8) -> [UInt8] {
        return p.map { mul($0, s) }
    }

    // Horner evaluation (polynomial p with index 0 = highest degree).
    static func polyEval(_ p: [UInt8], _ x: UInt8) -> UInt8 {
        var y: UInt8 = p[0]
        for i in 1..<p.count {
            y = mul(y, x) ^ p[i]
        }
        return y
    }
}

// MARK: – Reed-Solomon codec

/// Systematic Reed-Solomon RS(255, 255-nsym) codec over GF(2^8).
///
/// Capable of correcting up to `nsym / 2` symbol errors per block.
/// The generator polynomial starts at root α^0 (fcr = 0).
public struct ReedSolomon {
    /// Number of ECC (parity) symbols appended per block. Must be even.
    public let nsym: Int

    /// Generator polynomial g(x) = ∏_{i=0}^{nsym-1} (x − α^i),
    /// stored highest-degree first.
    private let gen: [UInt8]

    public init(nsym: Int = 32) {
        precondition(nsym >= 2 && nsym <= 254 && nsym % 2 == 0)
        self.nsym = nsym
        var g: [UInt8] = [1]
        for i in 0..<nsym {
            g = GF256.polyMul(g, [1, GF256.gfExp[i]])
        }
        gen = g
    }

    // MARK: – Encoding

    /// Systematic encoding: returns `msg` followed by `nsym` parity bytes.
    public func encode(_ msg: [UInt8]) -> [UInt8] {
        // Polynomial long division of msg(x)·x^nsym by gen(x).
        // gen[0] = 1 so no leading-coefficient normalisation is needed.
        var work = msg + [UInt8](repeating: 0, count: nsym)
        for i in 0..<msg.count {
            let coef = work[i]
            if coef != 0 {
                for j in 1..<gen.count {
                    work[i + j] ^= GF256.mul(gen[j], coef)
                }
            }
        }
        return Array(msg) + Array(work[msg.count...])
    }

    // MARK: – Syndromes

    private func calcSyndromes(_ msg: [UInt8]) -> [UInt8] {
        return (0..<nsym).map { GF256.polyEval(msg, GF256.gfExp[$0]) }
    }

    // MARK: – Berlekamp-Massey error locator

    /// Returns the error locator polynomial Λ(x) using the Berlekamp-Massey
    /// algorithm.  Stored highest-degree first; constant term is always 1.
    private func findErrorLocator(synd: [UInt8]) -> [UInt8] {
        var errLoc: [UInt8] = [1]
        var oldLoc: [UInt8] = [1]

        for i in 0..<nsym {
            // Discrepancy: δ = s_i + Σ_{j=1}^{L} σ_j · s_{i-j}
            // errLoc[errLoc.count - 1 - j] = σ_j (stored HDF)
            var delta = synd[i]
            for j in 1..<errLoc.count {
                delta ^= GF256.mul(errLoc[errLoc.count - 1 - j], synd[i - j])
            }

            oldLoc = oldLoc + [0]   // multiply old polynomial by x

            if delta != 0 {
                if oldLoc.count > errLoc.count {
                    let newLoc = GF256.polyScale(oldLoc, delta)
                    oldLoc = GF256.polyScale(errLoc, GF256.inv(delta))
                    errLoc = newLoc
                }
                errLoc = GF256.polyAdd(errLoc, GF256.polyScale(oldLoc, delta))
            }
        }

        // Strip leading zeros.
        var start = 0
        while start < errLoc.count - 1 && errLoc[start] == 0 { start += 1 }
        return Array(errLoc[start...])
    }

    // MARK: – Chien search

    /// Returns error positions (0-indexed from start of codeword) for each
    /// root found, or `nil` if the root count doesn't match the polynomial degree.
    ///
    /// For a codeword of length n stored HDF, an error at array position p
    /// corresponds to the monomial of degree (n−1−p).  The error locator root
    /// for that error is α^{−(n−1−p)}, so we scan all 255 field elements and
    /// map root α^i back to array position via  p = (i + n − 1) mod 255.
    private func findErrors(_ errLoc: [UInt8], n: Int) -> [Int]? {
        let numErrors = errLoc.count - 1
        var errPos = [Int]()
        for i in 0..<255 {
            if GF256.polyEval(errLoc, GF256.gfExp[i]) == 0 {
                let p = (i + n - 1) % 255
                if p < n { errPos.append(p) }
            }
        }
        guard errPos.count == numErrors else { return nil }
        return errPos
    }

    // MARK: – Forney algorithm (error magnitude)

    /// Applies the Forney algorithm to correct errors in `msg` at `errPos`.
    private func correctErrata(_ msg: inout [UInt8], synd: [UInt8], errPos: [Int]) {
        // Convert message positions to coefficient positions.
        let coefPos = errPos.map { msg.count - 1 - $0 }

        // Error locator from positions: eLocator = ∏_k (x − α^{coefPos[k]})
        var eLocator: [UInt8] = [1]
        for cp in coefPos {
            eLocator = GF256.polyMul(eLocator, GF256.polyAdd([1], [GF256.gfExp[cp], 0]))
        }

        // Error evaluator Ω(x) = S(x) · Λ(x)  mod  x^nsym.
        // S(x) = s_0 + s_1·x + … stored in HDF as [s_{nsym-1}, …, s_0].
        let syndPoly = Array(synd.reversed())
        var omega = GF256.polyMul(syndPoly, eLocator)
        // Keep only the nsym lowest-degree terms (the suffix in HDF).
        if omega.count > nsym {
            omega = Array(omega.suffix(nsym))
        }

        // For each error position compute the magnitude using Forney.
        let X = coefPos.map { GF256.gfExp[$0] }  // X_k = α^{coefPos[k]}
        for (k, xk) in X.enumerated() {
            let xkInv = GF256.inv(xk)  // X_k^{−1}

            // Λ'(X_k^{−1}) via product formula: ∏_{j≠k} (1 − X_k^{−1} · X_j)
            var errLocPrime: UInt8 = 1
            for (j, xj) in X.enumerated() where j != k {
                errLocPrime = GF256.mul(errLocPrime, 1 ^ GF256.mul(xkInv, xj))
            }
            if errLocPrime == 0 { continue }

            // Ω(X_k^{−1})
            let omegaVal = GF256.polyEval(omega, xkInv)

            // e_k = Ω(X_k^{−1}) / Λ'(X_k^{−1})
            // Λ'(X_k^{−1}) = X_k · errLocPrime  →  X_k cancels with the
            // numerator factor in the standard Forney formula, leaving:
            let magnitude = GF256.div(omegaVal, errLocPrime)
            msg[errPos[k]] ^= magnitude
        }
    }

    // MARK: – Decode

    /// Decode a received codeword (message + parity bytes).
    /// Returns the corrected message bytes, or `nil` if the block is uncorrectable.
    public func decode(_ received: [UInt8]) -> [UInt8]? {
        var msg = received
        let synd = calcSyndromes(msg)

        if synd.allSatisfy({ $0 == 0 }) {
            return Array(msg.prefix(msg.count - nsym))
        }

        let errLoc = findErrorLocator(synd: synd)
        let numErrors = errLoc.count - 1
        guard numErrors * 2 <= nsym else { return nil }
        guard let errPos = findErrors(errLoc, n: msg.count) else { return nil }

        correctErrata(&msg, synd: synd, errPos: errPos)

        // Verify that all syndromes are now zero.
        guard calcSyndromes(msg).allSatisfy({ $0 == 0 }) else { return nil }

        return Array(msg.prefix(msg.count - nsym))
    }
}
