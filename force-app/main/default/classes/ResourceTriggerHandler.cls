public class ResourceTriggerHandler implements ITriggerHandler {

    public void beforeInsert(List<SObject> newList) {
       //List<Account> accList = (List<Account>)newList;
        // custom logic here
    }

    public void beforeUpdate(List<SObject> newList, Map<Id, SObject> oldMap) {
        List<Account> accList = (List<Account>)newList;
        Map<Id, Account> oldAccMap = (Map<Id, Account>)oldMap;
        // custom logic here
    }

    public void beforeDelete(List<SObject> oldList) {
        List<Account> accList = (List<Account>)oldList;
        // custom logic here
    }

    public void afterInsert(List<SObject> newList) {
      // List<Account> accList = (List<Account>)newList;
        // custom logic here
    }

    public void afterUpdate(List<SObject> newList, Map<Id, SObject> oldMap) {
        List<Account> accList = (List<Account>)newList;
        Map<Id, Account> oldAccMap = (Map<Id, Account>)oldMap;
        // custom logic here
    }

    public void afterDelete(List<SObject> oldList) {
        List<Account> accList = (List<Account>)oldList;
        // custom logic here
    }

    public void afterUndelete(List<SObject> newList) {
        List<Account> accList = (List<Account>)newList;
        // custom logic here
    }
}