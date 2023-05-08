/**
 * lint-staged config
 * @ref https://www.npmjs.com/package/lint-staged
 * @desc generated at 6/19/2022, 7:04:22 PM by streakingman-cli@1.8.2
 */

module.exports = {
    '*.{[tj]s,[tj]sx,[cm]js}': ['eslint --fix'],
    '*.json': ['prettier --write'],
    '*.{css,scss}': ['stylelint --fix'],
};
