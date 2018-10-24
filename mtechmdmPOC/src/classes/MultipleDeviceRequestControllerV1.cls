public with sharing class MultipleDeviceRequestControllerV1 {
    public String SelectedSRNumber {get;set;}
    public String srId {get;set;}
    
    public List<MTech_Devices__c> PendingSRs {get;set;}
    public List<MTech_Devices__c> RelatedDevices {get; set;}
    
    map<Id, string> mapPendingDv = new map<Id,string>();
    Set<String> setPendingDv = new Set<String>();
        
    private ApexPages.StandardSetController standardController;
    private Set<Id> MDIds = new Set<Id>();
    
    public MultipleDeviceRequestControllerV1(ApexPages.StandardSetController sController)
    {
        standardController = sController;
        pendingSRs = new List<MTech_Devices__c>();

        PendingSRs = [Select SR_Number2__c,SR_Id__c,Serial_Number__c,Device_Type__c,Device_Description__c,Device_Color__c,Warranty_Claim__c from MTech_Devices__c WHERE Registered__c=false];
        for(MTech_Devices__c pDv : pendingSRs){
            if(pDv.SR_Number2__c != null)
            	setPendingDv.add(pDv.SR_Number2__c);
        }
        //system.debug('***srNumber - '+srNumber);
    }
    
    public List<SelectOption> SRList
    {
        get{
            SRList = new List<SelectOption>();
            
            for(string tempSrNo : setPendingDv){
                SRList.add(new SelectOption(tempSrNo,tempSrNo));
            }
            //system.debug('***SRList - ' + SRList);
            return SRList;
        }
        set;
    }
    public PageReference getDevices()
    {
        RelatedDevices = new List<MTech_Devices__c>([SELECT Id,SR_Id__c,Serial_Number__c,Device_Type__c,Device_Description__c,Device_Color__c,Warranty_Claim__c,Registered__c from MTech_Devices__c WHERE SR_Number2__c=: SelectedSRNumber]);
        return null;
    }
	
    public void SyncDevices()
    {
        System.Debug('In Sync method');
        //Get Class Id for 'MTech_Devices'    
        BMCServiceDesk__CMDB_Class__c DeviceClass = new BMCServiceDesk__CMDB_Class__c ();
        DeviceClass = [SELECT Id FROM BMCServiceDesk__CMDB_Class__c WHERE BMCServiceDesk__ClassName__c = 'Device' Limit 1];

        List<MTech_Devices__c> newMDs = new List<MTech_Devices__c>();
        
        //From Selected Devices, create a set for Serial#
        Set<String> MD1 = new Set<String>();
        for(MTech_Devices__c aMD : RelatedDevices){
            MD1.add(aMD.Serial_Number__c);
            system.debug('###Set MD1 - '+aMD.Serial_Number__c);
        }
        
        //Check if Device exists in CMDB
        List<BMCServiceDesk__BMC_BaseElement__c> existingDevices = new List<BMCServiceDesk__BMC_BaseElement__c>();
        existingDevices=[Select id, BMCServiceDesk__Name__c from BMCServiceDesk__BMC_BaseElement__c where BMCServiceDesk__SerialNumber__c IN : MD1];
        
        Set<String> existingDevices1 = new Set<String>();
        for(BMCServiceDesk__BMC_BaseElement__c aED : existingDevices){
            existingDevices1.add(aED.BMCServiceDesk__Name__c);
            system.debug('>>>Set existingDevices1 - '+aED.BMCServiceDesk__Name__c);
        }
        
        if(existingDevices.isEmpty())
            newMDs = [Select Id,Serial_Number__c,Device_Color__c,Device_Type__c,Device_Description__c from MTech_Devices__c where Serial_Number__c IN: MD1 and SR_Number2__c=:SelectedSRNumber];
        else
            newMDs = [Select Id,Serial_Number__c,Device_Color__c,Device_Type__c,Device_Description__c from MTech_Devices__c where Serial_Number__c NOT IN: existingDevices1 and SR_Number2__c=:SelectedSRNumber];
        
        //List<BMCServiceDesk__BMC_BaseElement__c> newDevices = new List<BMCServiceDesk__BMC_BaseElement__c>();

        List<BMCServiceDesk__BMC_BaseElement__c> addDevices = new List<BMCServiceDesk__BMC_BaseElement__c>();
        //Create Devices from Mtech_Devices which does not exist in CMDB
        if(newMDs.size()>0){
            for(MTech_Devices__c aDevice : newMDs){
                BMCServiceDesk__BMC_BaseElement__c MTD = new BMCServiceDesk__BMC_BaseElement__c();
                
                MTD.BMCServiceDesk__Name__c = aDevice.Serial_Number__c;  //Serial #
                MTD.BMCServiceDesk__SerialNumber__c = aDevice.Serial_Number__c;  //Serial #
                MTD.BMCServiceDesk__CMDB_Class__c = DeviceClass.id;
                MTD.BMCServiceDesk__Model__c = aDevice.Device_Description__c; //Device Description
                MTD.Color__c = aDevice.Device_Color__c; //Color
                MTD.Device_Type__c = aDevice.Device_Type__c; //Device Type
                
                addDevices.add(MTD);
            }
            system.debug('>>>addDevices: ' + addDevices);
            if (!addDevices.isEmpty())
                insert addDevices;
        }
        //Update MTech_Devices with Device Ids
        UpdateDeviceIDs(MD1, RelatedDevices);
        CreateLinkTasks(RelatedDevices);
        CompleteDeviceRegistration(RelatedDevices);
    }
    private void UpdateDeviceIDs(Set<String> MDSrNo, List<MTech_Devices__c> selDev)
    {
        //for each selected Mtech device -> get the Device ID from CMDB and update it in MTech_Devices
        List<BMCServiceDesk__BMC_BaseElement__c> DevicesIds = [Select id,BMCServiceDesk__Name__c from BMCServiceDesk__BMC_BaseElement__c where BMCServiceDesk__SerialNumber__c IN : MDSrNo];
        List<MTech_Devices__c> UpdDevIds = new List<MTech_Devices__c>();
        
        map<string,Id> mapBE = new map<string,Id>();
        for (BMCServiceDesk__BMC_BaseElement__c aBE : DevicesIds){
            mapBE.put(aBE.BMCServiceDesk__Name__c,aBE.Id);
        }
        
        for(MTech_Devices__c aDev : selDev){
            if(mapBE.containsKey(aDev.Serial_Number__c)){
                aDev.Device_Id__c = mapBE.get(aDev.Serial_Number__c);//Device Id
                system.debug('*****Device ID: '+aDev.Device_Id__c);
                system.debug('*****Serial Number: '+aDev.Serial_Number__c);
                UpdDevIds.add(aDev);
            }
        }
        update UpdDevIds;
    }
    
    private void CreateLinkTasks(List<MTech_Devices__c> MDev)
    {
        List<BMCServiceDesk__Task__c> newTasks = new List<BMCServiceDesk__Task__c>();
        for(MTech_Devices__c md : MDev)
        {
            //Create Tasks
            BMCServiceDesk__Task__c aTask = new BMCServiceDesk__Task__c();
            
            aTask.BMCServiceDesk__FKIncident__c = md.SR_Id__c;
            aTask.Configuration_Item__c = md.Device_Id__c;
            aTask.BMCServiceDesk__taskDescription__c = md.Problem_Description__c;
            aTask.OwnerId = UserInfo.getUserId();
            system.debug('*****aTask - '+aTask.Configuration_Item__c+' || '+aTask.BMCServiceDesk__taskDescription__c+' || '+aTask.BMCServiceDesk__FKIncident__c+' || '+aTask.OwnerId+' || ');
            newTasks.add(aTask);
        }
        system.debug('>>>newTasks: ' + newTasks);
        if(!newTasks.isEmpty())
            insert newTasks;
        
        //Link Configuration Item (Device) to Task
        List<BMCServiceDesk__BMC_CommonCILink__c> CILinks = new List<BMCServiceDesk__BMC_CommonCILink__c>();
        for (BMCServiceDesk__Task__c tsk : newTasks)
        {
            BMCServiceDesk__BMC_CommonCILink__c CILink = new BMCServiceDesk__BMC_CommonCILink__c();
            
            CILink.BMCServiceDesk__FKTask__c = tsk.id;
            CILink.BMCServiceDesk__CIInstance__c = tsk.Configuration_Item__c;
            CILink.BMCServiceDesk__ObjectName__c = 'Task__c';
            CILink.BMCServiceDesk__ObjectRecordID__c = 'TSK-' + tsk.id;
            CILinks.add(CILink);
            system.debug('*****CILink added for Task - '+ tsk.id);
        }
        
        insert CILinks;
        System.Debug('****CI Links created');
    }
    
    private void CompleteDeviceRegistration(List<MTech_Devices__c> UnRegisteredDevices){
        List<MTech_Devices__c> RegDevs = new List<MTech_Devices__c>();
        
        for(MTech_Devices__c rDev : UnRegisteredDevices){
            rDev.Registered__c = true;
            RegDevs.add(rDev);
        }
        update RegDevs;
    }
}