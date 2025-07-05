// Nhiệm vụ: Chứa các hàm mã hóa và giải mã dùng chung.

// --- Hàm giải mã ---
export async function decrypt(encryptedData: string, key: CryptoKey): Promise<string> {
  try {
    const [ivString, encryptedString] = encryptedData.split('.');
    if (!ivString || !encryptedString) {
      throw new Error("Invalid encrypted data format.");
    }

    const iv = new Uint8Array(ivString.match(/.{1,2}/g)!.map(byte => parseInt(byte, 16)));
    const data = new Uint8Array(encryptedString.match(/.{1,2}/g)!.map(byte => parseInt(byte, 16)));

    const decryptedData = await crypto.subtle.decrypt(
      { name: "AES-GCM", iv: iv },
      key,
      data
    );

    return new TextDecoder().decode(decryptedData);
  } catch (error) {
    console.error("Decryption failed:", error);
    throw new Error("Failed to decrypt data.");
  }
}