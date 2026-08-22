# *crypto* library

The library provides common cryptographic functions for mods

TLS and HTTP are not part of this library. They can use crypto for expensive
operations

Keys, signatures, hashes and encrypted data are passed as regular Lua strings.
Strings may contain zero bytes

The current API version is available in `crypto.API_VERSION`

## Hashing

```lua
crypto.sha256(data: str) -> str
crypto.sha384(data: str) -> str
crypto.sha512(data: str) -> str
crypto.md5(data: str) -> str
crypto.hash(hash: str, data: str) -> str
crypto.hmac(hash: str, key: str, data: str) -> str
```

Supported names are `SHA256`, `SHA384`, `SHA512` and `MD5`

MD5 is provided for old formats. SHA256 should be used for new data

Large data can be hashed in parts

```lua
local hash = crypto.hash_new("SHA256")
hash:update(part1)
hash:update(part2)
local result = hash:final()
```

Call `reset` before using the context again

## Signatures

```lua
crypto.ed25519_keypair() -> private_key, public_key
crypto.ed25519_public(private_key: str) -> str
crypto.ed25519_sign(private_key: str, message: str) -> str
crypto.ed25519_verify(public_key: str, message: str, signature: str)
    -> true
    -> false, error

crypto.ecdsa_keypair(curve: str) -> private_key, public_key
crypto.ecdsa_public(curve: str, private_key: str) -> str
crypto.ecdsa_sign(curve: str, private_key: str, message: str, hash: str) -> str
crypto.ecdsa_verify(curve: str, public_key: str, message: str,
                    signature: str, hash: str)
    -> true
    -> false, error

crypto.rsa_pkcs1_verify(hash: str, modulus: str, exponent: str,
                        message: str, signature: str)
    -> true
    -> false, error
crypto.rsa_pss_verify(hash: str, modulus: str, exponent: str,
                      message: str, signature: str, salt_length: int)
    -> true
    -> false, error
```

Ed25519 keys are 32 bytes and signatures are 64 bytes

ECDSA supports `P-256`, `P-384` and `P-521`. Public keys use the uncompressed
SEC1 format and signatures use DER

RSA modulus and exponent use big endian. A `salt_length` of `-1` uses the hash
size. RSA key generation is not provided, Ed25519 is easier for new keys

## Key exchange

```lua
crypto.x25519_keypair() -> private_key, public_key
crypto.x25519_public(private_key: str) -> str
crypto.x25519(private_key: str, peer_public_key: str) -> str
crypto.x25519_shared(private_key: str, peer_public_key: str) -> str

crypto.p256_keypair() -> private_key, public_key
crypto.p256_public(private_key: str) -> str
crypto.p256_shared(private_key: str, peer_public_key: str) -> str
```

`x25519` and `x25519_shared` do the same operation

Pass the shared secret through HKDF before using it as a key

## Encryption

```lua
crypto.aes_gcm_encrypt(key: str, nonce: str, aad: str, plaintext: str) -> str
crypto.aes_gcm_decrypt(key: str, nonce: str, aad: str, ciphertext: str)
    -> plaintext
    -> nil, error

crypto.chacha20_poly1305_encrypt(key: str, nonce: str, aad: str,
                                 plaintext: str) -> str
crypto.chacha20_poly1305_decrypt(key: str, nonce: str, aad: str,
                                 ciphertext: str)
    -> plaintext
    -> nil, error
```

AES GCM accepts 16 and 32 byte keys

ChaCha20 Poly1305 uses a 32 byte key and a 12 byte nonce

A 16 byte tag is appended to ciphertext. Decryption returns nothing when the
tag is invalid

Never use the same nonce twice with the same key

## Other functions

```lua
crypto.random_bytes(length: int) -> str
crypto.constant_time_equal(left: str, right: str) -> bool
crypto.hkdf_extract(hash: str, salt: str, ikm: str) -> str
crypto.hkdf_expand(hash: str, prk: str, info: str, length: int) -> str
crypto.pbkdf2(hash: str, password: str, salt: str,
              iterations: int, length: int) -> str
crypto.scrypt(password: str, salt: str, n: int, r: int, p: int,
              length: int, [optional]max_memory: int=0) -> str
crypto.features() -> table
```

Use scrypt or PBKDF2 with a random salt for passwords. A regular SHA256 hash is
not suitable for password storage

`features` returns the OpenSSL version and available functions

An invalid signature returns `false, "invalid_signature"`

An invalid encryption tag returns `nil, "authentication_failed"`

Invalid arguments raise a regular Lua error
