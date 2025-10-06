trigger FormulaShareBatchApexErrorEventTrigger on BatchApexErrorEvent (after insert) {
    FormulaShareBatchApexErrorEventHandler.handle(Trigger.New);
}

