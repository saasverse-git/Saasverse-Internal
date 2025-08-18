/********************************************************************************************
* @Name         InvoiceGeneratorController
* @Author       Inderjeet Yadav
* @Date         07/05/2025
* @Description  This Apex class acts as apex controller of the Invoice_Generation vf page which generates invoice templates
and mapp the values of invoice to template.
******************************************************************************************* 
MODIFICATION LOG
* Version          Developer          	   Date               Description
*
*  1.0             Inderjeet Yadav         07/05/2025         Initial Creation                                                      
********************************************************************************************/

public with sharing class InvoiceGeneratorController {
    public Id invoiceId { get; set; }
    public String renderedInvoiceHTML { get; set; }
    
    // Static resource configuration for the signature image
    private static final String SIGNATURE_RESOURCE_PATH = '/resource/1746519642000/ParagBhattSignature';
    
    // Constructor: initializes invoiceId and triggers invoice HTML generation
    public InvoiceGeneratorController(ApexPages.StandardController stdController) {
        this.invoiceId = stdController.getId();
        generateInvoiceHTML();
    }
    
    // Main method to generate the invoice HTML
    public void generateInvoiceHTML() {
        try {
            // 1. Retrieve Invoice and associated Vendor
            Invoice__c invoice = [SELECT Id, Vendor__c FROM Invoice__c WHERE Id = :invoiceId LIMIT 1];
            if (invoice == null || invoice.Vendor__c == null) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Invoice or Vendor not found.'));
                return;
            }
            
            // 2. Fetch the active template for the vendor
            List<Invoice_Template__c> templates = [SELECT Id, Template_Path__c FROM Invoice_Template__c WHERE Vendor__c = :invoice.Vendor__c AND Active__c = true LIMIT 1];
            if (templates.isEmpty() || String.isBlank(templates[0].Template_Path__c)) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No active template found for this vendor.'));
                return;
            }
            String templateName = templates[0].Template_Path__c;
            
            // 3. Load the template content from Static Resource
            List<StaticResource> resources = [SELECT Body FROM StaticResource WHERE Name = :templateName LIMIT 1];
            if (resources.isEmpty()) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Template static resource not found.'));
                return;
            }
            String templateContent = resources[0].Body.toString();
            
            // 4. Extract all placeholders from the template
            Set<String> placeholders = extractPlaceholders(templateContent);
            system.debug('placeholders =='+placeholders);
            // 5. Prepare field maps for Invoice and Vendor objects
            Map<String, Schema.SObjectField> invoiceFieldsMap = Schema.getGlobalDescribe().get('Invoice__c').getDescribe().fields.getMap();
            Map<String, Schema.SObjectField> vendorFieldsMap  = Schema.getGlobalDescribe().get('Vendor__c').getDescribe().fields.getMap();
            
            // 6. Build lists of fields to query based on placeholders
            Set<String> invoiceFields = new Set<String>();
            Set<String> vendorFields  = new Set<String>();
            for (String placeholder : placeholders) {
                String invoiceApi = findMatchingFieldApiName(placeholder, invoiceFieldsMap);
                String vendorApi  = findMatchingFieldApiName(placeholder, vendorFieldsMap);
                if (invoiceApi != null) invoiceFields.add(invoiceApi);
                if (vendorApi != null)  vendorFields.add(vendorApi);
            }
            // Always include Vendor__c for relationship
            invoiceFields.add('Vendor__c');
            
            // 7. Query Invoice record with dynamic fields
            String invoiceSOQL = 'SELECT ' + String.join(new List<String>(invoiceFields), ',') + ' FROM Invoice__c WHERE Id = :invoiceId LIMIT 1';
            Invoice__c invoiceRecord = Database.query(invoiceSOQL);
            
            // 8. Query Vendor record with dynamic fields (if needed)
            Vendor__c vendorRecord;
            if (invoiceRecord != null && invoiceRecord.Vendor__c != null && !vendorFields.isEmpty()) {
                String vendorSOQL = 'SELECT ' + String.join(new List<String>(vendorFields), ',') + ' FROM Vendor__c WHERE Id = :vendorId LIMIT 1';
                vendorRecord = Database.query(vendorSOQL.replace(':vendorId', '\'' + String.valueOf(invoiceRecord.Vendor__c) + '\''));
            }
            
            // 9. Replace all placeholders in the template with actual values
            renderedInvoiceHTML = replacePlaceholders(
                templateContent, placeholders, invoiceRecord, vendorRecord, invoiceFieldsMap, vendorFieldsMap
            );
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error generating invoice: ' + e.getMessage()));
        }
    }
    
    // Extracts all {{Placeholder}} tags from the template content
    private Set<String> extractPlaceholders(String templateContent) {
        Set<String> placeholders = new Set<String>();
        Pattern pattern = Pattern.compile('\\{\\{([A-Za-z0-9_]+)\\}\\}');
        Matcher matcher = pattern.matcher(templateContent);
        while (matcher.find()) {
            placeholders.add(matcher.group(1));
            system.debug('placeholders ==:'+placeholders);
        }
        System.debug('placeholders ==:'+placeholders);
        return placeholders;
    }
    
    // Fuzzy matches a placeholder to a field API name in the provided fields map
    private String findMatchingFieldApiName(String placeholder, Map<String, Schema.SObjectField> fieldsMap) {
        // Try exact match first
    if (fieldsMap.containsKey(placeholder)) {
        return placeholder;
    }

    // Fallback to fuzzy match (less reliable)
    String lowerPlaceholder = placeholder.toLowerCase();
    for (String apiName : fieldsMap.keySet()) {
        if (apiName.replaceAll('_', '').toLowerCase().contains(lowerPlaceholder)) {
            return apiName;
        }
    }
    return null;
    }
    
    // Replaces all placeholders in the template with field values from Invoice/Vendor
    private String replacePlaceholders(
        String templateContent,
        Set<String> placeholders,
        Invoice__c invoice,
        Vendor__c vendor,
        Map<String, Schema.SObjectField> invoiceFieldsMap,
        Map<String, Schema.SObjectField> vendorFieldsMap
    ) {
        String result = templateContent;
        for (String placeholder : placeholders) {
            String value = '';
            // Try Invoice fields first
            if (invoice != null) {
                String apiName = findMatchingFieldApiName(placeholder, invoiceFieldsMap);
                system.debug('apiName ==:'+apiName);
                if (apiName != null) {
                    value = formatValue(invoice.get(apiName), invoiceFieldsMap.get(apiName).getDescribe().getType());
                	system.debug('value ==:'+value);
                }
            }
            // If not found, try Vendor fields
            if (String.isBlank(value) && vendor != null) {
                String apiName = findMatchingFieldApiName(placeholder, vendorFieldsMap);
                if (apiName != null) {
                    value = formatValue(vendor.get(apiName), vendorFieldsMap.get(apiName).getDescribe().getType());
                }
            }
            result = result.replace('{{' + placeholder + '}}', value);
        }
        // Replace the Visualforce static resource reference with the actual resource path
        if (result.contains('{!$Resource.ParagBhattSignature}')) {
            result = result.replace('{!$Resource.ParagBhattSignature}', SIGNATURE_RESOURCE_PATH);
        }
        return result;
    }
    
    // Formats field values for display in the template
    private String formatValue(Object val, Schema.DisplayType dtype) {
        if (val == null) return '';
        if (dtype == Schema.DisplayType.Date) {
            return ((Date)val).format();
        } else if (dtype == Schema.DisplayType.Currency || dtype == Schema.DisplayType.Double || dtype == Schema.DisplayType.Percent) {
            return String.valueOf(((Decimal)val).setScale(2));
        } else if (dtype == Schema.DisplayType.Integer) {
            return String.valueOf(val);
        } else {
            String stringVal = String.valueOf(val);
            system.debug('String.valueOf(val) =='+stringVal);
            if (dtype == Schema.DisplayType.TextArea) {
                stringVal = stringVal.replaceAll('\n', '<br/>');
            }
            return stringVal;
        }
    }
    
}