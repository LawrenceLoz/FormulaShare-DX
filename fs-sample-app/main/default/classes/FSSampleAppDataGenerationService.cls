/**
*Copyright 2019 Lawrence Newcombe
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

public with sharing class FSSampleAppDataGenerationService {

    @TestVisible
    private static List<String> userProfiles = new List<String>{
        'Analytics Cloud Integration User',
        'Analytics Cloud Security User'
    };

    public static void run(Integer noDonations) {
        List<Country__c> countries = new List<Country__c>();
        Map<String,Id> countriesMap = new Map<String,Id>();
        List<Theme__c> themes = new List<Theme__c>();
        Map<String,Id> themesMap = new Map<String,Id>();
        List<Programme__c> progs = new List<Programme__c>();
        List<Donation__c> donations = new List<Donation__c>();
        List<Programme_Support_Officer__c> progSuppOfficers = new List<Programme_Support_Officer__c>();
        List<Donation_Payment__c> payments = new List<Donation_Payment__c>();

        List<User> users = [SELECT Id, Username FROM User WHERE Profile.Name IN :userProfiles];

        // insert countries
        for(FS_Sample_App_Country__mdt countryMeta : [SELECT DeveloperName, Finance_Manager_Role__c FROM FS_Sample_App_Country__mdt]) {
            Country__c c = new Country__c();
            c.Name = countryMeta.DeveloperName;
            c.Name_of_Country_CMDT_Record__c = countryMeta.DeveloperName;
            c.Finance_Manager_Role__c = countryMeta.Finance_Manager_Role__c;
            countries.add(c);
        }
        insert countries;
        for(Country__c c : countries) {
            countriesMap.put(c.Name,c.Id);
        }

        // insert themes
        for(FS_Sample_App_Theme__mdt themeMeta : [SELECT DeveloperName, Thematic_Area_Coordination_Public_Group__c FROM FS_Sample_App_Theme__mdt]) {
            Theme__c t = new Theme__c();
            t.Name = themeMeta.DeveloperName;
            t.Thematic_Area_Coordination_Public_Group__c = themeMeta.Thematic_Area_Coordination_Public_Group__c;
            themes.add(t);
        }
        insert themes;
        for(Theme__c t : themes) {
            themesMap.put(t.Name,t.Id);
        }

        // insert programmes
        for(FS_Sample_App_Programme__mdt progMeta : [SELECT DeveloperName, Country__r.DeveloperName, Theme__r.DeveloperName, Description__c FROM FS_Sample_App_Programme__mdt]) {
            Programme__c p = new Programme__c();
            p.Description__c = progMeta.DeveloperName;
            p.Country__c = countriesMap.get(progMeta.Country__r.DeveloperName);
            p.Theme__c = themesMap.get(progMeta.Theme__r.DeveloperName);
            p.Major_Donor_Relationship_Manager__c = users[0].Id;
            progs.add(p);
        }
        insert progs;

        // insert donations
        Integer count = 0;
        while(count < noDonations) {
            for(FS_Sample_App_First_Name__mdt firstNameMeta : [SELECT DeveloperName FROM FS_Sample_App_First_Name__mdt]) {
                for(FS_Sample_App_Surname__mdt surnameMeta : [SELECT DeveloperName FROM FS_Sample_App_Surname__mdt]) {
                    Donation__c d = new Donation__c();
    
                    Integer randomAmount = Math.Round(Math.Random() * 1000);
                    Integer randomIndex = Math.Round(Math.Random() * (progs.size() - 1));  
                    system.debug('this random index: '+randomIndex);
    
                    d.Donor_Name__c = firstNameMeta.DeveloperName + ' ' + surnameMeta.DeveloperName;
                    d.Amount__c = randomAmount;
                    if(randomAmount < 300) {
                        d.External_Sharing_Role__c = 'Programme_Manager';
                    }
                    else if(randomAmount < 600) {
                        d.External_Sharing_Role__c = 'Business_Development_Manager';
                    }
                    d.Programme_to_Support__c = progs[randomIndex].Id;
                    donations.add(d);
                    count++;
                }
            }
        }
        insert donations;

        // Insert random number of payments between 1 and 3
        for(Donation__c don : donations) {
            Integer noPayments = Math.Round(Math.Random() * 3);
            for(Integer i=0; i < noPayments; i++) {
                List<String> paymentMethods = new List<String>{
                    'Credit Card', 'Bank Transfer', 'Cash'
                };
                Integer randIndex = Math.Round(Math.Random() * 2);
                
                Donation_Payment__c payment = new Donation_Payment__c();
                payment.Donation__c = don.Id;
                payment.Amount__c = don.Amount__c;
                payment.Payment_Method__c = paymentMethods[randIndex];
                payments.add(payment);
            }
        }
        insert payments;

        // Insert two programme support officers for each programme
        for(Programme__c prog : progs) {
            for(User u : users) {
                Programme_Support_Officer__c pso = new Programme_Support_Officer__c();
                pso.Programme__c = prog.Id;
                pso.User__c = u.Id;
                progSuppOfficers.add(pso);
            }
        }
        insert progSuppOfficers;        
    }
}