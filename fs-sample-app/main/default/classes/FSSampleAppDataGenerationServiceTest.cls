@IsTest
public with sharing class FSSampleAppDataGenerationServiceTest {
    
    @IsTest
    public static void testGenerateData() {
        FormulaShareSettingsSelector mockFSSettingsSelector = (FormulaShareSettingsSelector) FormulaShareMockUtil.createMock(FormulaShareSettingsSelector.class);
        FormulaShareSettingsSelector.mock = mockFSSettingsSelector;

        FSSampleAppDataGenerationService.run();

        // Check right number of countries created
        List<FS_Sample_App_Country__mdt> countriesMeta = [SELECT DeveloperName, Finance_Manager_Role__c FROM FS_Sample_App_Country__mdt];
        List<Country__c> countries = [SELECT Name, Finance_Manager_Role__c FROM Country__c];
        System.assertEquals(countriesMeta.size(), countries.size());

        // Check country finance manager set correctly
        Country__c firstCountry = [SELECT Finance_Manager_Role__c FROM Country__c WHERE Name = :countriesMeta[0].DeveloperName][0];
        System.assertEquals(countriesMeta[0].Finance_Manager_Role__c, firstCountry.Finance_Manager_Role__c);

        // Check right number of themes created
        List<FS_Sample_App_Theme__mdt> themesMeta = [SELECT DeveloperName, Thematic_Area_Coordination_Public_Group__c FROM FS_Sample_App_Theme__mdt];
        List<Theme__c> themes = [SELECT Name, Thematic_Area_Coordination_Public_Group__c FROM Theme__c];
        System.assertEquals(themesMeta.size(), themes.size());

        // Check theme public group set correctly
        Theme__c firstTheme = [SELECT Thematic_Area_Coordination_Public_Group__c FROM Theme__c WHERE Name = :themesMeta[0].DeveloperName][0];
        System.assertEquals(themesMeta[0].Thematic_Area_Coordination_Public_Group__c, firstTheme.Thematic_Area_Coordination_Public_Group__c);

        // Check right number of programmes created, and that lookups are not null
        List<FS_Sample_App_Programme__mdt> progsMeta = [SELECT DeveloperName, Country__r.DeveloperName, Theme__r.DeveloperName, Description__c FROM FS_Sample_App_Programme__mdt];
        List<Programme__c> progs = [SELECT Description__c, Country__c, Theme__c FROM Programme__c];
        System.assertEquals(progsMeta.size(), progs.size());
        System.assert(progs[0].Country__c != null);
        System.assert(progs[0].Theme__c != null);

        // Check right number of donations created, and that fields are not null
        List<FS_Sample_App_First_Name__mdt> firstNamesList = [SELECT DeveloperName FROM FS_Sample_App_First_Name__mdt];
        List<FS_Sample_App_Surname__mdt> surnamesList = [SELECT DeveloperName FROM FS_Sample_App_Surname__mdt];
        List<Donation__c> donations = [SELECT Donor_Name__c, Amount__c, Programme_to_Support__c FROM Donation__c];
        System.assertEquals(firstNamesList.size() * surnamesList.size(), donations.size());
        System.assert(donations[0].Amount__c > 0);
        System.assert(donations[0].Programme_to_Support__c != null);
    }
}
