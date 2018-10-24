public with sharing class MultipleDeviceRequestController {
    public String SelectedSRNumber {get;set;}
    
    //public List<MTech_Devices__c> PendingSRs {get;set;}
    public List<MTech_Devices__c> PendingSRs;
    public List<MTech_Devices__c> RelatedDevices {get; set;}
    //public List<MTech_Devices__c> RelatedDevices;
    
    public Set<String> setPendingDv = new Set<String>();
        
    private ApexPages.StandardSetController standardController;
    private Set<Id> MDIds = new Set<Id>();
    public Boolean ErrorOccured=false;
    
    public MultipleDeviceRequestController(ApexPages.StandardSetController sController)
    {
        standardController = sController;
        pendingSRs = new List<MTech_Devices__c>();

        PendingSRs = [Select SR_Id__c,Serial_Number__c,SR_Number2__c,Device_Type__c,Device_Description__c,Device_Color__c,Warranty_Claim__c from MTech_Devices__c WHERE Registered__c=false];
        for(MTech_Devices__c pDv : pendingSRs){
            if(pDv.SR_Number2__c != null)
            	setPendingDv.add(pDv.SR_Number2__c);
        }
    }
    
    public List<SelectOption> SRList
    {
        get{
            SRList = new List<SelectOption>();
            
            for(string tempSrNo : setPendingDv){
                SRList.add(new SelectOption(tempSrNo,tempSrNo));
            }
            system.debug('***SRList - ' + SRList);
            return SRList;
        }
        set;
    }
    public PageReference getDevices()
    {
        system.debug('***getDevices Entry');
        system.debug('***SelectedSRNumber - ' + SelectedSRNumber);
        if(!String.IsBlank(SelectedSRNumber)){
            RelatedDevices = new List<MTech_Devices__c>([SELECT Id,Name,SR_Id__c,Serial_Number__c,SR_Number2__c,Device_Type__c,Device_Id__c,Device_Description__c,Device_Color__c,Warranty_Claim__c,Registered__c,Problem_Description__c,Customer_Name__c,CreatedDate,Service_Authorized__c,Task_Type__c from MTech_Devices__c WHERE SR_Number2__c=: SelectedSRNumber AND Registered__c =false]);
            system.debug('***RelatedDevices - ' + RelatedDevices);
            system.debug('***getDevices Exit');
        }

        return null;
    }
	
    /*public PageReference doCancel()
    {
        return standardController.cancel();
    }
	*/
    
    //public PageReference SyncDevices()
    public void SyncDevices()
    {
        System.Debug('***In Sync method');
        //Check for Service request exists
        if(Test.isRunningTest()==false){
            If(IsSRExists(SelectedSRNumber)==false){
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,'Service Request does not Exists. Please check the number in the MTech Device records.');
                ApexPages.addMessage(myMsg);
                ErrorOccured = true;
                //throw new StringException();
            }
        }
        
        //Get Class Id for 'MTech_Devices'    
        BMCServiceDesk__CMDB_Class__c DeviceClass = new BMCServiceDesk__CMDB_Class__c ();
        DeviceClass = [SELECT Id FROM BMCServiceDesk__CMDB_Class__c WHERE BMCServiceDesk__ClassName__c = 'Device' Limit 1];

        List<MTech_Devices__c> newMDs = new List<MTech_Devices__c>();
        try{
            map<string,MTech_Devices__c> mapUnRegDevices = new map<String,MTech_Devices__c>();
            if(RelatedDevices.size()>0){
                for(MTech_Devices__c aUnregDev : RelatedDevices){
                    if(String.isBlank(aUnregDev.Serial_Number__c) || String.isBlank(aUnregDev.SR_Number2__c)){
            			ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,'Serial Number or Service Request Number cannot be blank while registering the Device. Please check the MTech Device records.');
						ApexPages.addMessage(myMsg);
                        ErrorOccured = true;
                        //aUnregDev.addError('Error');
                    }
                    else
                    	mapUnRegDevices.put(aUnregDev.Serial_Number__c,aUnregDev);
                }
            }

        //From Selected SR, create a set of Serial# for all the Devices
        Set<String> setSerialNo = new Set<String>();
        for(MTech_Devices__c aMD : RelatedDevices){
            setSerialNo.add(aMD.Serial_Number__c);
            system.debug('***Set setSerialNo - '+aMD.Serial_Number__c);
        }
        
        //try{
	        //Check if Device exists in CMDB
	        system.debug('***Set setSerialNo - '+setSerialNo.size());
	        List<BMCServiceDesk__BMC_BaseElement__c> existingDevices = new List<BMCServiceDesk__BMC_BaseElement__c>();
	        
            existingDevices=[Select id,Name,BMCServiceDesk__Name__c,MTech_Asset__c,MTech_Serial__c,MTech_IMEI__c from BMCServiceDesk__BMC_BaseElement__c where BMCServiceDesk__Name__c IN : setSerialNo OR  MTech_Asset__c IN : setSerialNo OR MTech_Serial__c IN : setSerialNo OR MTech_IMEI__c IN : setSerialNo];
	                    
	        Set<String> setExstingDvcNames = new Set<String>();
	        for(BMCServiceDesk__BMC_BaseElement__c aED : existingDevices){
	            setExstingDvcNames.add(aED.BMCServiceDesk__Name__c);
                setExstingDvcNames.add(aED.MTech_Asset__c);
                setExstingDvcNames.add(aED.MTech_Serial__c);
                setExstingDvcNames.add(aED.MTech_IMEI__c);
                
	            system.debug('***Set setExstingDvcNames - '+aED.BMCServiceDesk__Name__c);
	        }
            
            Set<string> setNewDevices = new Set<String>();
            setNewDevices = setSerialNo;
            for(String strDevice : setExstingDvcNames){
                if(setNewDevices.contains(strDevice))
                    setNewDevices.remove(strDevice);
            }
            
            //Get the New Devices fom MTech_Devices
    		if(!setNewDevices.isEmpty()){
                System.debug('New Device found which needs to be created. Create new Devices.');
	            newMDs = [Select Id,Serial_Number__c,Device_Color__c,Device_Type__c,Device_Description__c from MTech_Devices__c where Serial_Number__c IN: setNewDevices and SR_Number2__c=:SelectedSRNumber];
        	}

            /*
    		if(existingDevices.isEmpty()){
                System.debug('Existing devices not found. Create new Devices.');
	            newMDs = [Select Id,Serial_Number__c,Device_Color__c,Device_Type__c,Device_Description__c from MTech_Devices__c where Serial_Number__c IN: setSerialNo and SR_Number2__c=:SelectedSRNumber];
        	}
            else{
                System.debug('Existing devices found.');
	            newMDs = [Select Id,Serial_Number__c,Device_Color__c,Device_Type__c,Device_Description__c from MTech_Devices__c where Serial_Number__c NOT IN: setExstingDvcNames and SR_Number2__c=:SelectedSRNumber and Registered__c =false];
            }
			*/
	        
	        List<BMCServiceDesk__BMC_BaseElement__c> addDevices = new List<BMCServiceDesk__BMC_BaseElement__c>();
	        //Create Devices from Mtech_Devices which does not exist in CMDB
	        if(newMDs.size()>0){
	            for(MTech_Devices__c aDevice : newMDs){
	                BMCServiceDesk__BMC_BaseElement__c MTD = new BMCServiceDesk__BMC_BaseElement__c();
	                
	                MTD.BMCServiceDesk__Name__c = aDevice.Serial_Number__c;  //Serial #
	                MTD.BMCServiceDesk__SerialNumber__c = aDevice.Serial_Number__c;  //Serial #
                    MTD.MTech_Asset__c = aDevice.Serial_Number__c;  //Serial #
                    MTD.MTech_Serial__c = aDevice.Serial_Number__c;  //Serial #
                    MTD.MTech_IMEI__c = aDevice.Serial_Number__c;  //Serial #
	                MTD.BMCServiceDesk__CMDB_Class__c = DeviceClass.id;
	                MTD.BMCServiceDesk__Model__c = aDevice.Device_Description__c; //Device Description
	                MTD.Color__c = aDevice.Device_Color__c; //Color
	                MTD.Device_Type__c = aDevice.Device_Type__c; //Device Type
                    //System.debug('>>>Contract - '+aDevice.MTech_Contract_Name__c);
	                //if (aDevice.MTech_Contract_Name__c!=null)
	                //	MTD.MTech_Contract__c = Id.valueOf(mapContracts.get(aDevice.MTech_Contract_Name__c)); 
	                 
	                addDevices.add(MTD);
	            }
	            system.debug('>>>addDevices: ' + addDevices);
	            if (!addDevices.isEmpty())
	                insert addDevices;
	        }
            
            System.debug('***ErrorOccured : '+ErrorOccured);
	        //Update MTech_Devices with Device Ids
	        if(ErrorOccured==false){
                System.debug('***Before UpdateDeviceIDs setSerialNo = '+setSerialNo.size());
                UpdateDeviceIDs(RelatedDevices);
                CreateLinkTasks(RelatedDevices);
                CompleteDeviceRegistration(RelatedDevices);
            }
        }
        catch(Exception excp1){
			ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,'SyncDevices - '+excp1.getMessage());
			ApexPages.addMessage(myMsg);
            ErrorOccured = true;
        }
    }
    
    private Boolean IsSRExists(String ServiceRequestNo){
        try{
        BMCServiceDesk__Incident__c SelectedInc = [Select Id,Name from BMCServiceDesk__Incident__c where Name =: ServiceRequestNo limit 1];
        if(SelectedInc.Id==null)
        	return false;
        else
            return true;
        }
        catch(Exception excp2){
			ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,'IsSRExists - '+excp2.getMessage());
			ApexPages.addMessage(myMsg);
            ErrorOccured=true;
            return false;}
    }
    
    //private void UpdateDeviceIDs(Set<String> DevSerialNo, List<MTech_Devices__c> selDev)
    private void UpdateDeviceIDs(List<MTech_Devices__c> selDev)
    {
        List<MTech_Devices__c> UpdDevIds = new List<MTech_Devices__c>();
        
        Set<String> DevSerialNo = new Set<String>();
        for(MTech_Devices__c aMD : selDev){
            DevSerialNo.add(aMD.Serial_Number__c);
        }
        System.debug('---In UpdateDeviceIDs...'+DevSerialNo.size());
        System.debug('---SR_Number2__c - '+selDev[0].SR_Number2__c);
        
        //for each selected Mtech device -> get the Device ID from CMDB and update it in MTech_Devices
        List<BMCServiceDesk__BMC_BaseElement__c> InstanceNameIds = [Select id,BMCServiceDesk__Name__c from BMCServiceDesk__BMC_BaseElement__c where BMCServiceDesk__Name__c IN : DevSerialNo];
        System.debug('---InstanceNameIds.size() - ' + InstanceNameIds.size());
        List<BMCServiceDesk__BMC_BaseElement__c> AssetIds = [Select id,MTech_Asset__c from BMCServiceDesk__BMC_BaseElement__c where MTech_Asset__c IN : DevSerialNo];
        System.debug('---AssetIds.size() - ' + AssetIds.size());
        List<BMCServiceDesk__BMC_BaseElement__c> MTechSerialIds = [Select id,MTech_Serial__c from BMCServiceDesk__BMC_BaseElement__c where MTech_Serial__c IN : DevSerialNo];
        System.debug('---MTechSerialIds.size() - ' + MTechSerialIds.size());
        List<BMCServiceDesk__BMC_BaseElement__c> IMEIIds = [Select id,MTech_IMEI__c from BMCServiceDesk__BMC_BaseElement__c where MTech_IMEI__c IN : DevSerialNo];
        System.debug('---IMEIIds.size() - ' + IMEIIds.size());
        
        map<string,Id> mapInstanceNameIds = new map<string,Id>();
        for (BMCServiceDesk__BMC_BaseElement__c aInst : InstanceNameIds){
            mapInstanceNameIds.put(aInst.BMCServiceDesk__Name__c,aInst.Id);
            System.debug('---mapInstanceNameIds - '+aInst.BMCServiceDesk__Name__c+', '+aInst.Id);
        }
        
        map<string,Id> mapAssetIds = new map<string,Id>();
        for (BMCServiceDesk__BMC_BaseElement__c aAsset : AssetIds){
            mapAssetIds.put(aAsset.MTech_Asset__c,aAsset.Id);
            System.debug('---mapAssetIds - '+aAsset.MTech_Asset__c+', '+aAsset.Id);
        }
        
        map<string,Id> mapMTechSerialIds = new map<string,Id>();
        for (BMCServiceDesk__BMC_BaseElement__c aMTS : MTechSerialIds){
            mapMTechSerialIds.put(aMTS.MTech_Serial__c,aMTS.Id);
            System.debug('---mapMTechSerialIds - '+aMTS.MTech_Serial__c+', '+aMTS.Id);
        }
        
        map<string,Id> mapIMEIIds = new map<string,Id>();
        for (BMCServiceDesk__BMC_BaseElement__c aIMEI : IMEIIds){
            mapIMEIIds.put(aIMEI.MTech_IMEI__c,aIMEI.Id);
            System.debug('---mapIMEIIds - '+aIMEI.MTech_IMEI__c+', '+aIMEI.Id);
        }

        try{
            BMCServiceDesk__Incident__c SR = new BMCServiceDesk__Incident__c ();
            
            if(Test.isRunningTest()==true)
                SR = [Select Id from BMCServiceDesk__Incident__c limit 1];
            else
                SR = [Select Id from BMCServiceDesk__Incident__c where Name =: SelectedSRNumber limit 1];
            
            if(SR != null){
                system.debug('---SR Id: '+SR.Id);
                for(MTech_Devices__c aDev : selDev){
                    System.debug('---Serial Number: '+aDev.Serial_Number__c);
                    if(mapInstanceNameIds.containsKey(aDev.Serial_Number__c) || mapAssetIds.containsKey(aDev.Serial_Number__c) || mapMTechSerialIds.containsKey(aDev.Serial_Number__c) || mapIMEIIds.containsKey(aDev.Serial_Number__c)){
                        
                        if(mapInstanceNameIds.containsKey(aDev.Serial_Number__c))
                        	aDev.Device_Id__c = mapInstanceNameIds.get(aDev.Serial_Number__c);	//Device Id
                        else if(mapAssetIds.containsKey(aDev.Serial_Number__c))
                            aDev.Device_Id__c = mapAssetIds.get(aDev.Serial_Number__c);	//Device Id
                        else if(mapMTechSerialIds.containsKey(aDev.Serial_Number__c))
                            aDev.Device_Id__c = mapMTechSerialIds.get(aDev.Serial_Number__c);	//Device Id
                        else if(mapIMEIIds.containsKey(aDev.Serial_Number__c))
                            aDev.Device_Id__c = mapIMEIIds.get(aDev.Serial_Number__c);	//Device Id
                        
                        system.debug('---Device ID: '+aDev.Device_Id__c);
                        aDev.SR_Id__c = SR.Id;	//SR Id

                        UpdDevIds.add(aDev);
                    }
                }
                if(UpdDevIds.size()>0 && ErrorOccured == false)
                	update UpdDevIds;
            }
            else
            	SR.addError('---No Service Request found....');
        }
        catch(Exception excp3){
			ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,'UpdateDeviceIDs - '+excp3.getMessage());
			ApexPages.addMessage(myMsg);
            ErrorOccured=true;
        }
    }
    
    private void CreateLinkTasks(List<MTech_Devices__c> MDev)
    {
        System.debug('===In CreateLinkTasks...');
        try{
            BMCServiceDesk__Incident__c SRAccount = new BMCServiceDesk__Incident__c();
            Account SrAc;
            System.debug('===MDev[0].SR_Id__c - '+MDev[0].SR_Id__c);
            
            if(Test.isRunningTest()==true)
                SRAccount = [Select Account_Name__c from BMCServiceDesk__Incident__c Limit 1];
            else
            	SRAccount = [Select Account_Name__c from BMCServiceDesk__Incident__c where Id=: MDev[0].SR_Id__c];
            
            
            System.debug('===SRAccount - '+SRAccount.Account_Name__c);
            if(!String.isBlank(SRAccount.Account_Name__c))
            	SrAc = [Select Name from Account where Id=:SRAccount.Account_Name__c];
            
            List<BMCServiceDesk__Task__c> newTasks = new List<BMCServiceDesk__Task__c>();
            for(MTech_Devices__c md : MDev)
            {	//Create Tasks
                BMCServiceDesk__Task__c aTask = new BMCServiceDesk__Task__c();
                
                system.debug('===md: ' + md.Id + ', ' + md.Serial_Number__c);
                aTask.BMCServiceDesk__FKIncident__c = md.SR_Id__c;
                aTask.RFIncident__c = md.SR_Id__c;
                aTask.Configuration_Item__c = md.Device_Id__c;
                aTask.BMCServiceDesk__taskDescription__c = md.Problem_Description__c;
                aTask.Problem_Description__c = md.Problem_Description__c;
                aTask.Task_Status__c = 'Receiving';
                aTask.Device_Color__c = md.Device_Color__c;
                aTask.Device_Type__c = md.Device_Type__c;
                if(!String.isBlank(SRAccount.Account_Name__c))
                	aTask.Account_Name__c = SrAc.Name;
                aTask.Received_Date__c = md.CreatedDate; 
                aTask.BMCServiceDesk__openDateTime__c = md.CreatedDate; 
                aTask.Serial_Number_In__c = md.Serial_Number__c;
                aTask.Service_Customer_Name__c = md.Customer_Name__c;
                aTask.Service_Authorized__c = md.Service_Authorized__c;
                aTask.Warranty__c = md.Warranty_Claim__c;
                aTask.Device_Description__c = md.Device_Description__c;
                aTask.OwnerId = UserInfo.getUserId();
                aTask.BMCServiceDesk__taskType__c = md.Task_Type__c;
                
                system.debug('===aTask - '+aTask.Configuration_Item__c+' || '+aTask.BMCServiceDesk__taskDescription__c+' || '+aTask.BMCServiceDesk__FKIncident__c+' || '+aTask.OwnerId+' ---- ');
                newTasks.add(aTask);
            }

            if(newTasks.size()>0 && ErrorOccured == false){
                insert newTasks;
                System.Debug('===Device Tasks created');
            }
            
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
                system.debug('===CILink added for Task - '+ tsk.id);
            }
            
            if(CILinks.size()>0 && ErrorOccured == false){
            	insert CILinks;
            	System.Debug('===CI Links created');
        	}
        }
        catch(Exception excp4){
			ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,'CreateLinkTasks - '+excp4.getMessage());
			ApexPages.addMessage(myMsg);
            ErrorOccured=true;
        }
    }
    
    private void CompleteDeviceRegistration(List<MTech_Devices__c> UnRegisteredDevices){
        System.debug('###In CompleteDeviceRegistration...');
        
        try{
            List<MTech_Devices__c> RegDevs = new List<MTech_Devices__c>();
            
            for(MTech_Devices__c rDev : UnRegisteredDevices){
                rDev.Registered__c = true;
                RegDevs.add(rDev);
            }
            if(RegDevs.size()>0 && ErrorOccured == false)
            	update RegDevs;
        }
        catch(Exception excp5){
			ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,'CompleteDeviceRegistration - '+excp5.getMessage());
			ApexPages.addMessage(myMsg);
            ErrorOccured=true;
        }
    }
}