/**
*Copyright 2018 Lawrence Newcombe
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

public class FormulaShareMockUtil {

    private FormulaShareMockUtil(){}

    public static FormulaShareMockProvider getInstance() {
        return new FormulaShareMockProvider();
    }
    public static FormulaShareMockProvRulesSelector getMockProvRulesSelectorInstance() {
        return new FormulaShareMockProvRulesSelector();
    }
    
    public static Object createMock(Type typeToMock) {
        return Test.createStub(typeToMock, FormulaShareMockUtil.getInstance());
    }

    // Used to set a standard mock for rules provider (can be used instead of related version when we want to test standard rules only)
    public static Object createMockProvRulesSelectorMock(Type typeToMock) {
        return Test.createStub(typeToMock, FormulaShareMockUtil.getMockProvRulesSelectorInstance());
    }

}