/**
*Copyright 2020 Lawrence Newcombe
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

public inherited sharing class FormulaShareFieldDefinitionSelector {

    // fflib selector pattern isn't used because it fails due to the lack of a 
    // CreatedDate. The basic query below is sufficient 
    // since FieldDefinition does not support FLS and sharing

    public static FormulaShareFieldDefinitionSelector construct() {
        return new FormulaShareFieldDefinitionSelector();
    }

    public List<FieldDefinition> getFieldsForIds(List<String> fieldEntityIds) {
        List<FieldDefinition> fields = [
            SELECT QualifiedApiName, DurableId
            FROM FieldDefinition
            WHERE DurableId IN :fieldEntityIds
            WITH SECURITY_ENFORCED];

        return fields;
    }

}