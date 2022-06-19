/**
 * eslint config
 * @ref http://eslint.cn/
 * @desc generated at 6/19/2022, 7:03:44 PM by streakingman-cli@1.8.2
 */

module.exports = {
    root: true,
    parser: '@typescript-eslint/parser',
    parserOptions: {
        sourceType: 'module',
        ecmaVersion: 11,
    },
    env: {
        es6: true,
        node: true,
    },
    plugins: ['eslint-plugin-prettier', '@typescript-eslint'],
    extends: [
        'eslint:recommended',

        'plugin:@typescript-eslint/recommended',
        'plugin:prettier/recommended',
    ],
    rules: {
        'prettier/prettier': 'error',
    },
};
