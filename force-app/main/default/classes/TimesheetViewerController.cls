/**
* @File Name : TimesheetViewerController.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : April 7, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | April 7, 2025 |   | Initial Version
**/

public class TimesheetViewerController {
	@AuraEnabled
    public static List<Timesheet_Entry__c> getTimesheets() {
        return [
            SELECT Id, Resource__r.Name, Project__r.Name, Start_Date__c, End_Date__c, Project__r.Final_Settlement_Payment_Received__c,
                   Worked_Days__c, Actual_Days_worked__c, Billable__c, Approved__c,
                   Submitted_On__c, Status__c, Captured_Hours__c, Approved_Days__c
            FROM Timesheet_Entry__c WHERE Project__r.Status__c IN ('In Progress' , 'On Hold')
            ORDER BY Submitted_On__c DESC
        ];
    }

    @AuraEnabled
    public static void updateWorkedDays(List<Timesheet_Entry__c> timesheets) {
    update timesheets;
    }

    //For  creat Invoice
    @AuraEnabled
public static Id createInvoice(Id timesheetId) {
    try {
        List<Invoice__c> invoicesToUpdate = new List<Invoice__c>();

        // Get all field API names for Timesheet_Entry__c
        Map<String, Schema.SObjectField> tsFieldsMap = Schema.getGlobalDescribe().get('Timesheet_Entry__c').getDescribe().fields.getMap();
        List<String> tsFieldNames = new List<String>(tsFieldsMap.keySet());
        
        
        // Build dynamic SOQL to fetch all fields for the timesheet
        String soql = 'SELECT ' + String.join(tsFieldNames, ',') + ', Project__r.Name FROM Timesheet_Entry__c WHERE Id = :timesheetId ORDER BY CreatedDate DESC LIMIT 1';
        System.debug('SOQL == :' + soql);
        Timesheet_Entry__c ts = Database.query(soql);

        // Find existing invoice for this project
        List<Invoice__c> existInvoices = [SELECT Id FROM Invoice__c WHERE Project__c = :ts.Project__c LIMIT 1];

        Invoice__c inv;
        Boolean isUpdate = false;

        // Initialize the invoice record
        if (!existInvoices.isEmpty()) {
            inv = existInvoices[0];
            isUpdate = true;
        } else {
            inv = new Invoice__c();
            inv.Project__c = ts.Project__c;
            inv.Name = 'Invoice for - ' + ts.Project__r.Name;
            inv.Invoice_Number__c = 'INV-' + String.valueOf(Datetime.now().getTime());
            inv.Quantity__c = ts.Captured_Hours__c;
        }

        // Get Invoice fields
        Map<String, Schema.SObjectField> invoiceFields = Schema.getGlobalDescribe().get('Invoice__c').getDescribe().fields.getMap();

        // Dynamic field mapping
        for (String invoiceField : invoiceFields.keySet()) {
            if (tsFieldsMap.containsKey(invoiceField)) {
                Schema.DescribeFieldResult fieldDescribe = invoiceFields.get(invoiceField).getDescribe();
                if (fieldDescribe.isUpdateable() && !fieldDescribe.isCalculated()) {
                    try {
                        inv.put(invoiceField, ts.get(invoiceField));
                    } catch (Exception ex) {
                        System.debug('Skipping field due to error: ' + invoiceField + ' -> ' + ex.getMessage());
                    }
                }
            }
        }

        // Static/default fields (set or override as needed)
        inv.Invoice_Number__c = 'INV-' + String.valueOf(Datetime.now().getTime());
        inv.Quantity__c = ts.Captured_Hours__c;

        invoicesToUpdate.add(inv);

        // Save the record
        if (isUpdate) {
            Database.SaveResult[] srList = Database.update(invoicesToUpdate, false);
            for (Database.SaveResult sr : srList) {
                if (!sr.isSuccess()) {
                    System.debug('Update failed: ' + sr.getErrors()[0].getMessage());
                }
            }
        } else {
            Database.SaveResult[] srList = Database.insert(invoicesToUpdate, false);
            for (Database.SaveResult sr : srList) {
                if (!sr.isSuccess()) {
                    System.debug('Insert failed: ' + sr.getErrors()[0].getMessage());
                }
            }
        }

        return inv.Id;

    } catch (Exception ex) {
        System.debug('Error in createInvoice: ' + ex.getMessage());
        throw new AuraHandledException('Failed to create or update invoice: ' + ex.getMessage());
    }
}

    
    // METHOD  — Get Timesheets with Incomplete Payment Projects
    @AuraEnabled(cacheable=true)
    public static List<Timesheet_Entry__c> getTimesheetsForIncompletePayment() {
        return [SELECT Id, Resource__r.Name, Project__c, Project__r.Name, Project__r.Final_Settlement_Payment_Received__c, 
                       Start_Date__c, End_Date__c, Worked_Days__c, Actual_Days_worked__c, 
                       Billable__c, Approved__c, Submitted_On__c, Status__c, Captured_Hours__c, Approved_Days__c
                FROM Timesheet_Entry__c
                WHERE Project__r.Final_Settlement_Payment_Received__c = False ORDER BY Submitted_On__c DESC];
    }

    //  METHOD  — Get All Timesheet Entries WITH Project Payment Status
    // @AuraEnabled(cacheable=true)
    // public static List<Timesheet_Entry__c> getTimesheetsForIncompletePayment(Boolean toggleValue) {
        
    //     if(isToggleOn){
    //         return [SELECT Id, Resource__r.Name, Project__c, Project__r.Name, Project__r.Final_Settlement_Payment_Received__c, 
    //                    Start_Date__c, End_Date__c, Worked_Days__c, Actual_Days_worked__c, 
    //                    Billable__c, Approved__c, Submitted_On__c, Status__c, Captured_Hours__c, Approved_Days__c
    //                    FROM Timesheet_Entry__c
    //                    WHERE Project__r.Final_Settlement_Payment_Received__c = False ORDER BY Submitted_On__c DESC];  
            
    //     }
    //     else{
    //         return [SELECT Id, Resource__r.Name, Project__c, Project__r.Name, Project__r.Final_Settlement_Payment_Received__c,
    //                     Start_Date__c, End_Date__c, Worked_Days__c, Actual_Days_worked__c, 
    //                     Billable__c, Approved__c, Submitted_On__c, Status__c, Captured_Hours__c, Approved_Days__c
    //                     FROM Timesheet_Entry__c WHERE Status__c IN ('In Progress' , 'On Hold')
    //                     ORDER BY Submitted_On__c DESC];
    //     }
            
    // }
}