public with sharing class InvoicePDFController {
    public String developerName { get; set; }
    public String generatedDate { get; set; }
    public List<EntryWrapper> entries { get; set; }
    public Decimal grandTotal { get; set; }

    public InvoicePDFController() {
        entries = new List<EntryWrapper>();
        grandTotal = 0;
        generatedDate = String.valueOf(Date.today());

        String timesheetIdsParam = ApexPages.currentPage().getParameters().get('timesheetIds');
        if (String.isBlank(timesheetIdsParam)) return;

        List<Id> timesheetIds = timesheetIdsParam.split(',');

        List<Timesheet_Entry__c> timesheets = [
            SELECT Resource__r.Name, Project__r.Name,   Project__r.Rate__c, Actual_Days_worked__c, Worked_Days__c
            FROM Timesheet_Entry__c
            WHERE Id IN :timesheetIds
        ];

        if (!timesheets.isEmpty()) {
            developerName = timesheets[0].Resource__r.Name;
        }

        for (Timesheet_Entry__c ts : timesheets) {
            Decimal rate = ts.Project__r.Rate__c;
            Decimal hours = ts.Actual_Days_worked__c;
            Decimal total = rate * hours;

            entries.add(new EntryWrapper(
                ts.Project__r.Name,
                ts.Worked_Days__c,
                hours,
                rate,
                total
            ));

            grandTotal += total;
        }
    }

    public class EntryWrapper {
        public String projectName { get; set; }
    public Decimal workedDays { get; set; }
    public Decimal workedHours { get; set; }
    public Decimal rate { get; set; }
    public Decimal total { get; set; }

        public EntryWrapper(String projectName, Decimal workedDays, Decimal workedHours, Decimal rate, Decimal total) {
            this.projectName = projectName;
            this.workedDays = workedDays;
            this.workedHours = workedHours;
            this.rate = rate;
            this.total = total;
        }
    }
}