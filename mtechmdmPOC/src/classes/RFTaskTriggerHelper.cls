public class RFTaskTriggerHelper {
    public static datetime StDate;
    public static datetime EndDate;
    public static Integer TotalLinkedTasks;
    
    public static void UpdateLinkedTasks(List<BMCServiceDesk__Task__c> newTasks,Map<Id,BMCServiceDesk__Task__c>TasksOldMap){
        
        System.debug('***UpdateLinkedTasks');
        //Get MTech Contract Name from Tasks

        //try{
            Set<Id> UpdateContracts = new Set<Id>();
        
        //For Insert or Updated Tasks
        if(newTasks!=null){
        	for(BMCServiceDesk__Task__c aTask : newTasks){
                system.debug('***aTask.FKMTech_Contract__c - '+aTask.FKMTech_Contract__c);
                system.debug('***aTask.MTech_Contract__c - '+aTask.MTech_Contract__c);
                //if(aTask.MTech_Contract__c != null)
                if(aTask.FKMTech_Contract__c != null)
                	UpdateContracts.add(aTask.FKMTech_Contract__c);	//Get MTech Contract for New Tasks
                    
              	if(TasksOldMap!=null){
                    if(TasksOldMap.get(aTask.id).FKMTech_Contract__c != null)
                        UpdateContracts.add(TasksOldMap.get(aTask.id).FKMTech_Contract__c);	//Get MTech Contract for Updated Tasks
                }
            }
        }
        else{	//For Deleted Tasks
            System.debug('***Deleted Tasks');
        	for(BMCServiceDesk__Task__c aTask : TasksOldMap.values()){
                if(TasksOldMap.get(aTask.id).FKMTech_Contract__c != null)
                    UpdateContracts.add(TasksOldMap.get(aTask.id).FKMTech_Contract__c);	//Get MTech Contract for Deleted Task
            }
        }
        
        if(UpdateContracts.size()>0)
            RefreshLinkedTasks(UpdateContracts);
        //}
        //catch(DMLException e){
        //    newTasks.get(0).addError(e.getDMLMessage(0));
        //}

    }
    
    public static void RefreshLinkedTasks(Set<Id> setMContracts){
        System.debug('***RefreshLinkedTasks');
        List <MTech_Contract__c> UpdMContracts = new List<MTech_Contract__c>();
        for (Id MContractId : setMContracts){
            if(MContractId != null){
                System.debug('MTech_Contract_Name__c - '+ MContractId);
                //Get the MTech Contract Details from Contract Name in Task
                MTech_Contract__c MContract = [SELECT Id,Name,Contract_End_Date__c,Contract_Start_Date__c,IsActive__c FROM MTech_Contract__c WHERE Id=: MContractId];
                StDate =  MContract.Contract_Start_Date__c;
                EndDate = MContract.Contract_End_Date__c;
                //system.debug('Start & End Dates = ' + StDate +' - '+EndDate);
                system.debug('MContract Id = ' + MContract.Id);
                
                //Get the total Tasks based on Contract Start/End Date
                TotalLinkedTasks = [SELECT Count() FROM BMCServiceDesk__Task__c WHERE FKMTech_Contract__c =: MContractId AND BMCServiceDesk__taskType__c ='Repair' AND CreatedDate >=: StDate AND CreatedDate <=: EndDate];
                system.debug('TotalLinkedTasks for Contract ('+ MContractId + ') = ' + TotalLinkedTasks);
                
                //Update Total Linked Tasks in MTech Contract            
                MTech_Contract__c aMContract = new MTech_Contract__c();
                aMContract.Id = MContract.Id;
                aMContract.Number_Of_Linked_Tasks__c = TotalLinkedTasks;
                aMContract.Contract_Incidents_Used__c = TotalLinkedTasks;
                
                UpdMContracts.add(aMContract);
            }
    	}
        
        if(UpdMContracts.size()>0)
        	update UpdMContracts;
        
    }
    
    
    public static void LinkTaskContract(List<BMCServiceDesk__Task__c> newTasks){
        System.debug('***LinkTaskContract');
        Set<Id> RelatedBEIDs = new Set<Id>();
        //List<BMCServiceDesk__Task__c> updTasks = new List<BMCServiceDesk__Task__c>();
        for (BMCServiceDesk__Task__c aTsk : newTasks){
            RelatedBEIDs.add(aTsk.Configuration_Item__c);
            System.debug('***RelatedBEs - '+aTsk.Configuration_Item__c+' , '+ aTsk.Configuration_Item__r.Name+' , '+aTsk.Configuration_Item__r.BMCServiceDesk__Name__c+' , '+aTsk.Configuration_Item__r.Id);
        }
        //List<BMCServiceDesk__BMC_BaseElement__c> RelatedBEs = new List<BMCServiceDesk__BMC_BaseElement__c>([Select Id,Name,MTech_Contract_Number__c from BMCServiceDesk__BMC_BaseElement__c where Id IN:RelatedBEIDs]);
        Map<Id,BMCServiceDesk__BMC_BaseElement__c> AllBEs = new Map<Id,BMCServiceDesk__BMC_BaseElement__c>([Select Id, Name, MTech_Contract_Number__c from BMCServiceDesk__BMC_BaseElement__c WHERE Id IN : RelatedBEIDs]);
        if(AllBEs.size()>0){
            //Map<Id,BMCServiceDesk__BMC_BaseElement__c> AllBEs = new Map<Id,BMCServiceDesk__BMC_BaseElement__c>([Select Id, Name, MTech_Contract_Number__c from BMCServiceDesk__BMC_BaseElement__c WHERE Id IN : RelatedBEIDs]);
            Map<Id,MTech_Contract__c> AllMContracts = new Map<Id,MTech_Contract__c>([SELECT Id,Name,Contract_End_Date__c,Contract_Start_Date__c,IsActive__c FROM MTech_Contract__c]);
            
            for (BMCServiceDesk__Task__c tsk : newTasks){
                System.debug('MTech_Contract__c = ' + tsk.MTech_Contract__c);
                System.debug('1. Configuration_Item__c = ' + tsk.Configuration_Item__c);
                System.debug('MTech_Contract_Number__c = ' + tsk.MTech_Contract_Number__c);
                
                //if(tsk.Configuration_Item__c != null && String.isBlank(tsk.Configuration_Item__c)){
                
                if(tsk.Configuration_Item__c != null && !String.isBlank(tsk.Configuration_Item__c)){ //Insert
                    System.debug('2. Configuration_Item__c = ' + tsk.Configuration_Item__c);
                    //BMCServiceDesk__BMC_BaseElement__c BE = [Select Id, Name, MTech_Contract_Number__c from BMCServiceDesk__BMC_BaseElement__c where Id =: tsk.Configuration_Item__c];
                    //System.debug('BE.Name = ' + BE.MTech_Contract_Number__c);
                    String MContractNumber = AllBEs.get(tsk.Configuration_Item__c).MTech_Contract_Number__c;
                    
                    
                    System.debug('*** BE.MTech_Contract_Number__c = ' + AllBEs.get(tsk.Configuration_Item__c).MTech_Contract_Number__c);
                    //if(BE.MTech_Contract_Number__c!=null){
                    if(MContractNumber !=null){
                        //MTech_Contract__c aMContract = [SELECT Id,Name,Contract_End_Date__c,Contract_Start_Date__c,IsActive__c FROM MTech_Contract__c WHERE Id =: BE.MTech_Contract_Number__c];
        
                        tsk.FKMTech_Contract__c = AllMContracts.get(MContractNumber).Id;	//aMContract.Id;
                        tsk.MTech_Contract__c = AllMContracts.get(MContractNumber).Name;	//aMContract.Name;
                        tsk.MTech_Contract_Start__c = String.valueOf(AllMContracts.get(MContractNumber).Contract_Start_Date__c);	//String.valueOf(aMContract.Contract_Start_Date__c);
                        tsk.MTech_Contract_End__c = String.valueOf(AllMContracts.get(MContractNumber).Contract_Start_Date__c);	//String.valueOf(aMContract.Contract_End_Date__c);
                        System.debug('*** tsk.MTech_Contract__c = ' + tsk.MTech_Contract__c);
                        //updTasks.add(tsk);
                    }
                    else
                        System.debug('*** No Contract is linked to Device: ' + tsk.Configuration_Item__c);
                }
            }
        }
	}
    
    public static void UpdateLinkTaskContract(List<BMCServiceDesk__Task__c> newTasks,Map<Id,BMCServiceDesk__Task__c>TasksOldMap){
        System.debug('***UpdateLinkTaskContract');
        for (BMCServiceDesk__Task__c tsk : newTasks){
            System.debug('MTech_Contract__c = ' + tsk.MTech_Contract__c);
            System.debug('Configuration_Item__c = ' + tsk.Configuration_Item__c);
            System.debug('FKMTech_Contract__c = ' + tsk.FKMTech_Contract__c);
            
            //if(tsk.Configuration_Item__c != null && String.isBlank(tsk.Configuration_Item__c)){
            if(tsk.Configuration_Item__c != null){ //Update
                if(tsk.Configuration_Item__c != TasksOldMap.get(tsk.id).Configuration_Item__c){
                	BMCServiceDesk__BMC_BaseElement__c BE = [Select Id, Name, MTech_Contract_Number__c from BMCServiceDesk__BMC_BaseElement__c where Id =: tsk.Configuration_Item__c];
                    //System.debug('BE.Name = ' + BE.MTech_Contract_Number__c);
                    if(BE.MTech_Contract_Number__c!=null){
                        MTech_Contract__c aMContract = [SELECT Id,Name,Contract_End_Date__c,Contract_Start_Date__c,IsActive__c FROM MTech_Contract__c WHERE Id =: BE.MTech_Contract_Number__c];
        
                        tsk.FKMTech_Contract__c = aMContract.Id;
                        tsk.MTech_Contract__c = aMContract.Name;
                        tsk.MTech_Contract_Start__c = String.valueOf(aMContract.Contract_Start_Date__c);
                        tsk.MTech_Contract_End__c = String.valueOf(aMContract.Contract_End_Date__c);
                    }
                }
            }
            else if(tsk.Configuration_Item__c == null){
                if(TasksOldMap.get(tsk.id).Configuration_Item__c != null){
                    tsk.FKMTech_Contract__c = null;
                    tsk.MTech_Contract__c = '';
                    tsk.MTech_Contract_Start__c = '';
                    tsk.MTech_Contract_End__c = '';
                }
            }
		}
	}
}