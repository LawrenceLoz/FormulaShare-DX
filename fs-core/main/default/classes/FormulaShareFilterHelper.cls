/**
*Copyright 2024 Lawrence Newcombe
*
*Permission is hereby granted, free of charge, to any person obtaining a copy
*of this software and associated documentation files (the "Software"), to deal
*in the Software without restriction, including without limitation the rights
*to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
*of the Software, and to permit persons to whom the Software is furnished to do
*so, subject to the following conditions:
*
*The above copyright notice and this permission notice shall be included in all
*copies or substantial portions of the Software.
*
*THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
*IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
*FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
*COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
*IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
*CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
**/

// Utility class for parsing, serialising and evaluating sharing condition filters.
// Filters are stored in CMDT as a pipe-delimited string: FieldApiName|Operator[|Value]
// Multiple conditions on the same object are separated by double-pipe: Field1|Op1|Val1||Field2|Op2|Val2
// Supported operators: Equals, Not Equals, Is Blank, Is Not Blank
public inherited sharing class FormulaShareFilterHelper {

    public static final String OPERATOR_EQUALS = 'Equals';
    public static final String OPERATOR_NOT_EQUALS = 'Not Equals';
    public static final String OPERATOR_IS_BLANK = 'Is Blank';
    public static final String OPERATOR_IS_NOT_BLANK = 'Is Not Blank';
    private static final String SEPARATOR = '|';
    private static final String CONDITION_SEPARATOR = '||';

    // Inner class representing a parsed filter condition
    public class FilterDetail {
        @AuraEnabled public String fieldApiName;
        @AuraEnabled public String operator;
        @AuraEnabled public String value;

        public Boolean hasValue() {
            return operator == OPERATOR_EQUALS || operator == OPERATOR_NOT_EQUALS;
        }
    }

    // Container for all conditions on an object level
    public class ObjectFilterDetail {
        @AuraEnabled public List<FilterDetail> fieldConditions;

        public ObjectFilterDetail() {
            this.fieldConditions = new List<FilterDetail>();
        }
    }


    // Parse a contracted filter string (FieldApiName|Operator[|Value]) into a FilterDetail
    // Returns null if the string is blank or malformed
    public static FilterDetail parseFilter(String contracted) {
        if(String.isBlank(contracted)) {
            return null;
        }
        // For multi-condition strings, parse only the first condition for backwards compatibility
        String firstCondition = contracted;
        Integer doublePipeIdx = contracted.indexOf(CONDITION_SEPARATOR);
        if(doublePipeIdx >= 0) {
            firstCondition = contracted.substring(0, doublePipeIdx);
        }
        return parseSingleFilter(firstCondition);
    }

    // Parse a single condition string into a FilterDetail
    private static FilterDetail parseSingleFilter(String conditionStr) {
        if(String.isBlank(conditionStr)) {
            return null;
        }
        // Split with a limit of 3 so any pipe characters in value are preserved
        List<String> parts = conditionStr.split('\\|', 3);
        if(parts.size() < 2) {
            System.debug('FormulaShareFilterHelper.parseFilter: malformed filter string: ' + conditionStr);
            return null;
        }
        FilterDetail fd = new FilterDetail();
        fd.fieldApiName = parts[0].trim();
        fd.operator     = parts[1].trim();
        if(parts.size() == 3) {
            fd.value = parts[2];
        }
        return fd;
    }


    // Parse a full filter string into an ObjectFilterDetail supporting multiple conditions
    public static ObjectFilterDetail parseObjectFilter(String contracted) {
        ObjectFilterDetail ofd = new ObjectFilterDetail();
        if(String.isBlank(contracted)) {
            return ofd;
        }

        // Parse multiple field-based conditions separated by ||
        // Must use indexOf loop because split('\\|\\|') would also match single pipes
        List<String> conditionStrings = splitConditions(contracted);
        for(String condStr : conditionStrings) {
            FilterDetail fd = parseSingleFilter(condStr.trim());
            if(fd != null) {
                ofd.fieldConditions.add(fd);
            }
        }
        return ofd;
    }

    // Split a contracted string by double-pipe || while preserving single pipes within conditions
    private static List<String> splitConditions(String contracted) {
        List<String> conditions = new List<String>();
        Integer startIdx = 0;
        Integer len = contracted.length();
        while(startIdx < len) {
            Integer doublePipeIdx = contracted.indexOf(CONDITION_SEPARATOR, startIdx);
            if(doublePipeIdx < 0) {
                conditions.add(contracted.substring(startIdx));
                break;
            }
            conditions.add(contracted.substring(startIdx, doublePipeIdx));
            startIdx = doublePipeIdx + CONDITION_SEPARATOR.length();
        }
        return conditions;
    }


    // Serialize a filter into contracted pipe-delimited string form
    public static String toContracted(String fieldApiName, String operator, String value) {
        if(String.isBlank(fieldApiName) || String.isBlank(operator)) {
            return null;
        }
        String contracted = fieldApiName + SEPARATOR + operator;
        Boolean needsValue = (operator == OPERATOR_EQUALS || operator == OPERATOR_NOT_EQUALS);
        if(needsValue && value != null) {
            contracted += SEPARATOR + value;
        }
        return contracted;
    }

    // Serialize an ObjectFilterDetail back to the contracted CMDT string
    public static String objectFilterToContracted(ObjectFilterDetail ofd) {
        if(ofd == null) {
            return null;
        }
        // Field-based conditions
        List<String> parts = new List<String>();
        for(FilterDetail fd : ofd.fieldConditions) {
            String part = toContracted(fd.fieldApiName, fd.operator, fd.value);
            if(part != null) {
                parts.add(part);
            }
        }
        return parts.isEmpty() ? null : String.join(parts, CONDITION_SEPARATOR);
    }


    // Build a SOQL WHERE fragment for a field directly on the queried object
    // e.g. "Active__c = TRUE" or "Status__c != 'Active'" or "AccountId = NULL"
    public static String toSoqlCondition(FilterDetail filter) {
        if(filter == null || String.isBlank(filter.fieldApiName) || String.isBlank(filter.operator)) {
            return null;
        }
        return buildConditionFragment(filter.fieldApiName, filter);
    }


    // Build a SOQL WHERE fragment for a field reached via a relationship path
    // e.g. toSoqlConditionWithPath("Account__r.Region__r", fd) → "Account__r.Region__r.Status__c = 'Active'"
    public static String toSoqlConditionWithPath(String relationshipPath, FilterDetail filter) {
        if(filter == null || String.isBlank(filter.fieldApiName) || String.isBlank(filter.operator)) {
            return null;
        }
        String qualified = String.isBlank(relationshipPath)
            ? filter.fieldApiName
            : relationshipPath + '.' + filter.fieldApiName;
        return buildConditionFragment(qualified, filter);
    }


    // Evaluate a filter condition against an SObject record in memory
    // Returns true if the record satisfies the condition (i.e. should NOT be filtered out)
    // Returns true if filter is null (no condition set)
    public static Boolean evaluateFilter(SObject record, FilterDetail filter) {
        if(filter == null) {
            return true;
        }
        Object fieldValue;
        try {
            fieldValue = record.get(filter.fieldApiName);
        }
        catch(Exception e) {
            // Field not on record - treat as passing (no filter)
            System.debug('FormulaShareFilterHelper.evaluateFilter: field not retrievable: ' + filter.fieldApiName + ' - ' + e.getMessage());
            return true;
        }
        return evaluateCondition(fieldValue, filter);
    }

    // Evaluate all conditions in an ObjectFilterDetail against an SObject record.
    // All field-based conditions must pass (AND logic).
    // Returns true if record satisfies all conditions, or true if no conditions set.
    public static Boolean evaluateObjectFilter(SObject record, ObjectFilterDetail ofd) {
        if(ofd == null || ofd.fieldConditions.isEmpty()) {
            return true;
        }
        for(FilterDetail fd : ofd.fieldConditions) {
            if(!evaluateFilter(record, fd)) {
                return false;
            }
        }
        return true;
    }


    // Evaluate a filter condition against a field reached via a dot-notation relationship path on an SObject
    // e.g. evaluateFilterWithPath(record, "Account__r.Region__r", filter)
    public static Boolean evaluateFilterWithPath(SObject record, String relationshipPath, FilterDetail filter) {
        if(filter == null) {
            return true;
        }
        // If no path, evaluate directly
        if(String.isBlank(relationshipPath)) {
            return evaluateFilter(record, filter);
        }

        // Traverse relationship path segments
        List<String> pathSegments = relationshipPath.split('\\.');
        SObject current = record;
        try {
            for(String segment : pathSegments) {
                if(current == null) return true;  // No record at this level - treat as passing
                current = current.getSObject(segment);
            }
        }
        catch(Exception e) {
            System.debug('FormulaShareFilterHelper.evaluateFilterWithPath: could not traverse path ' + relationshipPath + ' - ' + e.getMessage());
            return true;
        }

        if(current == null) {
            // The related record doesn't exist - treat Is Blank as passing, others as failing
            return filter.operator == OPERATOR_IS_BLANK;
        }

        Object fieldValue;
        try {
            fieldValue = current.get(filter.fieldApiName);
        }
        catch(Exception e) {
            System.debug('FormulaShareFilterHelper.evaluateFilterWithPath: field not retrievable: ' + filter.fieldApiName + ' - ' + e.getMessage());
            return true;
        }
        return evaluateCondition(fieldValue, filter);
    }

    // Evaluate all conditions in an ObjectFilterDetail against a field reached via relationship path.
    // All field-based conditions must pass (AND logic).
    public static Boolean evaluateObjectFilterWithPath(SObject record, String relationshipPath, ObjectFilterDetail ofd) {
        if(ofd == null || ofd.fieldConditions.isEmpty()) {
            return true;
        }
        for(FilterDetail fd : ofd.fieldConditions) {
            if(!evaluateFilterWithPath(record, relationshipPath, fd)) {
                return false;
            }
        }
        return true;
    }


    // ---------------------- Private helpers ---------------------- //

    private static String buildConditionFragment(String qualifiedFieldPath, FilterDetail filter) {
        switch on filter.operator {
            when 'Is Blank' {
                return qualifiedFieldPath + ' = NULL';
            }
            when 'Is Not Blank' {
                return qualifiedFieldPath + ' != NULL';
            }
            when 'Equals' {
                return qualifiedFieldPath + ' = ' + soqlValue(filter.value);
            }
            when 'Not Equals' {
                return qualifiedFieldPath + ' != ' + soqlValue(filter.value);
            }
            when else {
                System.debug('FormulaShareFilterHelper: unknown operator: ' + filter.operator);
                return null;
            }
        }
    }


    // Returns a SOQL-safe literal for the value.
    // Booleans (TRUE/FALSE), numbers, and NULLs are unquoted; everything else is single-quoted.
    private static String soqlValue(String val) {
        if(val == null) return 'NULL';
        String trimmed = val.trim();
        // Boolean literals
        if(trimmed.equalsIgnoreCase('TRUE') || trimmed.equalsIgnoreCase('FALSE')) {
            return trimmed.toUpperCase();
        }
        // Numeric literals (integer or decimal)
        if(trimmed.isNumeric() || Pattern.matches('-?\\d+(\\.\\d+)?', trimmed)) {
            return trimmed;
        }
        // Everything else: single-quote and escape any embedded single quotes
        return '\'' + trimmed.replace('\'', '\\\'') + '\'';
    }


    private static Boolean evaluateCondition(Object fieldValue, FilterDetail filter) {
        System.debug('evaluateCondition filter: '+filter);
        System.debug('evaluateCondition fieldValue: '+fieldValue);
        switch on filter.operator {
            when 'Is Blank' {
                Boolean passesCondition = fieldValue == null || String.valueOf(fieldValue).trim() == '';
                System.debug('evaluateCondition passesCondition: '+passesCondition);
                return passesCondition;
            }
            when 'Is Not Blank' {
                Boolean passesCondition = fieldValue != null && String.valueOf(fieldValue).trim() != '';
                System.debug('evaluateCondition passesCondition: '+passesCondition);
                return passesCondition;
            }
            when 'Equals' {
                if(fieldValue == null) return filter.value == null || filter.value.equalsIgnoreCase('NULL');
                return String.valueOf(fieldValue).equalsIgnoreCase(filter.value);
            }
            when 'Not Equals' {
                if(fieldValue == null) return !(filter.value == null || filter.value.equalsIgnoreCase('NULL'));
                return !String.valueOf(fieldValue).equalsIgnoreCase(filter.value);
            }
            when else {
                System.debug('evaluateCondition: unknown operator in evaluation: ' + filter.operator);
                return true;
            }
        }
    }
}