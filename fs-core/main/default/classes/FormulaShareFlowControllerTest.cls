@IsTest
private class FormulaShareFlowControllerTest {
    
    @IsTest
    static void testGetFlowVersionId() {
        // Create test data
        String testFlowApiName = 'Apply_FormulaShare_Rules_Synchronous';
        
        Test.startTest();
        String flowId = FormulaShareFlowController.getFlowVersionId(testFlowApiName);
        Test.stopTest();
        
        if(FormulaSharePackageVerifier.getLicenseAllowance().Name != 'OS') {
            System.assertNotEquals(null, flowId, 'FormulaShare template should be found');
        }
        else {
            System.assertEquals(null, flowId, 'FormulaShare template should not be found for OS version');
        }
    }
    

    @IsTest
    static void testGetFlowVersionIdWithInvalidName() {
        // Test with non-existent flow name
        String invalidFlowName = 'NonExistentFlow';
        
        Test.startTest();
        String flowId = FormulaShareFlowController.getFlowVersionId(invalidFlowName);
        Test.stopTest();
        
        System.assertEquals(null, flowId, 'Flow ID should be null for non-existent flow');
    }
    
    @IsTest
    static void testGetFlowVersionIdWithNullName() {
        Test.startTest();
        String flowId = FormulaShareFlowController.getFlowVersionId(null);
        Test.stopTest();
        
        System.assertEquals(null, flowId, 'Flow ID should be null when input is null');
    }
} 