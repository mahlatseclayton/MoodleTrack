module.exports = {
  env: {
    es6: true,
    node: true,
  },
  parserOptions: {
    ecmaVersion: 2018,
    sourceType: "module",
  },
  extends: [
    "eslint:recommended",
  ],
  rules: {
    "quotes": ["error", "double"],
    "max-len": ["error", { "code": 200 }], // bumped to 200 chars
    "require-jsdoc": "off",
    "indent": ["error", 2],
    "no-unused-vars": ["error", { "argsIgnorePattern": "^_" }], // unused args must start with _
  },
};
