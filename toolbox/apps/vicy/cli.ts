import { isValidKey, isValidText, encrypt, decrypt } from "./vigenere";

// @ts-ignore
if (typeof window === "undefined") {
  const [mode, key, keyConfirm, textOrCipher] = process.argv.slice(2);
  if (!isValidKey(key, keyConfirm)) {
    console.log("Error: Invalid key");
    process.exit(1);
  }
  if (!isValidText(textOrCipher)) {
    console.log("Error: Invalid text or cipher");
    process.exit(1);
  }

  if (mode === "e") {
    console.log(encrypt(textOrCipher, key));
  } else if (mode === "d") {
    console.log(decrypt(textOrCipher, key));
  }
}
