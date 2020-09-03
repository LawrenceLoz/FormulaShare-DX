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

public inherited sharing class FormulaShareReportsService {

    static String reportPrefix = '/lightning/r/Report/';

    public static String getRecordErrorsAllReportUrl(String ruleName) {
        FormulaShare_Settings__mdt settings = FormulaShareSettingsSelector.construct().selectActiveSettings();
        String reportName = settings.All_Record_Errors_Report_Name__c;
        Id reportId = getReportIdForName(reportName);
        String ruleNameUrlFormat = EncodingUtil.urlEncode(ruleName, 'UTF-8');
        String reportUrl = reportPrefix + reportId + '/view' + '?fv1=' + ruleNameUrlFormat;
        return reportUrl;
    }
    
    public static String getRecordErrorsSinceLastBatchReportUrl(String ruleName, Id lastBatchId, Long batchFinishEpoch) {
        FormulaShare_Settings__mdt settings = FormulaShareSettingsSelector.construct().selectActiveSettings();
        String reportName = settings.Rec_Errors_Since_Last_Batch_Report_Name__c;
        Id reportId = getReportIdForName(reportName);
        String ruleNameUrlFormat = EncodingUtil.urlEncode(ruleName, 'UTF-8');
        String reportUrl = reportPrefix + reportId + '/view' + '?fv1=' + ruleNameUrlFormat + '&fv2=' + lastBatchId + '&fv3=' + batchFinishEpoch;
        return reportUrl;
    }

    public static String getBatchErrorReportUrl(String objectApiName) {
        FormulaShare_Settings__mdt settings = FormulaShareSettingsSelector.construct().selectActiveSettings();
        String reportName = settings.Batch_Errors_Report_Name__c;
        Id reportId = getReportIdForName(reportName);
        String objectApiNameUrlFormat = EncodingUtil.urlEncode(objectApiName, 'UTF-8');
        String reportUrl = reportPrefix + reportId + '/view' + '?fv0=' + objectApiNameUrlFormat;
        return reportUrl;
    }

    public static Id getReportIdForName(String reportName) {
        if(reportIdsMap == null) {
            setReportIdsMap();
        }
        return reportIdsMap.get(reportName);
    }

    static Map<String,Id> reportIdsMap;
    private static void setReportIdsMap() {
        reportIdsMap = new Map<String,Id>();

        // Get developer names for all reports specified in settings
        List<String> reportNames = new List<String>();
        FormulaShare_Settings__mdt settings = FormulaShareSettingsSelector.construct().selectActiveSettings();
        reportNames.add(settings.All_Record_Logs_Report_Name__c);
        reportNames.add(settings.Record_Logs_Since_Last_Batch_Report_Name__c);
        reportNames.add(settings.All_Record_Errors_Report_Name__c);
        reportNames.add(settings.Rec_Errors_Since_Last_Batch_Report_Name__c);
        reportNames.add(settings.Batch_Errors_Report_Name__c);

        // Query for all reports and populate cached map of ids
        List<Report> fsReports = [SELECT Id, DeveloperName FROM Report WHERE DeveloperName IN :reportNames];
        for(Report r : fsReports) {
            reportIdsMap.put(r.DeveloperName, r.Id);
        }
    }

}