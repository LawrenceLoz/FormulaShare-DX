// Generate test data
FSSampleAppDataGenerationService.run();

// Schedule batch jobs
System.schedule('FormulaShare Job 1', '0 0 * * * ?', new FormulaShareProcessSchedulable());
System.schedule('FormulaShare Job 1', '0 15 * * * ?', new FormulaShareProcessSchedulable());
System.schedule('FormulaShare Job 1', '0 30 * * * ?', new FormulaShareProcessSchedulable());
System.schedule('FormulaShare Job 1', '0 45 * * * ?', new FormulaShareProcessSchedulable());