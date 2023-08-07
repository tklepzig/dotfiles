const maxChar = 126;
const minChar = 32;
const modValue = maxChar + 1 - minChar;

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
  const shift = char.charCodeAt(0) - minChar;

  return shift;
};

const getCharCode = (char: string) => {
  return char.charCodeAt(0) - minChar;
};

const getStringFromCharCode = (code: number) => {
  return String.fromCharCode(code + minChar);
};

export const isValidKey = (key: string, keyConfirm: string) => {
  let isValid = key === keyConfirm && key.length > 1;

  for (const c of key) {
    if (c.charCodeAt(0) < minChar || c.charCodeAt(0) > maxChar) {
      isValid = false;
      return;
    }
  }

  return isValid;
};

export const isValidText = (text: string) => {
  let isValid = text.length > 0;

  for (const c of text) {
    if (
      (c.charCodeAt(0) < minChar && c.charCodeAt(0) !== 10) ||
      c.charCodeAt(0) > maxChar
    ) {
      isValid = false;
      return;
    }
  }

  return isValid;
};
