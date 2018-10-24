trigger Trigger_RFTask on BMCServiceDesk__Task__c (before insert,after insert,before update,after update,after delete) {
	
    if(Trigger.isAfter){
    	if (trigger.isUpdate || trigger.isInsert || trigger.isdelete)
   			RFTaskTriggerHelper.UpdateLinkedTasks(Trigger.new,Trigger.OldMap);	//Update the count of Number Of Linked Tasks in MTech Contract
        
        
    	//if (trigger.isInsert)
   		//	RFTaskTriggerHelper.RefreshLinkedTasks(Trigger.new,Trigger.OldMap);	//Update the count of Number Of Linked Tasks in MTech Contract
    }
    
    if(Trigger.isBefore){
        if (trigger.isUpdate)
            RFTaskTriggerHelper.UpdateLinkTaskContract(Trigger.new,Trigger.OldMap);	//When Device# gets updated
        
        if(trigger.isInsert)
            RFTaskTriggerHelper.LinkTaskContract(Trigger.new);	//When Device# gets linked
    }
}