public class recallProcessWrapper {
    @AuraEnabled public String First_Name { get; set; }
    @AuraEnabled public String Last_Name { get; set; }
    @AuraEnabled public String SuppliedEmail { get; set; }
    @AuraEnabled public String ContactPhone { get; set; }
    @AuraEnabled public String SuppliedPhone { get; set; }
    @AuraEnabled public String Address { get; set; }
    @AuraEnabled public String Support_Address { get; set; }
    @AuraEnabled public String City { get; set; }
    @AuraEnabled public String State { get; set; }
    @AuraEnabled public String ZipCode { get; set; }
    @AuraEnabled public String Model_Number { get; set; }
    @AuraEnabled public date Purchase_Date { get; set; }
    @AuraEnabled public String Batch_Number { get; set; }
    @AuraEnabled public String Brand { get; set; }    
    @AuraEnabled public String VisitorFingerprintId { get; set; }    
    @AuraEnabled public String fingerprintRequestId { get; set; }    
}