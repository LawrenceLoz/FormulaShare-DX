const { jestConfig } = require('@salesforce/sfdx-lwc-jest/config');
const setupFilesAfterEnv = jestConfig.setupFilesAfterEnv || [];
//setupFilesAfterEnv.push('<rootDir>/jest-sa11y-setup.js');
module.exports = {
    ...jestConfig,
    moduleNameMapper: {
        //'^@salesforce/apex$': '<rootDir>/fs-core/main/test/jest-mocks/apex',
        //'^@salesforce/schema$': '<rootDir>/fs-app/test/jest-mocks/schema',
        '^lightning/navigation$':
            '<rootDir>/fs-core/test/jest-mocks/lightning/navigation',
        '^lightning/platformShowToastEvent$':
            '<rootDir>/fs-core/test/jest-mocks/lightning/platformShowToastEvent',
        '^lightning/uiRecordApi$':
            '<rootDir>/fs-core/test/jest-mocks/lightning/uiRecordApi',
        '^lightning/messageService$':
            '<rootDir>/fs-core/test/jest-mocks/lightning/messageService'
    },
    //setupFiles: ['jest-canvas-mock'],
    setupFilesAfterEnv,
    testTimeout: 10000
};