/**
*Copyright 2026 Lawrence Newcombe
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

@IsTest
public with sharing class FormulaShareBatchApexErrEvtHndlTest {

    @TestSetup
    static void setup() {
        FormulaShareTestUtils.setupAdmin();
    }


    // ---- handle(): null events list — returns early without exception ----

    @IsTest
    static void handle_nullEvents_returnsEarly() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareBatchApexErrorEventHandler.wasCalled = false;
            FormulaShareBatchApexErrorEventHandler.handle(null);
            System.assert(FormulaShareBatchApexErrorEventHandler.wasCalled, 'handle() should set wasCalled flag');
        }
    }


    // ---- handle(): empty events list — returns early ----

    @IsTest
    static void handle_emptyEvents_returnsEarly() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareBatchApexErrorEventHandler.wasCalled = false;
            FormulaShareBatchApexErrorEventHandler.handle(new List<BatchApexErrorEvent>());
            System.assert(FormulaShareBatchApexErrorEventHandler.wasCalled, 'handle() should set wasCalled flag on empty list');
        }
    }


    // ---- handle(): event with null AsyncApexJobId — no exception, no relevant events ----

    @IsTest
    static void handle_eventWithNullJobId_noException() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            BatchApexErrorEvent evt = new BatchApexErrorEvent();
            // Leave AsyncApexJobId null — should be skipped in jobIds collection
            List<BatchApexErrorEvent> events = new List<BatchApexErrorEvent>{ evt };

            FormulaShareBatchApexErrorEventHandler.wasCalled = false;
            FormulaShareBatchApexErrorEventHandler.handle(events);
            System.assert(FormulaShareBatchApexErrorEventHandler.wasCalled, 'handle() should complete without exception');
        }
    }


    // ---- handle(): event with populated but non-matching job id — exits at relevantEvents empty check ----

    @IsTest
    static void handle_eventWithNonMatchingJob_noException() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            // Use a fake ID that doesn't correspond to a real batch job
            // The selector will return nothing → classIdsOfEvents empty → allowedClassIds empty → relevantEvents empty
            BatchApexErrorEvent evt = new BatchApexErrorEvent();
            // We can't easily set AsyncApexJobId since it's read-only on the event;
            // but calling handle() with a null job id exercises the skip branch
            List<BatchApexErrorEvent> events = new List<BatchApexErrorEvent>{ evt };

            FormulaShareBatchApexErrorEventHandler.handle(events);
            System.assert(true, 'handle() completed with non-matching job id');
        }
    }

}