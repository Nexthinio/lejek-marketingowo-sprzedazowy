/*
Description: Since Salesforce doesn't allow to pass triggers as arguments, I'm creating my own TriggerCopy class to capture all the information surrounding the trigger.
     */

public virtual class LMS_TriggerCopy {
    public Boolean isInsert { get; protected set; }
    public Boolean isUpdate { get; protected set; }
    public Boolean isDelete { get; protected set; }
    public Integer size { get; protected set; }
    
    public List<sObject> oldList { get; protected set; }
    public Map<Id, sObject> oldMap { get; protected set; }
    
    public List<sObject> newList { get; protected set; }
    public Map<Id, sObject> newMap { get; protected set; }
    
    /**
     * Konstruktor dla LMS_TriggerCopy.
     *
     * @param isInsert Znacznik czy jest to insert
     * @param isUpdate Znacznik czy jest to update
     * @param isDelete Znacznik czy jest to delete
     * @param size Rozmiar operacji triggera
     * @param oldList Lista starych rekordów
     * @param oldMap Mapa starych rekordów
     * @param newList Lista nowych rekordów
     */
    
    public LMS_TriggerCopy (Boolean isInsert, Boolean isUpdate, Boolean isDelete,
    Integer size, List<sObject> oldList, Map<Id, sObject> oldMap, List<sObject> newList, Map<Id, sObject> newMap)
    {
        this.isInsert = isInsert;
        this.isUpdate = isUpdate;
        this.isDelete = isDelete;
        this.size = size;
        this.oldList = oldList;
        this.oldMap = oldMap;
        this.newList = newList;
        this.newMap = newMap;
    }
    
    /**
     * Zwraca reprezentację tekstową obiektu LMS_TriggerCopy dla potrzeb testu i debugowania.
     *
     * @return String
     */
    
    public override String toString() {
        return 'isInsert: ' + isInsert + ', isUpdate: ' + isUpdate + ', isDelete: ' + isDelete + ', size: ' + size + ', oldList: ' + oldList + ', oldMap: ' + oldMap + ', newList: ' + newList + ', newMap: ' + newMap;
    }
}