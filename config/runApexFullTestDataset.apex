// Generate test data
FSSampleAppDataGenerationService.run(730);

// Schedule batch job once per day
System.schedule('FormulaShare Job', '0 0 22 * * ? *', new FormulaShareProcessSchedulable());
//System.schedule('FormulaShare Job 1', '0 0 * * * ?', new FormulaShareProcessSchedulable());
//System.schedule('FormulaShare Job 2', '0 15 * * * ?', new FormulaShareProcessSchedulable());
//System.schedule('FormulaShare Job 3', '0 30 * * * ?', new FormulaShareProcessSchedulable());
//System.schedule('FormulaShare Job 4', '0 45 * * * ?', new FormulaShareProcessSchedulable());