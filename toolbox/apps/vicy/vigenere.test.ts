import { isValidKey, isValidText } from "./vigenere";

describe("isValidKey", () => {
  it("returns true for a valid key", () => {
    expect(isValidKey("a valid key", "a valid key")).toBe(true);
  });

  it("returns false if key is less than 2 chars", () => {
    expect(isValidKey("k", "k")).toBe(false);
  });

  it("returns false for non matching keys", () => {
    expect(isValidKey("a valid key", "wrong confirmation")).toBe(false);
  });

  it("returns false if key contains not supported chars", () => {
    expect(isValidKey("an invalid k€y", "an invalid k€y")).toBe(false);
  });
});

describe("isValidText", () => {
  it("returns true for a valid text", () => {
    expect(isValidText("a valid text")).toBe(true);
  });

  it("returns false if text contains not supported chars", () => {
    expect(isValidText("an invalid t€xt")).toBe(false);
  });
});
