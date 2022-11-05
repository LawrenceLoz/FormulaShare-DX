public with sharing class FormulaShareMockProvRulesSelector implements System.StubProvider {

    private String prefix = FormulaShareTestUtils.getNamespacePrefix();

    public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, 
        Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames, 
        List<Object> listOfArgs) {

        if(stubbedMethodName == 'getRulesSharingObject' || stubbedMethodName == 'getAllRules') {
            return FormulaShareRuleFactory.getStandardRulesSharingBatchLogs();
        }


        else if(stubbedMethodName == 'getStandardAndAncestorRulesSharingObject') {
            system.debug('getStandardAndAncestorRulesSharingObject stub');

            String sharedObjectName = (String) listOfArgs[0];
            List<FormulaShareRule> rules = new List<FormulaShareRule>();

            if(sharedObjectName.contains('FormulaShare_Log__c')) {
                rules = FormulaShareRuleFactory.getStandardRulesSharingBatchLogs();
            }
//            else if(sharedObjectName.contains('FormulaShare_Record_Log__c')) {
//                rules.add(FormulaShareRuleFactoryRelated.getAncestorUserRule());
//            }

            return rules;
        }


        else if(stubbedMethodName == 'selectObjectsWithRules') {
            Map<String, String> objNames = new Map<String, String>();
            objNames.put(prefix + 'FormulaShare_Log__c', 'FormulaShare Batch Log');
            objNames.put(prefix + 'FormulaShare_Record_Log__c', 'FormulaShare Record Log');
            return objNames;
        }

        else return null;
    }

}
