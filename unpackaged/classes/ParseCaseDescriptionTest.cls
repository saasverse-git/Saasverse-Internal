@IsTest
private class ParseCaseDescriptionTest {
    
    @IsTest
    static void testParseFields() {
        // Sample case description matching the expected pattern
        String description = 
            'Name: John Doe\n' +
            'Email: john.doe@example.com\n' +
            'Phone: +1-555-1234\n' +
            'Product Name: WidgetX\n' +
            'Model Number: WX-100\n' +
            'Issue Type: Broken screen\n' +
            'Other notes: Customer called in about issue.';

        // Create InputWrapper and add to list
        ParseCaseDescription.InputWrapper input = new ParseCaseDescription.InputWrapper();
        input.description = description;

        List<ParseCaseDescription.InputWrapper> inputList = new List<ParseCaseDescription.InputWrapper>{ input };

        Test.startTest();
        List<ParseCaseDescription.OutputWrapper> results = ParseCaseDescription.parseFields(inputList);
        Test.stopTest();

        // Validate result
        System.assertEquals(1, results.size(), 'Should return one result');
        ParseCaseDescription.OutputWrapper result = results[0];

        //System.assertEquals('John Doe', result.name, 'Name parsed incorrectly');
        System.assertEquals('john.doe@example.com', result.email, 'Email parsed incorrectly');
        System.assertEquals('+1-555-1234', result.phone, 'Phone parsed incorrectly');
        //System.assertEquals('WidgetX', result.product, 'Product parsed incorrectly');
        //System.assertEquals('WX-100', result.modelNumber, 'Model Number parsed incorrectly');
        //System.assertEquals('Broken screen', result.issueType, 'Issue Type parsed incorrectly');
    }

    @IsTest
    static void testParseFields_withNullDescription() {
        // Input with null description to test null handling
        ParseCaseDescription.InputWrapper input = new ParseCaseDescription.InputWrapper();
        input.description = null;

        List<ParseCaseDescription.InputWrapper> inputList = new List<ParseCaseDescription.InputWrapper>{ input };

        List<ParseCaseDescription.OutputWrapper> results = ParseCaseDescription.parseFields(inputList);

        System.assertEquals(1, results.size(), 'Should return one result even if description is null');
        ParseCaseDescription.OutputWrapper result = results[0];

        System.assertEquals(null, result.name, 'Name should be null');
        System.assertEquals(null, result.email, 'Email should be null');
        System.assertEquals(null, result.phone, 'Phone should be null');
        System.assertEquals(null, result.product, 'Product should be null');
        System.assertEquals(null, result.modelNumber, 'Model Number should be null');
        System.assertEquals(null, result.issueType, 'Issue Type should be null');
    }
}