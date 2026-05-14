const alphabet =
  " !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~§ÄÖÜßäöü";
const modValue = alphabet.length;

// real modulo, not only the remainder
// it fixes it for negative numbers, so that -1 mod 26 is not -1 but 25 (it begins again from the end)
//TODO add tests
const mod = (n: number, modulo: number) => {
  var remainder = n % modulo;
  return Math.floor(remainder >= 0 ? remainder : remainder + modulo);

  //shorter, but not so nice to read
  //return ((n % modulo) + modulo) % modulo;
};

const LINE_BREAK = String.fromCharCode(10);
const isLineBreak = (char: string) => {
  return char.charCodeAt(0) === 10;
};

export const encrypt = (text: string, key: string) => {
  if (!isValidKey(key, key)) throw new Error("Invalid key");
  if (!isValidText(text)) throw new Error("Invalid text");

  return shiftTextByKey(text, key, "encrypt");
};

export const decrypt = (cipher: string, key: string) => {
  if (!isValidKey(key, key)) throw new Error("Invalid key");
  if (!isValidText(cipher)) throw new Error("Invalid cipher");

  return shiftTextByKey(cipher, key, "decrypt");
};

const shiftTextByKey = (
  text: string,
  key: string,
  mode: "encrypt" | "decrypt"
) =>
  text
    .split("")
    .map((char, index) => {
      if (isLineBreak(char)) {
        return LINE_BREAK;
      }

      const textIndex = alphabet.indexOf(char);

      const keyChar = key[mod(index, key.length)];
      const keyIndex = alphabet.indexOf(keyChar);

      const shiftedIndex = mod(
        textIndex + keyIndex * (mode === "decrypt" ? -1 : 1),
        modValue
      );

      return alphabet[shiftedIndex];
    })
    .join("");

const isValidChar = (char: string) => alphabet.indexOf(char) !== -1;

export const isValidKey = (key: string, keyConfirm: string) => {
  if (key.length < 2 || key !== keyConfirm) {
    return false;
  }

  for (const c of key) {
    if (!isValidChar(c)) {
      return false;
    }
  }

  return true;
};

export const isValidText = (text: string) => {
  if (text.length < 1) {
    return false;
  }

  for (const c of text) {
    if (!isValidChar(c) && !isLineBreak(c)) {
      return false;
    }
  }

  return true;
};
