const { jestConfig } = require('@salesforce/sfdx-lwc-jest/config');
const setupFilesAfterEnv = jestConfig.setupFilesAfterEnv || [];
//setupFilesAfterEnv.push('<rootDir>/jest-sa11y-setup.js');
module.exports = {
    ...jestConfig,
    modulePaths: ['<rootDir>'],
    moduleNameMapper: {
        '^c/(.+)$': [
            '<rootDir>/fs-core/main/default/lwc/$1/$1',
            '<rootDir>/fs-core/main/os/default/lwc/$1/$1'
        ],
        //'^@salesforce/apex$': '<rootDir>/fs-core/main/test/jest-mocks/apex',
        //'^@salesforce/schema$': '<rootDir>/fs-app/test/jest-mocks/schema',
        '^lightning/navigation$':
            '<rootDir>/fs-core/test/jest-mocks/lightning/navigation',
        '^lightning/platformShowToastEvent$':
            '<rootDir>/fs-core/test/jest-mocks/lightning/platformShowToastEvent',
        '^lightning/uiRecordApi$':
            '<rootDir>/fs-core/test/jest-mocks/lightning/uiRecordApi',
        '^lightning/messageService$':
            '<rootDir>/fs-core/test/jest-mocks/lightning/messageService',
        "^lightning/empApi$":
            "<rootDir>/fs-core/test/jest-mocks/lightning/empApi"
    },
    //setupFiles: ['jest-canvas-mock'],
    setupFilesAfterEnv,
    testTimeout: 10000
};