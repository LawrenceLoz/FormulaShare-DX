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

public inherited sharing class FormulaShareEntityDefinitionSelector {

    // fflib selector pattern isn't used because it fails due to the lack of a 
    // CreatedDate on EntityDefinition. The basic query below is sufficient 
    // since EntityDefinition does not support FLS and sharing

    public static FormulaShareEntityDefinitionSelector construct() {
        return new FormulaShareEntityDefinitionSelector();
    }

    public List<EntityDefinition> getEntitiesForIds(List<String> objectEntityIds) {
        List<EntityDefinition> entities = [
            SELECT QualifiedApiName     // Object API name with namespace prefix
            , DurableId, Label, PluralLabel
            , InternalSharingModel, ExternalSharingModel      // Private, Read, ReadWrite, ReadWriteTransfer, FullAccess (campaigns), ControlledByParent (MD children)
            , DetailUrl
            FROM EntityDefinition
            WHERE DurableId IN :objectEntityIds
            WITH SECURITY_ENFORCED];

        return entities;
    }

    public List<EntityDefinition> getEntitiesForApiNames(List<String> objectApiNames) {
        List<EntityDefinition> entities = [
            SELECT QualifiedApiName, DurableId
                , IsApexTriggerable, IsCustomizable, IsLayoutable
            FROM EntityDefinition
            WHERE QualifiedApiName IN :objectApiNames
            WITH SECURITY_ENFORCED];

        return entities;
    }

    public List<EntityDefinition> getAllShareable() {
        List<EntityDefinition> entities = [
            SELECT QualifiedApiName, DurableId, Label, PluralLabel, InternalSharingModel
            , ExternalSharingModel, DetailUrl 
            FROM EntityDefinition
            WHERE IsCustomSetting = FALSE
            AND IsApexTriggerable = TRUE
            AND IsCustomizable = TRUE
            WITH SECURITY_ENFORCED
            ORDER BY Label];
        
        return entities;
    }

    public List<EntityDefinition> getAllCustomMetadataTypes() {
        List<EntityDefinition> entities = [SELECT QualifiedApiName, DurableId, Label, PluralLabel, DetailUrl 
        FROM EntityDefinition
                          WHERE QualifiedApiName LIKE '%__mdt'
                          AND (NOT QualifiedApiName LIKE 'sdfs__FormulaShare%')
        WITH SECURITY_ENFORCED
        ORDER BY Label];
        return entities;
    }

}