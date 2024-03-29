/**
 * stylelint config
 * @ref https://stylelint.io/
 * @desc generated at 6/19/2022, 7:04:03 PM by streakingman-cli@1.8.2
 */

module.exports = {
    extends: [
        'stylelint-config-standard-scss',
        'stylelint-config-prettier-scss',
        'stylelint-config-prettier',
    ],
    rules: {
        'at-rule-no-unknown': null,
        'scss/at-rule-no-unknown': [
            true,
            {
                ignoreAtRules: ['tailwind'],
            },
        ],
        'selector-class-pattern': null,
        'selector-pseudo-class-no-unknown': [
            true,
            {
                ignorePseudoClasses: ['global'],
            },
        ],
        'no-empty-source': null,
    },
};
