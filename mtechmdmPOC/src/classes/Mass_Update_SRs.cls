public class Mass_Update_SRs {
	//string[] SRNos = new string[] {'1','2'};
	List<string> EmailList = new List<string>{'paryss25@yahoo.com'};
	
	//set<string> SrNoSet = new set<string>{'1','2'};
	//map<id,BMCServiceDesk__Incident__c> SRmap = new map<Id,BMCServiceDesk__Incident__c>([Select Id, Name, BMCServiceDesk__FKStatus__c from BMCServiceDesk__Incident__c where Name IN : SrNoSet]);
	List<string> SRNoList = new List<string>{'00001081','00001082'};
    map<id,BMCServiceDesk__Incident__c> SRmap = new map<Id,BMCServiceDesk__Incident__c>([Select Id, Name, BMCServiceDesk__FKStatus__c from BMCServiceDesk__Incident__c where Name IN : SRNoList]);
    //List<BMCServiceDesk__Incident__c> SRList = new List<BMCServiceDesk__Incident__c>([Select Id, Name, BMCServiceDesk__FKStatus__c from BMCServiceDesk__Incident__c where Name IN : SRNoList]);
    //set<string> SRIds = new set<string>();
    
    //for(BMCServiceDesk__Incident__c Inc:SRList){
    //    System.debug('Incident# '+Inc.Name);
    //}
    

    
    map<id,BMCServiceDesk__Task__c> TSKmap = new map<Id,BMCServiceDesk__Task__c>([Select Id, Name,BMCServiceDesk__FKStatus__c,Task_Status__c from BMCServiceDesk__Task__c where BMCServiceDesk__FKIncident__c IN : SRmap.keySet()]);
    
}