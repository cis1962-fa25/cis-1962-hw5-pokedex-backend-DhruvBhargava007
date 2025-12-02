import js from '@eslint/js';
import globals from 'globals';
import { defineConfig } from 'eslint/config';
import eslintPluginUnicorn from 'eslint-plugin-unicorn';
import tseslint from 'typescript-eslint';

export default defineConfig([
    {
        files: ['**/*.{js,mjs,cjs}'],
        plugins: { js, unicorn: eslintPluginUnicorn },
        extends: ['js/recommended'],
        languageOptions: {
            ecmaVersion: "latest",
            sourceType: "module",
            globals: globals.node,
        },
        rules: {
            // eslint base rules
            'no-lonely-if': 'error',
            eqeqeq: 'error',
            'prefer-const': 'error',
            'no-var': 'error',
            'prefer-template': 'error',
            'prefer-arrow-callback': 'error',
            'no-unused-vars': ['warn', { argsIgnorePattern: '^_', varsIgnorePattern: '^_', caughtErrorsIgnorePattern: '^_' }],
            'consistent-return': 'off',

            // unicorn
            'unicorn/consistent-destructuring': 'error',
            'unicorn/error-message': 'error',
            'unicorn/no-abusive-eslint-disable': 'error',
            'unicorn/no-lonely-if': 'error',
            'unicorn/prefer-ternary': 'error',
        },
    },
    {
        files: ['**/*.ts'],
        plugins: { unicorn: eslintPluginUnicorn },
        languageOptions: {
            ecmaVersion: "latest",
            sourceType: "module",
            globals: globals.node,
            parser: tseslint.parser,
        },
        rules: {
            // eslint base rules
            'no-lonely-if': 'error',
            eqeqeq: 'error',
            'prefer-const': 'error',
            'no-var': 'error',
            'prefer-template': 'error',
            'prefer-arrow-callback': 'error',
            'no-unused-vars': ['warn', { argsIgnorePattern: '^_', varsIgnorePattern: '^_', caughtErrorsIgnorePattern: '^_' }],
            'consistent-return': 'off',

            // unicorn
            'unicorn/consistent-destructuring': 'error',
            'unicorn/error-message': 'error',
            'unicorn/no-abusive-eslint-disable': 'error',
            'unicorn/no-lonely-if': 'error',
            'unicorn/prefer-ternary': 'error',
        },
    },
]);
