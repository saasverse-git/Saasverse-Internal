public interface ITriggerHandler {
    void beforeInsert(List<SObject> newList);
    void beforeUpdate(List<SObject> newList, Map<Id, SObject> oldMap);
    void beforeDelete(List<SObject> oldList);
    
    void afterInsert(List<SObject> newList);
    void afterUpdate(List<SObject> newList, Map<Id, SObject> oldMap);
    void afterDelete(List<SObject> oldList);
    void afterUndelete(List<SObject> newList);
}