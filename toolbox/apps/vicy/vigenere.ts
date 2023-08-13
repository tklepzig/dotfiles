const alphabet =
  " !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~§ÄÖÜßäöü";
const modValue = alphabet.length;

// to support negative numbers
const modX = (n: number, modulo: number) => {
  return ((n % modulo) + modulo) % modulo;
};

const LINE_BREAK = String.fromCharCode(10);
const isLineBreak = (char: string) => {
  return char.charCodeAt(0) === 10;
};

export const encrypt = (text: string, key: string) => {
  let result = "";

  for (let i = 0; i < text.length; i++) {
    const char = text[i];

    if (isLineBreak(char)) {
      result += LINE_BREAK;
      continue;
    }

    let newIndex = getCharCode(char) + getShiftForIndex(key, i);

    newIndex %= modValue;

    result += getStringFromCharCode(newIndex);
  }

  return result;
};

export const decrypt = (text: string, key: string) => {
  let result = "";

  for (let i = 0; i < text.length; i++) {
    const char = text[i];

    if (isLineBreak(char)) {
      result += LINE_BREAK;
      continue;
    }

    let newIndex = getCharCode(char) - getShiftForIndex(key, i);

    newIndex = modX(newIndex, modValue);

    result += getStringFromCharCode(newIndex);
  }

  return result;
};

const getShiftForIndex = (key: string, index: number) => {
  const char = key[index % key.length];
  const shift = alphabet.indexOf(char);

  return shift;
};

const getCharCode = (char: string) => {
  return alphabet.indexOf(char);
};

const getStringFromCharCode = (code: number) => {
  return alphabet[code];
};

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
