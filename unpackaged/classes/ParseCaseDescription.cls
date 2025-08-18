public class ParseCaseDescription {

    // Input wrapper class for Flow
    public class InputWrapper {
        @InvocableVariable(label = 'Case Description')
        public String description;
    }

    // Output wrapper class for Flow
    public class OutputWrapper {
        @InvocableVariable(label = 'Parsed Name')
        public String name;

        @InvocableVariable(label = 'Parsed Email')
        public String email;

        @InvocableVariable(label = 'Parsed Phone')
        public String phone;

        @InvocableVariable(label = 'Parsed Product')
        public String product;

        @InvocableVariable(label = 'Parsed Model Number')
        public String modelNumber;

        @InvocableVariable(label = 'Parsed Issue Type')
        public String issueType;
    }

    // Invocable method to be called from Flow
    @InvocableMethod(label = 'Parse Case Description')
    public static List<OutputWrapper> parseFields(List<InputWrapper> requestList) {
        List<OutputWrapper> results = new List<OutputWrapper>();

        for (InputWrapper request : requestList) {
            String body = (request.description != null) ? request.description.toLowerCase() : '';
            OutputWrapper result = new OutputWrapper();

            result.name         = extractField(body, 'name');
            result.email        = extractField(body, 'email');
            result.phone        = extractField(body, 'phone');
            result.product      = extractField(body, 'product name');
            result.modelNumber  = extractField(body, 'model number');
            result.issueType    = extractField(body, 'issue type');

            results.add(result);
        }

        return results;
    }

    // Helper method to extract value from description using regex
    private static String extractField(String text, String label) {
        String patternStr = label + '\\s*:\\s*(.+)';
        Pattern pattern = Pattern.compile(patternStr);
        Matcher matcher = pattern.matcher(text);

        if (matcher.find()) {
            String value = matcher.group(1);
            if (value != null) {
                // Stop at newline if exists, and trim
                Integer newlineIndex = value.indexOf('\n');
                if (newlineIndex != -1) {
                    value = value.substring(0, newlineIndex);
                }
                return value.trim();
            }
        }
        return null;
    }
}