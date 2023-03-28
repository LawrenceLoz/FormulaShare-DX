@IsTest
public with sharing class FormulaShareReportsServiceTest {

    static String reportPrefix = FormulaShareReportsService.reportPrefix;
    static String ruleName = 'Testrule';
    static String objectName = 'FormulaShare_Log__c';

    @TestSetup
    public static void setup() {
        FormulaShareTestUtils.setupAdmin();
    }
    

    @IsTest
    public static void testGetRecordErrorsAllReportUrl() {

        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareReportsService rs = FormulaShareReportsService.construct();

            String reportUrl = rs.getRecordErrorsAllReportUrl(ruleName);

            String expectedUrl = reportPrefix + 'null' + '/view' + '?fv1=' + ruleName;
            System.assertEquals(expectedUrl, reportUrl, 'Report URL mismatch with expected string)');
        }
    }

    @IsTest
    public static void testGetRecordErrorsSinceLastBatchReportUrl() {

        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareReportsService rs = FormulaShareReportsService.construct();
            Id lastBatchId = UserInfo.getUserId();  // Any ID is fine
            Long batchFinishEpoch = 123456789;

            String reportUrl = rs.getRecordErrorsSinceLastBatchReportUrl(ruleName, lastBatchId, batchFinishEpoch);

            String expectedUrl = reportPrefix + 'null' + '/view' + '?fv1=' + ruleName  + '&fv2=' + lastBatchId + '&fv3=' + batchFinishEpoch;
            System.assertEquals(expectedUrl, reportUrl, 'Report URL mismatch with expected string)');
        }
    }

    @IsTest
    public static void testGetBatchErrorReportUrl() {

        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareReportsService rs = FormulaShareReportsService.construct();

            String reportUrl = rs.getBatchErrorReportUrl(objectName);

            String expectedUrl = reportPrefix + 'null' + '/view' + '?fv0=' + objectName;
            System.assertEquals(expectedUrl, reportUrl, 'Report URL mismatch with expected string)');
        }
    }

}
