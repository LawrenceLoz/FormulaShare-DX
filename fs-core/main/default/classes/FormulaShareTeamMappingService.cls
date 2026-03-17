/**
*Copyright 2024-2026 Lawrence Newcombe
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

/**
 * Virtual base class providing team mapping data access for the core LWC layer.
 * The core implementation returns empty/null defaults; the main project extends
 * this class with real data retrieval logic through FormulaShareTeamMappingServiceMain.
 * 
 * Controllers in core obtain an instance via FormulaShareInjectionService.getTeamMappingService(),
 * ensuring no direct compile-time dependency on the main project.
 */
public virtual inherited sharing class FormulaShareTeamMappingService {

    /**
     * Returns active team mapping options for the combobox.
     * Core default: empty list (no team mappings available without main project).
     */
    public virtual List<TeamMappingOption> getActiveTeamMappings() {
        return new List<TeamMappingOption>();
    }

    /**
     * Returns fields eligible for the "Specified in Field" dropdown for a given
     * team mapping and controlling/shared object.
     * Core default: empty list.
     */
    public virtual List<TeamFieldOption> getTeamFieldOptions(
            String objectApiName,
            String teamObjectApiName,
            String sharedObjectApiName) {
        return new List<TeamFieldOption>();
    }

    /**
     * Returns the label of the team object for a given team object API name.
     * Core default: empty string.
     */
    public virtual String getTeamObjectLabel(String teamObjectApiName) {
        return '';
    }

    // ---- Shared data types used by both core controller and main implementation ---- //

    public class TeamMappingOption {
        @AuraEnabled public String developerName;
        @AuraEnabled public String label;
        @AuraEnabled public String teamObjectApiName;
        @AuraEnabled public String teamNameFieldApiName;
    }

    public class TeamFieldOption {
        @AuraEnabled public String fieldApiName;
        @AuraEnabled public String fieldLabel;
        @AuraEnabled public String fieldCategory;
        @AuraEnabled public Boolean isIdType;
    }
}
