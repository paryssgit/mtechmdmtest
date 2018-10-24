public class RFIncidentTriggerHelper {
    public static string sQuery;
    public static string SHIEmailBody;
    public static string SafewareEmailBody;
    public static String SHIFromEmail = Label.SHI_FROM_EMAIL_ADDRESS;
    public static String SHIBccEmail = Label.SHI_BCC_EMAIL_ADDRESS; //SFMOOC@shicustomersupport.com
    public static String SafewareToEmail = Label.Safeware_TO_EMAIL_ADDRESS;
    public static String SHIAccountName = Label.SHI_Account_Name;
   
    public static String[] BccAddr = SHIBccEmail.split(',');
    
    /*
     * This method validates linked Tasks Status based on Status Queue Configuration
    */
    public static void ProcessStatusQueue(List<BMCServiceDesk__Incident__c> ListSRs,Map<Id,BMCServiceDesk__Incident__c>SROldMap){
        System.debug('***In ProcessStatusQueue');
        String SRStatus;
        String SRQueue;
        //MTech_RF_Features__c MTechFeatures = MTech_RF_Features__c.getValues('Status_Queue_Validation');
        //if(MTechFeatures.Enabled__c == true){
            Map<String,Status_Queue_Configuration__mdt> SQConfigMap = new Map<string,Status_Queue_Configuration__mdt>();
        List<String> TskStatus = new List<String>();
            
            String ShippedId = string.valueOf([SELECT Id,Name FROM BMCServiceDesk__Status__c WHERE Name='SHIPPED'].Id);
            String PartiallyShippedId = string.valueOf([SELECT Id,Name FROM BMCServiceDesk__Status__c WHERE Name='PARTIALLY SHIPPED'].Id);
            String SanitizedId = string.valueOf([SELECT Id,Name FROM BMCServiceDesk__Status__c WHERE Name='SANITATION COMPLETE'].Id);
            
            //Get Status records from BMCServiceDesk__Status__c.
            List<BMCServiceDesk__Status__c> StatusList = new List<BMCServiceDesk__Status__c>([select Id,Name from BMCServiceDesk__Status__c]);
            Map<Id,BMCServiceDesk__Status__c> StatusIdMap = new Map<Id,BMCServiceDesk__Status__c>();
            for(BMCServiceDesk__Status__c aStatus : StatusList){
                StatusIdMap.put(aStatus.Id, aStatus);
            }
            
            //Get Queue records from Group.
            List<Group> QueueList = new List<Group>([select Id,Name,Type from Group where Type = 'Queue']);
            Map<String,Group> QueueIdMap = new Map<String,Group>();
            for(Group aGr : QueueList){
                QueueIdMap.put(aGr.Name.toupperCase(), aGr);
            }
            
            //Get Configuration records from Status_Queue_Configuration__mdt.
            List<Status_Queue_Configuration__mdt> SQConfigList = new List<Status_Queue_Configuration__mdt>([Select Id,DeveloperName,SR_Status__c,SR_Queue__c,Task_Status__c from Status_Queue_Configuration__mdt]);
            for(Status_Queue_Configuration__mdt aConfig : SQConfigList){
                SQConfigMap.put(aConfig.SR_Status__c.toupperCase(), aConfig);
            }
            try{
                for(BMCServiceDesk__Incident__c aSR : ListSRs){
                    System.debug('***aSR.BMCServiceDesk__FKStatus__c = '+ aSR.BMCServiceDesk__FKStatus__c);
                    if(aSR.BMCServiceDesk__isServiceRequest__c && aSR.BMCServiceDesk__FKStatus__c != ShippedId && aSR.BMCServiceDesk__FKStatus__c != SanitizedId){
                        System.debug('***Old Status = '+ SROldMap.get(aSR.Id).BMCServiceDesk__FKStatus__c);
                        System.debug('***Config Status Name = '+ StatusIdMap.get(aSR.BMCServiceDesk__FKStatus__c).Name);
                        
                        SRStatus = SQConfigMap.get(StatusIdMap.get(aSR.BMCServiceDesk__FKStatus__c).Name.toupperCase()).Task_Status__c.toupperCase();
                        SRQueue = SQConfigMap.get(StatusIdMap.get(aSR.BMCServiceDesk__FKStatus__c).Name.toupperCase()).SR_Queue__c.toupperCase();
                        System.debug('***SQConfigMap.Task_Status__c = '+SRStatus);
                        System.debug('***SQConfigMap.SR_Queue__c = '+SRQueue);
                        
                        if(SRStatus == '')
                            aSR.addError('Validation Error occurred. Service Request Status cannot be Blank. Please select the Status for Service Request# '+aSR.Name);
                        else
                            TskStatus = SRStatus.split(',');
                        
                        if(SROldMap.get(aSR.Id).BMCServiceDesk__FKStatus__c != aSR.BMCServiceDesk__FKStatus__c){
                            //Get Configuration record from Status_Queue_Configuration__mdt.
                            Map<Id,List<BMCServiceDesk__Task__c>> LinkedTasksMap = new Map<Id,List<BMCServiceDesk__Task__c>>();
                            List<BMCServiceDesk__Task__c> LinkedTasksList = new List<BMCServiceDesk__Task__c>([Select Name,Task_Status__c,Ship_Date__c,Configuration_Item__c from BMCServiceDesk__Task__c where BMCServiceDesk__FKIncident__c=: aSR.Id And Task_Status__c NOT IN: TskStatus]);
                            System.debug('***LinkedTasksList.size = '+ LinkedTasksList.size());
                            
                            if(LinkedTasksList.size() > 0)
                                LinkedTasksMap.put(aSR.Id, LinkedTasksList);
                            
                            
                            
                            if(LinkedTasksMap.size()>0){
                                //Throw validation error.
                                //Validation Message: All the linked Tasks to the Incident# 'aSR.Name' should be in the Status 'SQConfigMap.get(aSR.BMCServiceDesk__FKStatus__c).Task_Status__c'. Please check the tasks.
                                aSR.addError('Validation Error occurred. Please check Status of the Task linked to Service Request# '+aSR.Name + '. All the linked Tasks should be in: '+ SRStatus + ' status.');
                            }
                            else{
                                aSR.OwnerId=QueueIdMap.get(SRQueue).Id;
                                System.debug('***aSR.OwnerId = '+ aSR.OwnerId);
                            }
                        }
                    }
                }
            }
            catch(System.NullPointerException e){
                System.debug('***Error: Exception occured on line '+ e.getLineNumber() +', Message: '+ e.getMessage());
            }
        //}
    }
    
    /*
     * This method processes & sends email based on SHIPPED, SANITATION COMPLETE status
    */
    public static void ProcessSHISRs(List<BMCServiceDesk__Incident__c> ListSRs,Map<Id,BMCServiceDesk__Incident__c>SROldMap){
        system.debug('***In ProcessSHISRs...');
        Map<Id,List<BMCServiceDesk__Task__c>> ShippedTasks = new Map<Id,List<BMCServiceDesk__Task__c>>();
        Map<Id,List<BMCServiceDesk__Task__c>> PartiallyShippedTasks = new Map<Id,List<BMCServiceDesk__Task__c>>();
        Map<Id,List<BMCServiceDesk__Task__c>> SanitizedTasks = new Map<Id,List<BMCServiceDesk__Task__c>>();
        
        //Get Status IDs for 'SHIPPED', 'PARTIALLY SHIPPED', 'SANITATION COMPLETE'
        //List <BMCServiceDesk__Status__c> RFStatusIDs = new List<BMCServiceDesk__Status__c>([SELECT Id,Name FROM BMCServiceDesk__Status__c WHERE Name IN ('SHIPPED','PARTIALLY SHIPPED','SANITATION COMPLETE')]);
        String ShippedId = string.valueOf([SELECT Id,Name FROM BMCServiceDesk__Status__c WHERE Name='SHIPPED'].Id);
        String PartiallyShippedId = string.valueOf([SELECT Id,Name FROM BMCServiceDesk__Status__c WHERE Name='PARTIALLY SHIPPED'].Id);
        String SanitizedId = string.valueOf([SELECT Id,Name FROM BMCServiceDesk__Status__c WHERE Name='SANITATION COMPLETE'].Id);
        
        for(BMCServiceDesk__Incident__c aSR : ListSRs){
            if(aSR.AccountName__c == SHIAccountName){
                if(SROldMap.get(aSR.Id).BMCServiceDesk__FKStatus__c != aSR.BMCServiceDesk__FKStatus__c){
                    if(aSR.BMCServiceDesk__FKStatus__c==ShippedId){
                      List<BMCServiceDesk__Task__c> LinkedTasks = new List<BMCServiceDesk__Task__c>([Select Name,Task_Status__c,Ship_Date__c,Configuration_Item__c from BMCServiceDesk__Task__c where BMCServiceDesk__FKIncident__c=: aSR.Id]);
                      ShippedTasks.put(aSR.Id, LinkedTasks);
                    }
                    else if(aSR.BMCServiceDesk__FKStatus__c==SanitizedId){
                      List<BMCServiceDesk__Task__c> LinkedTasks = new List<BMCServiceDesk__Task__c>([Select Name,Task_Status__c,Ship_Date__c,Configuration_Item__c from BMCServiceDesk__Task__c where BMCServiceDesk__FKIncident__c=: aSR.Id]);
                      SanitizedTasks.put(aSR.Id, LinkedTasks);
                    }
                    /*
                    else if(aSR.BMCServiceDesk__FKStatus__c==PartiallyShippedId){
                      List<BMCServiceDesk__Task__c> LinkedTasks = new List<BMCServiceDesk__Task__c>([Select Name,Task_Status__c,Ship_Date__c,Configuration_Item__c from BMCServiceDesk__Task__c where BMCServiceDesk__FKIncident__c=: aSR.Id]);
                      PartiallyShippedTasks.put(aSR.Id, LinkedTasks);
                    }*/
                }
            }
        }
        
        if(ShippedTasks.size()>0){  //Shipped Devices
            system.debug('***ShippedTasks.size()'+ShippedTasks.size());
            
            SendShippedEmail(ShippedTasks);
            SendSafewareEmail(ShippedTasks);
        }
        if(SanitizedTasks.size()>0){    //Sanitized Devices
            system.debug('***SanitizedTasks.size()'+SanitizedTasks.size());
            
            SendSanitizedEmail(SanitizedTasks);
            SendSafewareEmail(SanitizedTasks);
        }
        /*
        if(PartiallyShippedTasks.size()>0){ //Partially Shipped Devices
            system.debug('***SRTasks.size()'+PartiallyShippedTasks.size());
            
            SendPartShippedEmail(PartiallyShippedTasks);
            SendSafewareEmail(PartiallyShippedTasks);
        }*/

    }
    
    public static void SendShippedEmail(map<id,List<BMCServiceDesk__Task__c>> SRTasksData){
        Id SHITemplateId;
        String[] CcAddr;
        String[] ToAddr;
        
        //Creating  list instance of messaging class
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        system.debug('***In SendShippedEmail...');
        //Initialize variable of messaging class
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            
        OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address =: SHIFromEmail];
        if ( owea.size() > 0 ) {
            mail.setOrgWideEmailAddressId(owea.get(0).Id);
        }
        
        SHITemplateId = [SELECT DeveloperName,Id,IsActive,TemplateType FROM EmailTemplate WHERE DeveloperName = 'StateFarm_Shipment_Email'].Id;
        
        mail.setTemplateId(SHITemplateId);
        system.debug('***SHITemplateId - '+SHITemplateId);                  
            
        //Set Bcc address of the mail
        mail.setBccAddresses(BccAddr);
            
        for(Id SRId : SRTasksData.keySet()){
            BMCServiceDesk__Incident__c IncShipped = [SELECT Id,Repair_Customer_Email__c,Customer_Manager_Email__c,BMCServiceDesk__FKContact__c from BMCServiceDesk__Incident__c where Id=:SRId];
            
            System.debug('***Repair_Customer_Email__c- '+IncShipped.Repair_Customer_Email__c);
            System.debug('***Customer_Manager_Email__c- '+IncShipped.Customer_Manager_Email__c);
            
            mail.setTargetObjectId(IncShipped.BMCServiceDesk__FKContact__c);
            
            //Set to address of the mail
            if(IncShipped.Repair_Customer_Email__c !='' && IncShipped.Repair_Customer_Email__c != null){
                ToAddr = IncShipped.Repair_Customer_Email__c.split(',');
                mail.setToAddresses(ToAddr);    //End User Email
            }
                
            if(IncShipped.Customer_Manager_Email__c != '' && IncShipped.Customer_Manager_Email__c != null){
                CcAddr = IncShipped.Customer_Manager_Email__c.split(',');
                mail.setCcAddresses(CcAddr);	//Manager's Email
            }
            
            mail.setWhatId(SRId);
            
            mail.setSaveAsActivity(false);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
            system.debug('***Shipped Email Sent...');
        }    
    }
