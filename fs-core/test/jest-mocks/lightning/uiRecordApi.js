/*
 * Copyright (c) 2018, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: MIT
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/MIT
 */
export const getRecord = jest.fn();
export const getRecordCreateDefaults = jest.fn();
export const updateRecord = jest.fn().mockResolvedValue({});
export const createRecord = jest.fn().mockResolvedValue({});
export const deleteRecord = jest.fn().mockResolvedValue();
export const generateRecordInputForCreate = jest.fn();
export const generateRecordInputForUpdate = jest.fn();
export const createRecordInputFilteredByEditedFields = jest.fn();
export const getRecordInput = jest.fn();
export const refresh = jest.fn().mockResolvedValue();
export const getRecordUi = jest.fn();
export const getFieldValue = jest.fn((data, fieldReference) => {
    if (data) {
        const fields = fieldReference.fieldApiName.split('.');
        if (data.result) {
            const fieldData = fields.reduce((o, i) => o[i], data.result.fields);
            if (fieldData && fieldData.value) {
                return fieldData.value;
            }
        } else {
            const fieldData = fields.reduce((o, i) => o[i], data.fields);
            if (fieldData && fieldData.value) {
                return fieldData.value;
            }
        }
        return null;
    }
});
export const getFieldDisplayValue = jest.fn();
