# EncryptionUtils Explained Simply

## The real-world analogy

Think of encryption like a **locked safe**:
- Your note content is the **valuables** inside
- The encryption key is the **combination code**
- Encrypting = locking the safe
- Decrypting = unlocking the safe

Without the combination, the contents are useless to anyone who finds the safe.

---

## What problem does EncryptionUtils solve?

Notes are stored in a local database on the device. If someone gets access to the device
storage (rooted phone, forensic tool, backup extraction), they can read raw database files.

Without encryption, your note title "Bank PIN is 4821" is stored as plain readable text.
With encryption, the database contains: `a3Fg9kL2mX8pQrZ1...` — meaningless bytes.

---

## The algorithm: AES-256-CBC

**AES** = Advanced Encryption Standard. Used by governments, banks, messaging apps.
**256** = key size in bits. The longer the key, the harder to crack.
**CBC** = Cipher Block Chaining. A mode that chains each encrypted block to the previous
one, so identical words don't produce identical ciphertext.

### Why CBC over other modes?

```
Without chaining (ECB mode) — INSECURE:
"hello hello hello" → [block1][block1][block1]  // identical blocks expose patterns

With CBC:
"hello hello hello" → [block1][block2][block3]  // each block is unique
```

---

## The IV — Initialization Vector

CBC needs a random "starting point" for the chain. That's the IV.

Think of it like a dice roll before a board game — every game (every encryption)
starts from a different random position, so even the same text encrypted twice
produces completely different output.

```
Encrypt "hello" with key K, IV=AAA → "xK9mP2..."
Encrypt "hello" with key K, IV=ZZZ → "qR7nL5..."  ← different output, same input!
```

The IV is **not secret** — it's stored alongside the ciphertext. Its only job is
to ensure randomness, not secrecy.

---

## Walking through EncryptionUtils line by line

```dart
class EncryptionUtils {
  static String encrypt(String plainText, String base64Key) {
```

Both methods are `static` — you call them as `EncryptionUtils.encrypt(...)` without
needing to create an instance. `base64Key` is the 32-byte AES key encoded as a
Base64 string (safe to store/transmit as text).

---

### encrypt()

```dart
// Step 1: decode the Base64 key back to raw bytes
final keyBytes = base64Decode(base64Key);
final key = Key(Uint8List.fromList(keyBytes));
```

The key is stored as Base64 text (easier to store in secure storage).
Here we decode it back to raw bytes that the AES algorithm needs.

```dart
// Step 2: generate a fresh random IV for this encryption
final iv = IV.fromSecureRandom(EncryptionConstants.ivLength); // 16 bytes
```

`fromSecureRandom` uses the OS cryptographic random generator — not `math.Random()`.
This is important: `math.Random` is predictable; OS crypto random is not.

```dart
// Step 3: create the AES encrypter and encrypt
final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
final encrypted = encrypter.encrypt(plainText, iv: iv);
```

This runs the actual AES-CBC algorithm and returns the ciphertext bytes.

```dart
// Step 4: prefix the IV to the ciphertext and Base64 encode the whole thing
final combined = iv.bytes + encrypted.bytes;
return base64Encode(combined);
```

We store IV + ciphertext together as one Base64 string.
Why? Because decrypt() needs the IV to reverse the operation.
The IV is not secret — storing it alongside the ciphertext is standard practice.

**Final output looks like:** `"AAECAwQFBgcICQoLDA0OD2O9kL3p8..."`
(first 16 decoded bytes = IV, rest = encrypted note)

---

### decrypt()

```dart
// Step 1: decode the stored Base64 string back to raw bytes
final combined = base64Decode(cipherText);
```

We get the raw bytes of [IV + ciphertext] that we stored.

```dart
// Step 2: split out the IV (first 16 bytes) from the ciphertext (rest)
final ivBytes  = Uint8List.fromList(combined.sublist(0, 16));
final encBytes = Uint8List.fromList(combined.sublist(16));
```

`sublist(0, 16)` = bytes 0–15 = the IV we prepended during encrypt.
`sublist(16)` = bytes 16 onwards = the actual encrypted content.

```dart
// Step 3: reconstruct the same key and IV objects
final key = Key(Uint8List.fromList(base64Decode(base64Key)));
final iv  = IV(ivBytes);
```

Same key (retrieved from Keystore), same IV (recovered from stored data).

```dart
// Step 4: decrypt
final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
return encrypter.decrypt(Encrypted(encBytes), iv: iv);
```

AES-CBC with the same key and IV reverses the operation exactly.
Output is your original plain text note content.

---

## Full flow with concrete example

```
User types note:  "My WiFi password is Sunshine99"

ENCRYPT (on save):
  key     = "abc...32bytes...xyz"  (from Android Keystore / iOS Secure Enclave)
  iv      = [random 16 bytes]       e.g. 0x3F 0xA1 0x22 ... (generated fresh)
  cipher  = AES_CBC(key, iv, "My WiFi password is Sunshine99")
  stored  = base64(iv + cipher)
           = "P6Ei9kL2mX8pQrZnT3Fg..." ← this goes into the DB

DECRYPT (on open):
  raw     = base64decode("P6Ei9kL2mX8pQrZnT3Fg...")
  iv      = raw[0..15]   = [0x3F 0xA1 0x22 ...]
  cipher  = raw[16..]    = [remaining bytes]
  plain   = AES_CBC_DECRYPT(key, iv, cipher)
           = "My WiFi password is Sunshine99"  ← shown to user
```

---

## What if someone steals the database file?

```
DB file contents (what attacker sees):
  id:               "a1b2c3d4"
  title:            "WiFi"                        ← title is also encrypted in our app
  encrypted_content: "P6Ei9kL2mX8pQrZnT3Fg..."  ← meaningless without key

Key is stored in:
  Android → Android Keystore (hardware-backed, never leaves the chip)
  iOS     → Secure Enclave (hardware security module)

Attacker has: database file ✓
Attacker has: encryption key ✗ (locked in hardware)

Result: attacker cannot decrypt. The data is useless.
```

---

## What EncryptionUtils does NOT do

| Concern | Handled by |
|---|---|
| Where the key comes from | `KeystoreChannel` (MethodChannel to native) |
| Storing the key safely | Android Keystore / iOS Secure Enclave |
| Who is allowed to decrypt | `AuthRepository` (biometric gate) |
| Encrypting the note title | Calling code in repository — EncryptionUtils just provides the tool |

`EncryptionUtils` is a pure stateless utility. It does one thing: given text + key,
produce ciphertext; given ciphertext + key, produce text. Everything else is
someone else's responsibility.