/*
    public static void SendPartShippedEmail(map<id,List<BMCServiceDesk__Task__c>> SRTasksData){
        Id SHITemplateId;
        
        //Creating  list instance of messaging class
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        system.debug('***In SendPartShippedEmail...');
        //Initialize variable of messaging class
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        
        OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address =: SHIFromEmail];
        if ( owea.size() > 0 ) {
            mail.setOrgWideEmailAddressId(owea.get(0).Id);
        }
        
        SHITemplateId = [SELECT DeveloperName,Id,IsActive,TemplateType FROM EmailTemplate WHERE DeveloperName = 'SHI_Shipment_Notification'].Id;
        mail.setTemplateId(SHITemplateId);
        system.debug('***SHITemplateId - '+SHITemplateId);
        
        //Set Bcc address of the mail
        mail.setBccAddresses(new String[]{SHIBccEmail});
        
        for(Id SRId : SRTasksData.keySet()){
            BMCServiceDesk__Incident__c Inc = [SELECT Id,Repair_Customer_Email__c,Customer_Manager_Email__c,BMCServiceDesk__FKContact__c from BMCServiceDesk__Incident__c where Id=:SRId];
            System.debug('***SendPartShippedEmail-Repair_Customer_Email__c- '+Inc.Repair_Customer_Email__c);
            System.debug('***SendPartShippedEmail-Customer_Manager_Email__c- '+Inc.Customer_Manager_Email__c);
            System.debug('***SendPartShippedEmail-BMCServiceDesk__FKContact__c- '+Inc.BMCServiceDesk__FKContact__c);

            if(Inc.BMCServiceDesk__FKContact__c != null)
                mail.setTargetObjectId(Inc.BMCServiceDesk__FKContact__c);       //'0032C00000G0Kkw'
            
            //Set to address of the mail
            if(Inc.Repair_Customer_Email__c != null)
                mail.setToAddresses(new String[] {Inc.Repair_Customer_Email__c});
            
            if(Inc.Customer_Manager_Email__c != null)
                mail.setCcAddresses(new String[] {Inc.Customer_Manager_Email__c});  //Manager's Email
            
            mail.setWhatId(SRId);
            mail.setSaveAsActivity(false);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
            system.debug('***Partially Shipped Email Sent...');
        }
    }
*/
    public static void SendSanitizedEmail(map<id,List<BMCServiceDesk__Task__c>> SRTasksData){
        Id SHITemplateId;
        String[] CcAddr;
        String[] ToAddr;
        
        //Creating  list instance of messaging class
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        system.debug('***In SendSanitizedEmail...');
        
        //Initialize variable of messaging class
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        
        OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address =: SHIFromEmail];
        if (owea.size() > 0)
            mail.setOrgWideEmailAddressId(owea.get(0).Id);
        
        String SanitationTo = Label.SHI_SANITATION_TO_EMAIL_ADDRESS;	//MOOC Admin
        
        Contact MOOCAdmin = [Select Id,Name,Email from Contact where Email=: SanitationTo];
        
        SHITemplateId = [SELECT DeveloperName,Id,IsActive,TemplateType FROM EmailTemplate WHERE DeveloperName = 'StateFarm_MOOC_Returned_Laptop_Email'].Id;
        mail.setTemplateId(SHITemplateId);
        system.debug('***SHITemplateId - '+SHITemplateId);
        
        //Set 'MOOCAdmin' Contact
        mail.setTargetObjectId(MOOCAdmin.Id);
        
        //Set 'TO' address of the mail
        ToAddr = SanitationTo.split(',');
        mail.setToAddresses(ToAddr);    //End User Email
        
        //Set 'BCC' address of the mail
        mail.setBccAddresses(BccAddr);
        
        for(Id SRId : SRTasksData.keySet()){
            mail.setWhatId(SRId);
            mail.setSaveAsActivity(false);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
            system.debug('***Sanitation Email Sent...');
        }
    }
    
    public static void SendSafewareEmail(map<id,List<BMCServiceDesk__Task__c>> SRTasksData){
        Id SafewareTemplateId;
        String SafewareUserName = Label.Safeware_UserName;
        
        User SWUser = [Select Id,Name,Email,username from User where username=: SafewareUserName];
        //Creating  list instance of messaging class
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        system.debug('***In SendSafewareEmail...');
        //Initialize variable of messaging class
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            
        OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address =: SHIFromEmail];
        if ( owea.size() > 0 ) {
            mail.setOrgWideEmailAddressId(owea.get(0).Id);
        }
        
        SafewareTemplateId = [SELECT DeveloperName,Id,IsActive,TemplateType FROM EmailTemplate WHERE DeveloperName = 'Safeware_Shipment_Notification'].Id;
        mail.setTemplateId(SafewareTemplateId);
        system.debug('***SafewareTemplateId - '+SafewareTemplateId);
                    
        //Set to address of the mail
        mail.setToAddresses(new String[] {SafewareToEmail});
        
        for(Id SRId : SRTasksData.keySet()){
            if(SWUser != null)
                mail.setTargetObjectId(SWUser.Id);
            
            mail.setWhatId(SRId);
            mail.setSaveAsActivity(false);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
            system.debug('***Safeware Email Sent...');
        }
    }
}