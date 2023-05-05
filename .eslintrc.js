/**
 * eslint config
 * @ref http://eslint.cn/
 * @desc generated at 6/19/2022, 7:03:44 PM by streakingman-cli@1.8.2
 */

module.exports = {
    root: true,
    parser: 'vue-eslint-parser',
    parserOptions: {
        parser: '@typescript-eslint/parser',
        ecmaFeatures: {
            jsx: true,
        },
        sourceType: 'module',
        ecmaVersion: 11,
    },
    globals: {
        __QUEC_ENV__: true,
    },
    env: {
        es6: true,
        node: true,
        browser: true,
    },
    extends: [
        'plugin:vue/vue3-recommended',
        'eslint:recommended',
        'plugin:@typescript-eslint/recommended',
        'prettier',
        'plugin:prettier/recommended',
    ],
    rules: {
        '@typescript-eslint/ban-ts-comment': 0,
        '@typescript-eslint/no-explicit-any': 0,
        '@typescript-eslint/no-non-null-assertion': 0,
        'vue/multi-word-component-names': 0,
    },
};
