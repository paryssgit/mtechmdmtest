@isTest (SeeAllData=false)
private class TestMultipleDevices {
    public static BMCServiceDesk__CMDB_Class__c oDeviceAsset;
    public static BMCServiceDesk__CMDB_Class__c oCls;
    public static String userId;
    public static string DeviceId;

    static testMethod void testMultipleDevices(){
       
        userId = UserInfo.getUserId();
        DeviceId='';
        
        //Create Account
        Account oAccount = new Account(Name = 'Test Account1',BMCServiceDesk__Remedyforce_Account__c=true);
        insert oAccount;
        
        system.assert(oAccount.Id != null);
        
        //Create UserAccount Link
        BMCServiceDesk__User_Account_Link__c UALink = new BMCServiceDesk__User_Account_Link__c(BMCServiceDesk__FKAccount__c=oAccount.Id,BMCServiceDesk__FKUser__c=userId);
        insert UALink;
        system.assert(UALink.Id != null);
        
        //BMCServiceDesk__CMDB_Class__c oCls;
        oCls = new BMCServiceDesk__CMDB_Class__c(BMCServiceDesk__ClassName__c = 'BMC_BusinessService', BMCServiceDesk__CMDBClassType__c='Asset',BMCServiceDesk__SuperClass__c='BMC_BaseElement', BMCServiceDesk__Namespace__c='BMC');
        insert oCls;
        
        //BMCServiceDesk__CMDB_Class__c oDeviceAsset;
        oDeviceAsset = new BMCServiceDesk__CMDB_Class__c(BMCServiceDesk__ClassName__c = 'Device', BMCServiceDesk__CMDBClassType__c='Asset',BMCServiceDesk__SuperClass__c='BMC_BaseElement', BMCServiceDesk__Namespace__c='BMC');
        insert oDeviceAsset;
        
        //Create Service
        BMCServiceDesk__BMC_BaseElement__c oService = new BMCServiceDesk__BMC_BaseElement__c(
            BMCServiceDesk__CMDB_Class__c = oCls.Id,
            BMCServiceDesk__InstanceID__c = 'Inst-Test Device Repair Service',
            BMCServiceDesk__Name__c = 'Name-Test Device Repair Service',
            BMCServiceDesk__ServiceType__c = 'BusinessService'
        );
        insert oService;

        //Create Service Offering
        BMCServiceDesk__BMC_BaseElement__c oOffering = new BMCServiceDesk__BMC_BaseElement__c(
            BMCServiceDesk__CMDB_Class__c = oCls.Id,
            BMCServiceDesk__FKBusinessService__c = oService.Id,
            BMCServiceDesk__InstanceID__c = 'Inst-Test Repair Service',
            BMCServiceDesk__Name__c = 'Name-TestRepair Service',
            BMCServiceDesk__ServiceType__c = 'Offering'
        );
        insert oOffering;

        //Create Category
        BMCServiceDesk__Category__c oCat = new BMCServiceDesk__Category__c(Name = 'Test Category_iPhone6', BMCServiceDesk__AvailableForIncidents__c=true, BMCServiceDesk__AvailableForServiceCatalog__c=true);
        insert oCat;
        
        //Create Request detail Template
        BMCServiceDesk__SYSTemplate__c oSRTemplate = new BMCServiceDesk__SYSTemplate__c(Name='test SR Template',BMCServiceDesk__templateFor__c='Request Detail');
        insert oSRTemplate;

        //Create Incident Template        
        BMCServiceDesk__SYSTemplate__c oIncTemplate = new BMCServiceDesk__SYSTemplate__c(Name='Test Inc Template',BMCServiceDesk__templateFor__c='Incident');
        insert oIncTemplate;
        
        //Create Request Definition
        string SRName = 'Multiple Device Repair Request';
        BMCServiceDesk__SRM_RequestDefinition__c reqDef = new BMCServiceDesk__SRM_RequestDefinition__c(BMCServiceDesk__FKCategory__c=oCat.Id,BMCServiceDesk__FKBusinessService__c=oService.Id,BMCServiceDesk__FKServiceOffering__c=oOffering.Id,Name=SRName,BMCServiceDesk__serviceRequestTitle__c=SRName);
        insert reqDef;

        system.assert(reqDef.Id != null);

        //Create Request Detail
        BMCServiceDesk__SRM_RequestDetail__c oRD = new BMCServiceDesk__SRM_RequestDetail__c(
            BMCServiceDesk__FKClient__c = userId,
            BMCServiceDesk__FKRequestDefinition__c = reqDef.Id,
            BMCServiceDesk__ServiceRequest__c = 'Test Service Request for iPhone 6',
            BMCServiceDesk__ApprovalRequired__c = false
        );
        insert oRD;
        
        //Create Incident
        BMCServiceDesk__Incident__c oInc = new BMCServiceDesk__Incident__c(
            BMCServiceDesk__FKCategory__c = reqDef.BMCServiceDesk__FKCategory__c,
            BMCServiceDesk__FKClient__c = userId,
            BMCServiceDesk__FKBusinessService__c = reqDef.BMCServiceDesk__FKBusinessService__c,
            BMCServiceDesk__FKRequestDefinition__c = reqDef.Id,
            BMCServiceDesk__FKRequestDetail__c = oRD.Id,
            BMCServiceDesk__FKServiceOffering__c = reqDef.BMCServiceDesk__FKServiceOffering__c,
            BMCServiceDesk__Service_Request_Title__c = 'Multiple Device Repair Request',
            BMCServiceDesk__TemplateAlreadyApplied__c = false,
            BMCServiceDesk__TemplateName__c = '',
            BMCServiceDesk__IncidentType__c = 'Service Request',
            OwnerId = userId,
            BMCServiceDesk__contactType__c = 'Self Service',
            Account_Name__c = oAccount.Id
        );
        insert oInc;
        //system.assert(oInc.Name != '');
        system.assert(oInc.Id != null);

        System.assertEquals(oInc.BMCServiceDesk__Service_Request_Title__c,'Multiple Device Repair Request');
        
        //Update Request Detail
        BMCServiceDesk__SRM_RequestDetail__c updateoRD = [Select BMCServiceDesk__FKIncident__c from BMCServiceDesk__SRM_RequestDetail__c where id =: oRD.id];
        updateoRD.BMCServiceDesk__FKIncident__c = oInc.id;
        update updateoRD;
        
        //Create Device
        BMCServiceDesk__BMC_BaseElement__c TestDevice = new BMCServiceDesk__BMC_BaseElement__c();
            TestDevice.BMCServiceDesk__Name__c = 'Test123a'; //Instance Name
            TestDevice.MTech_Serial__c = 'Test123a'; //MTech Serial #
        	TestDevice.MTech_Asset__c = 'Test123a';
            TestDevice.BMCServiceDesk__CMDB_Class__c = oDeviceAsset.id;    // Class
            TestDevice.BMCServiceDesk__Model__c = 'iPad 4 16GB Verizon';  //Device Description
            TestDevice.Color__c = 'Gold'; //Color
            TestDevice.Device_Type__c = 'iPad'; //Device Type
            
            insert TestDevice;
        
        //Insert Devices in MTech_Devices__c
        List<MTech_Devices__c> UnRegMDs = new List<MTech_Devices__c>();
        MTech_Devices__c md1 = new MTech_Devices__c (SR_Number2__c=oInc.Id,Serial_Number__c='Test0111a',Task_Type__c='Repair',Customer_Name__c='NMG1',Device_Type__c='iPhone',Device_Description__c='iPhone 5S 16GB',Device_Color__c='Pink',Problem_Description__c='Cracked Screen',Warranty_Claim__c=True,Registered__c=false, Service_Authorized__c='Level 1 - Standard Cosmetic');
        UnRegMDs.add(md1);

        MTech_Devices__c md2 = new MTech_Devices__c (SR_Number2__c=oInc.Id,Serial_Number__c='Test123a',Task_Type__c='Provisioning',Customer_Name__c='NMG1',Device_Type__c='iPad',Device_Description__c='iPad 4 16GB Verizon',Device_Color__c='Gold',Problem_Description__c='Charge Port',Warranty_Claim__c=True,Registered__c=false, Service_Authorized__c='Level 1 - Standard Cosmetic');
        UnRegMDs.add(md2);
        
        //MTech_Devices__c md3 = new MTech_Devices__c (SR_Number2__c='TestError',Serial_Number__c='Test123a',Task_Type__c='Provisioning',Customer_Name__c='NMG1',Device_Type__c='iPad',Device_Description__c='iPad 4 16GB Verizon',Device_Color__c='Gold',Problem_Description__c='Charge Port',Warranty_Claim__c=True,Registered__c=false, Service_Authorized__c='Level 1 - Standard Cosmetic');
        //UnRegMDs.add(md3);
        
        insert UnRegMDs;
        system.assert(UnRegMDs.size()>0);
        system.assert(UnRegMDs[0].SR_Number2__c != null);
        
        Test.startTest();
        PageReference pageRef = Page.Start_Sync_Process;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardSetController sc = new ApexPages.StandardSetController(UnRegMDs);
        
        MultipleDeviceRequestController controller = new MultipleDeviceRequestController(sc);

        List<SelectOption> selSRList = controller.SRList;
        selSRList.add(new SelectOption(UnRegMDs[0].SR_Number2__c, UnRegMDs[0].SR_Number2__c));

        controller.SelectedSRNumber = UnRegMDs[0].SR_Number2__c;

        controller.getDevices();
        Controller.SyncDevices();
        
        Test.stopTest();
    }
}