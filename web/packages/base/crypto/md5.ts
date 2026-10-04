/**
 * @file Incremental MD5 (RFC 1321), producing base64 encoded digests.
 *
 * MD5 is only used to compute the `Content-MD5` checksums that S3 uses to
 * verify the integrity of uploaded objects (and parts). It is not used for any
 * security purpose.
 *
 * [Note: MD5 off the main thread]
 *
 * Uploads compute the MD5 of every (encrypted) object and multipart part they
 * send. That is a lot of bytes, so this implementation avoids per byte work in
 * the hot loop, and it is exposed via the {@link CryptoWorker} so that the
 * hashing for concurrent uploads is spread over their respective workers
 * instead of all contending for the main thread.
 */

/* Per round shift amounts. */
const S = new Int32Array([
    7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 5, 9, 14, 20, 5,
    9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11,
    16, 23, 4, 11, 16, 23, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10,
    15, 21,
]);

/* Per round additive constants, floor(abs(sin(i + 1)) * 2^32). */
const K = Int32Array.from(
    { length: 64 },
    (_, i) => Math.floor(Math.abs(Math.sin(i + 1)) * 2 ** 32) | 0,
);

/* Index of the message word used in each round. */
const G = Int32Array.from({ length: 64 }, (_, j) =>
    j < 16
        ? j
        : j < 32
          ? (5 * j + 1) % 16
          : j < 48
            ? (3 * j + 5) % 16
            : (7 * j) % 16,
);

/**
 * An incremental MD5 hasher.
 *
 * Feed it data in any number of {@link update} calls (of arbitrary sizes), then
 * call {@link digestBase64} once to obtain the digest.
 */
export class Md5 {
    private state = new Int32Array([
        0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476,
    ]);
    /** Scratch space for the 16 little-endian words of the current block. */
    private words = new Int32Array(16);
    /** Bytes that did not yet fill a complete 64 byte block. */
    private tail = new Uint8Array(64);
    private tailLength = 0;
    /** Total number of bytes hashed so far. */
    private length = 0;

    update(data: Uint8Array): this {
        this.length += data.length;
        let offset = 0;

        if (this.tailLength > 0) {
            const n = Math.min(64 - this.tailLength, data.length);
            this.tail.set(data.subarray(0, n), this.tailLength);
            this.tailLength += n;
            offset = n;
            if (this.tailLength < 64) return this;
            this.processBlock(this.tail, 0);
            this.tailLength = 0;
        }

        for (; offset + 64 <= data.length; offset += 64) {
            this.processBlock(data, offset);
        }

        if (offset < data.length) {
            this.tail.set(data.subarray(offset));
            this.tailLength = data.length - offset;
        }
        return this;
    }

    /**
     * Finalize the hash and return the digest as a base64 string.
     *
     * The hasher should not be used after this.
     */
    digestBase64(): string {
        const bitLength = this.length * 8;
        const padding = new Uint8Array(
            this.tailLength < 56 ? 64 - this.tailLength : 128 - this.tailLength,
        );
        padding[0] = 0x80;
        const n = padding.length;
        const lo = bitLength >>> 0;
        const hi = Math.floor(bitLength / 0x100000000) >>> 0;
        for (let i = 0; i < 4; i++) {
            padding[n - 8 + i] = (lo >>> (8 * i)) & 0xff;
            padding[n - 4 + i] = (hi >>> (8 * i)) & 0xff;
        }
        this.update(padding);

        const digest = new Uint8Array(16);
        for (let i = 0; i < 4; i++) {
            const word = this.state[i]!;
            digest[4 * i] = word & 0xff;
            digest[4 * i + 1] = (word >>> 8) & 0xff;
            digest[4 * i + 2] = (word >>> 16) & 0xff;
            digest[4 * i + 3] = (word >>> 24) & 0xff;
        }
        return bytesToBase64(digest);
    }

    private processBlock(bytes: Uint8Array, offset: number) {
        const x = this.words;
        for (let i = 0, o = offset; i < 16; i++, o += 4) {
            x[i] =
                bytes[o]! |
                (bytes[o + 1]! << 8) |
                (bytes[o + 2]! << 16) |
                (bytes[o + 3]! << 24);
        }

        const state = this.state;
        let a = state[0]!;
        let b = state[1]!;
        let c = state[2]!;
        let d = state[3]!;

        // One loop per round (instead of branching on the round within a
        // single loop) keeps the boolean function monomorphic in each loop.
        let j = 0;
        for (; j < 16; j++) {
            const sum = (a + ((b & c) | (~b & d)) + K[j]! + x[G[j]!]!) | 0;
            const s = S[j]!;
            a = d;
            d = c;
            c = b;
            b = (b + ((sum << s) | (sum >>> (32 - s)))) | 0;
        }
        for (; j < 32; j++) {
            const sum = (a + ((d & b) | (~d & c)) + K[j]! + x[G[j]!]!) | 0;
            const s = S[j]!;
            a = d;
            d = c;
            c = b;
            b = (b + ((sum << s) | (sum >>> (32 - s)))) | 0;
        }
        for (; j < 48; j++) {
            const sum = (a + (b ^ c ^ d) + K[j]! + x[G[j]!]!) | 0;
            const s = S[j]!;
            a = d;
            d = c;
            c = b;
            b = (b + ((sum << s) | (sum >>> (32 - s)))) | 0;
        }
        for (; j < 64; j++) {
            const sum = (a + (c ^ (b | ~d)) + K[j]! + x[G[j]!]!) | 0;
            const s = S[j]!;
            a = d;
            d = c;
            c = b;
            b = (b + ((sum << s) | (sum >>> (32 - s)))) | 0;
        }

        state[0] = (state[0]! + a) | 0;
        state[1] = (state[1]! + b) | 0;
        state[2] = (state[2]! + c) | 0;
        state[3] = (state[3]! + d) | 0;
    }
}

const bytesToBase64 = (bytes: Uint8Array) => {
    let binary = "";
    for (const byte of bytes) binary += String.fromCharCode(byte);
    return btoa(binary);
};

/**
 * Return the base64 encoded MD5 digest of the given {@link data}.
 */
export const computeMd5Base64 = (data: Uint8Array): string =>
    new Md5().update(data).digestBase64();
