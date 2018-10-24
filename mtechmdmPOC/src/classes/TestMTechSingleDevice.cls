@isTest (SeeAllData=false)
private class TestMTechSingleDevice {
    public static BMCServiceDesk__CMDB_Class__c oCls;
    public static BMCServiceDesk__CMDB_Class__c oDeviceAsset;
    public static String userId;
    public static string DeviceId;
    
    public static void CreateTestData(){
        //Test.startTest();
        //String userName = UserInfo.getUserName();
        //User activeUser = [Select Id, Name, Email From User where Username=: userName limit 1];
        //String userNm = activeUser.Name;
        //String userEmail = activeUser.Email;
        userId = UserInfo.getUserId();
        DeviceId='';
        
        //BMCServiceDesk__CMDB_Class__c oCls;
        //oCls = [Select Id from BMCServiceDesk__CMDB_Class__c where BMCServiceDesk__ClassName__c = 'BMC_BusinessService'];
        oCls = new BMCServiceDesk__CMDB_Class__c(BMCServiceDesk__ClassName__c = 'BMC_BusinessService', BMCServiceDesk__CMDBClassType__c='CI',BMCServiceDesk__SuperClass__c='BMC_BaseElement', BMCServiceDesk__Namespace__c='BMC');
        insert oCls;
        system.assert(oCls != null);
        
        //BMCServiceDesk__CMDB_Class__c oDeviceAsset;
        oDeviceAsset = new BMCServiceDesk__CMDB_Class__c(BMCServiceDesk__ClassName__c = 'Device', BMCServiceDesk__CMDBClassType__c='Asset',BMCServiceDesk__SuperClass__c='BMC_BaseElement', BMCServiceDesk__Namespace__c='BMC');
        insert oDeviceAsset;
        system.assert(oDeviceAsset != null);
    }
    
    public static void TestDataSQConfig(){
        oCls = new BMCServiceDesk__CMDB_Class__c(BMCServiceDesk__ClassName__c = 'BMC_BusinessService', BMCServiceDesk__CMDBClassType__c='CI',BMCServiceDesk__SuperClass__c='BMC_BaseElement', BMCServiceDesk__Namespace__c='BMC');
        insert oCls;
        system.assert(oCls != null);
        
        oDeviceAsset = new BMCServiceDesk__CMDB_Class__c(BMCServiceDesk__ClassName__c = 'Device', BMCServiceDesk__CMDBClassType__c='Asset',BMCServiceDesk__SuperClass__c='BMC_BaseElement', BMCServiceDesk__Namespace__c='BMC');
        insert oDeviceAsset;
        system.assert(oDeviceAsset != null); 
        
        Status_Queue_Configuration__mdt[] SQConfigList = [Select Id,DeveloperName,SR_Status__c,SR_Queue__c,Task_Status__c from Status_Queue_Configuration__mdt];
        system.assert(SQConfigList.size()>0);
        
        BMCServiceDesk__Status__c IncOpenStatus = new BMCServiceDesk__Status__c(Name = 'Open',BMCServiceDesk__state__c=true,BMCServiceDesk__appliesToIncident__c=true);
        insert IncOpenStatus;
        
        BMCServiceDesk__Status__c IncStatus;
        BMCServiceDesk__Status__c TskStatus;
        
        if(SQConfigList[0].SR_Status__c != SQConfigList[0].Task_Status__c){
        //Create Status
            IncStatus = new BMCServiceDesk__Status__c(Name = SQConfigList[0].SR_Status__c,BMCServiceDesk__state__c=true,BMCServiceDesk__appliesToIncident__c=true);
            insert IncStatus;
    
            TskStatus = new BMCServiceDesk__Status__c(Name = SQConfigList[0].Task_Status__c,BMCServiceDesk__state__c=true,BMCServiceDesk__appliesToTask__c=true);
            insert TskStatus;
        }
        else{
            IncStatus = new BMCServiceDesk__Status__c(Name = SQConfigList[0].SR_Status__c,BMCServiceDesk__state__c=true,BMCServiceDesk__appliesToIncident__c=true,BMCServiceDesk__appliesToTask__c=true);
            insert IncStatus;
            
            TskStatus = IncStatus;
        }
        
        //Create Queue
        Group STQueue = new Group (Name=SQConfigList[0].SR_Queue__c,Type = 'Queue');
        insert STQueue;
        system.assert(STQueue.Id!=null);
        
        //QueueSobject QSObj = new QueueSobject (QueueId=STQueue.Id,SobjectType='BMCServiceDesk__Incident__c');
        //insert QSObj;
    }
    
    
    static testMethod void testSingleDevice(){

        CreateTestData();
        system.assert(oDeviceAsset != null);

        //Create Account
        Account Ac = new Account(Name='State Farm',BMCServiceDesk__Remedyforce_Account__c=true);
        insert Ac;
        
        //Create Contact
      	Contact Ct = new Contact(Account=Ac,FirstName='Test',LastName='Contact',Customer_Name__c='TestCustomer',Email='myemail@test.com',Manager_Email__c='Manager@Test.com');
        insert ct;
            
        //Fetch Status Queue Configuration
        //Status_Queue_Configuration__mdt SQConfig = new Status_Queue_Configuration__mdt(Label='Repair',SR_Status__c=InRepairStatus.Name,SR_Queue__c=STQueue.Name,Task_Status__c=InRepairStatus.Name);
        //insert SQConfig;

        
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
        string SRName = 'Single Device Repair Request';
        //string SRName1 = 'Incoming Single Device Request';
        BMCServiceDesk__SRM_RequestDefinition__c reqDef = new BMCServiceDesk__SRM_RequestDefinition__c(BMCServiceDesk__FKCategory__c=oCat.Id,BMCServiceDesk__FKBusinessService__c=oService.Id,BMCServiceDesk__FKServiceOffering__c=oOffering.Id,Name=SRName,BMCServiceDesk__serviceRequestTitle__c=SRName);
        insert reqDef;
        
        //BMCServiceDesk__SRM_RequestDefinition__c reqDef = Database.query('Select Id,BMCServiceDesk__FKCategory__c,BMCServiceDesk__FKBusinessService__c,BMCServiceDesk__FKServiceOffering__c from BMCServiceDesk__SRM_RequestDefinition__c where Name =: SRName');
        
        system.assert(reqDef.Id != null);

        //Create Request Detail
        BMCServiceDesk__SRM_RequestDetail__c oRD = new BMCServiceDesk__SRM_RequestDetail__c(
            BMCServiceDesk__FKClient__c = userId,
            //BMCServiceDesk__FKIncident__c = '',
            BMCServiceDesk__FKRequestDefinition__c = reqDef.Id,
            BMCServiceDesk__ServiceRequest__c = 'Test Service Request for iPhone 6',
            BMCServiceDesk__ApprovalRequired__c = false
        );
        insert oRD;
        
        Test.startTest();
        //Create Incident
        BMCServiceDesk__Incident__c oInc = new BMCServiceDesk__Incident__c(
            BMCServiceDesk__FKCategory__c = reqDef.BMCServiceDesk__FKCategory__c,
            BMCServiceDesk__FKClient__c = userId,
            BMCServiceDesk__FKBusinessService__c = reqDef.BMCServiceDesk__FKBusinessService__c,
            BMCServiceDesk__FKRequestDefinition__c = reqDef.Id,
            BMCServiceDesk__FKRequestDetail__c = oRD.Id,
            BMCServiceDesk__FKServiceOffering__c = reqDef.BMCServiceDesk__FKServiceOffering__c,
            BMCServiceDesk__Service_Request_Title__c = 'Single Device Repair Request',
            BMCServiceDesk__TemplateAlreadyApplied__c = false,
            BMCServiceDesk__TemplateName__c = '',
            BMCServiceDesk__IncidentType__c = 'Service Request',
            SR_Serial__c='Test00011b',
            SR_Model__c='iPhone',
            SR_Color__c='Gold',
            SR_Device_Type__c='iPhone',
            OwnerId = userId,
            BMCServiceDesk__contactType__c = 'Self Service'
            //BMCServiceDesk__FKStatus__c = IncOpenStatus.Id
        );
        insert oInc;

        
        System.assertEquals(oInc.BMCServiceDesk__Service_Request_Title__c,'Single Device Repair Request');
        //Test.stopTest();
        //Update Request Detail
        BMCServiceDesk__SRM_RequestDetail__c updateoRD = [Select BMCServiceDesk__FKIncident__c from BMCServiceDesk__SRM_RequestDetail__c where id =: oRD.id];
        updateoRD.BMCServiceDesk__FKIncident__c = oInc.id;
        update updateoRD;

        List<BMCServiceDesk__BMC_BaseElement__c> LinkedDevice = new List<BMCServiceDesk__BMC_BaseElement__c>([Select Id, BMCServiceDesk__Name__c from BMCServiceDesk__BMC_BaseElement__c where BMCServiceDesk__Name__c =: oInc.SR_Serial__c]);
        //System.assertEquals(LinkedDevice.size(),1);
        //Test.startTest();
        
        //Create Device
        BMCServiceDesk__BMC_BaseElement__c TestDevice = new BMCServiceDesk__BMC_BaseElement__c();
        if(LinkedDevice.size()== 0){
            TestDevice.BMCServiceDesk__Name__c = oInc.SR_Serial__c; //Instance Name
            TestDevice.BMCServiceDesk__SerialNumber__c = oInc.SR_Serial__c; //Serial #
            TestDevice.BMCServiceDesk__CMDB_Class__c = oDeviceAsset.id;    // Class
            TestDevice.BMCServiceDesk__Model__c = oInc.SR_Model__c;  //Device Description
            TestDevice.Color__c = oInc.SR_Color__c; //Color
            TestDevice.Device_Type__c = oInc.SR_Device_Type__c; //Device Type
            
            insert TestDevice;
        }
        
        if(LinkedDevice.isEmpty()){
            DeviceId = TestDevice.id;
            System.Debug('****New Device found. DeviceId - ' + DeviceId);
        }
        else{
            DeviceId = LinkedDevice[0].id;
            System.Debug('****Existing Device found. DeviceId - ' + DeviceId);
        }

        //Create Task
        BMCServiceDesk__Task__c newTask = new BMCServiceDesk__Task__c();
        newTask.BMCServiceDesk__FKIncident__c = oInc.id;
        newTask.RFIncident__c = oInc.Id;
        newTask.Configuration_Item__c = DeviceId;
        newtask.BMCServiceDesk__taskDescription__c = 'Test Task Desc';
        newtask.OwnerId = UserInfo.getUserId();
        //newtask.BMCServiceDesk__FKStatus__c = TskStatus.Id;
        
        insert newtask;
        
        //Update Service Request
        //BMCServiceDesk__Incident__c UpdSR1 = new BMCServiceDesk__Incident__c(Id=oInc.Id,BMCServiceDesk__FKStatus__c = IncStatus.Id);
        //update UpdSR1;
        
        Test.stopTest();
    }    
    
    static testMethod void testStateFarmService(){
        oCls = new BMCServiceDesk__CMDB_Class__c(BMCServiceDesk__ClassName__c = 'BMC_BusinessService', BMCServiceDesk__CMDBClassType__c='CI',BMCServiceDesk__SuperClass__c='BMC_BaseElement', BMCServiceDesk__Namespace__c='BMC');
        insert oCls;
        system.assert(oCls != null);
        
        //BMCServiceDesk__CMDB_Class__c oDeviceAsset;
        oDeviceAsset = new BMCServiceDesk__CMDB_Class__c(BMCServiceDesk__ClassName__c = 'Device', BMCServiceDesk__CMDBClassType__c='Asset',BMCServiceDesk__SuperClass__c='BMC_BaseElement', BMCServiceDesk__Namespace__c='BMC');
        insert oDeviceAsset;
        system.assert(oDeviceAsset != null);
        
        string SRName1 = 'Incoming Single Device Request';
        string MOOCLAdminEmail = Label.SHI_SANITATION_TO_EMAIL_ADDRESS;
        
        //Create Account
        Account Ac = new Account(Name='State Farm',BMCServiceDesk__Remedyforce_Account__c=true);
        insert Ac;
        
      	Contact Ct = new Contact(Account=Ac,FirstName='Test',LastName='Contact',Customer_Name__c='TestCustomer',Email='myemail@test.com',Manager_Email__c='Manager@Test.com');
        insert ct;

      	Contact MOCCAdmin = new Contact(Account=Ac,FirstName='MOOC',LastName='Admin',Customer_Name__c='TestCustomer',Email=MOOCLAdminEmail,Manager_Email__c=MOOCLAdminEmail);
        insert MOCCAdmin;
        
        BMCServiceDesk__Category__c ProvCat = new BMCServiceDesk__Category__c(Name = 'Provisioning', BMCServiceDesk__AvailableForIncidents__c=true, BMCServiceDesk__AvailableForServiceCatalog__c=true);
        insert ProvCat;
        
        BMCServiceDesk__Category__c SanitCat = new BMCServiceDesk__Category__c(Name = 'Sanitation', BMCServiceDesk__AvailableForIncidents__c=true, BMCServiceDesk__AvailableForServiceCatalog__c=true);
        insert SanitCat;
        
        BMCServiceDesk__Status__c ProcessingStatus = new BMCServiceDesk__Status__c(Name = 'PROCESSING',BMCServiceDesk__state__c=true,BMCServiceDesk__appliesToIncident__c=true);
        insert ProcessingStatus;
        
        BMCServiceDesk__Status__c PartStatus = new BMCServiceDesk__Status__c(Name = 'PARTIALLY SHIPPED',BMCServiceDesk__state__c=true,BMCServiceDesk__appliesToIncident__c=true);
        insert PartStatus;

        BMCServiceDesk__Status__c ProvStatus = new BMCServiceDesk__Status__c(Name = 'SHIPPED',BMCServiceDesk__state__c=true,BMCServiceDesk__appliesToIncident__c=true);
        insert ProvStatus;

        
        BMCServiceDesk__Status__c SanitStatus = new BMCServiceDesk__Status__c(Name = 'SANITATION COMPLETE',BMCServiceDesk__state__c=true,BMCServiceDesk__appliesToIncident__c=true);
        insert SanitStatus;

        
        system.assert(ProvCat.Id != null);
        system.assert(SanitCat.Id != null);

        //Create Service
        BMCServiceDesk__BMC_BaseElement__c oService1 = new BMCServiceDesk__BMC_BaseElement__c(
            BMCServiceDesk__CMDB_Class__c = oCls.Id,
            BMCServiceDesk__InstanceID__c = 'Inst-Test Device Repair Service',
            BMCServiceDesk__Name__c = 'Name-Test Device Repair Service',
            BMCServiceDesk__ServiceType__c = 'BusinessService'
        );
        insert oService1;
        
        //Create Service Offering
        BMCServiceDesk__BMC_BaseElement__c oOffering1 = new BMCServiceDesk__BMC_BaseElement__c(
            BMCServiceDesk__CMDB_Class__c = oCls.Id,
            BMCServiceDesk__FKBusinessService__c = oService1.Id,
            BMCServiceDesk__InstanceID__c = 'Inst-Test Repair Service',
            BMCServiceDesk__Name__c = 'Name-TestRepair Service',
            BMCServiceDesk__ServiceType__c = 'Offering'
        );
        insert oOffering1;

        BMCServiceDesk__SRM_RequestDefinition__c reqDef1 = new BMCServiceDesk__SRM_RequestDefinition__c(BMCServiceDesk__FKCategory__c=ProvCat.Id,BMCServiceDesk__FKBusinessService__c=oService1.Id,BMCServiceDesk__FKServiceOffering__c=oOffering1.Id,Name=SRName1,BMCServiceDesk__serviceRequestTitle__c=SRName1);
        insert reqDef1;

        system.assert(reqDef1.Id != null);
        
        BMCServiceDesk__SRM_RequestDetail__c oRD1 = new BMCServiceDesk__SRM_RequestDetail__c(
            BMCServiceDesk__FKClient__c = userId,
            //BMCServiceDesk__FKIncident__c = '',
            BMCServiceDesk__FKRequestDefinition__c = reqDef1.Id,
            BMCServiceDesk__ServiceRequest__c = 'Test Service Request for iPhone 6',
            BMCServiceDesk__ApprovalRequired__c = false
        );
        insert oRD1;

        Test.startTest();
        
        BMCServiceDesk__Incident__c IncProv = new BMCServiceDesk__Incident__c(
            Account_Name__c = Ac.Id,
            Device_Quantity__c = 1,
            BMCServiceDesk__FKContact__c = Ct.Id,
            Repair_Customer_Name__c = 'TestCustomer',
            Repair_Customer_Email__c = 'myemail@test.com',
            Customer_Manager_Email__c = 'Manager@Test.com',
            Shipping_Address__c = 'Dallas, TX',
            BMCServiceDesk__incidentDescription__c = 'TEST. TEST. TEST.',
            BMCServiceDesk__FKCategory__c = ProvCat.Id,
            BMCServiceDesk__FKClient__c = UserInfo.getUserId(),
            BMCServiceDesk__FKBusinessService__c = reqDef1.BMCServiceDesk__FKBusinessService__c,
            BMCServiceDesk__FKRequestDefinition__c = reqDef1.Id,
            BMCServiceDesk__FKServiceOffering__c = reqDef1.BMCServiceDesk__FKServiceOffering__c,
            BMCServiceDesk__FKRequestDetail__c = oRD1.Id,
            BMCServiceDesk__Service_Request_Title__c = 'Incoming Single Device Request',
            BMCServiceDesk__IncidentType__c = 'Service Request',
            OwnerId = UserInfo.getUserId(),
            BMCServiceDesk__FKStatus__c = ProcessingStatus.Id,
            Purchase_Order__c = '1234',
            MTech_Priority__c = '1 - Urgent'
        );
        insert IncProv;
        
        
        BMCServiceDesk__Incident__c IncSanit = new BMCServiceDesk__Incident__c(
            Account_Name__c = Ac.Id,
            Device_Quantity__c = 1,
            BMCServiceDesk__FKContact__c = Ct.Id,
            Repair_Customer_Name__c = 'TestCustomer',
            Repair_Customer_Email__c = 'myemail@test.com',
            Customer_Manager_Email__c = 'Manager@Test.com',
            Shipping_Address__c = 'Dallas, TX',
            BMCServiceDesk__incidentDescription__c = 'TEST. TEST. TEST.',
            BMCServiceDesk__FKCategory__c = SanitCat.Id,
            BMCServiceDesk__FKClient__c = UserInfo.getUserId(),
            BMCServiceDesk__FKBusinessService__c = reqDef1.BMCServiceDesk__FKBusinessService__c,
            BMCServiceDesk__FKRequestDefinition__c = reqDef1.Id,
            BMCServiceDesk__FKServiceOffering__c = reqDef1.BMCServiceDesk__FKServiceOffering__c,
            BMCServiceDesk__FKRequestDetail__c = oRD1.Id,
            BMCServiceDesk__Service_Request_Title__c = 'Incoming Single Device Request',
            BMCServiceDesk__IncidentType__c = 'Service Request',
            OwnerId = UserInfo.getUserId(),
            BMCServiceDesk__FKStatus__c = ProcessingStatus.Id,
            Purchase_Order__c = '1234',
            MTech_Priority__c = '1 - Urgent'
        );
        insert IncSanit;

        BMCServiceDesk__Task__c ProvTask = new BMCServiceDesk__Task__c();
        
        ProvTask.BMCServiceDesk__FKIncident__c = IncProv.Id;
        ProvTask.RFIncident__c = IncProv.Id;
        //aTask.BMCServiceDesk__taskDescription__c = ProbDesc;
        ProvTask.Problem_Description__c = 'Blank Task';
        ProvTask.Task_Status__c = 'Receiving';
        ProvTask.Account_Name__c = Ac.Id;
        ProvTask.Received_Date__c = system.today(); 
        ProvTask.BMCServiceDesk__openDateTime__c = system.today(); 
        ProvTask.Service_Customer_Name__c = 'TestCustomer';
        ProvTask.OwnerId = UserInfo.getUserId();
        ProvTask.Purchase_Order_Number__c = '1234';
        
        insert ProvTask;
        System.debug('Task Added='+ProvTask.Name);

        
        BMCServiceDesk__Task__c SanitTask = new BMCServiceDesk__Task__c();
        
        SanitTask.BMCServiceDesk__FKIncident__c = IncProv.Id;
        SanitTask.RFIncident__c = IncProv.Id;
        //aTask.BMCServiceDesk__taskDescription__c = ProbDesc;
        SanitTask.Problem_Description__c = 'Blank Task';
        SanitTask.Task_Status__c = 'Receiving';
        SanitTask.Account_Name__c = Ac.Id;
        SanitTask.Received_Date__c = system.today(); 
        SanitTask.BMCServiceDesk__openDateTime__c = system.today(); 
        SanitTask.Service_Customer_Name__c = 'TestCustomer';
        SanitTask.OwnerId = UserInfo.getUserId();
        SanitTask.Purchase_Order_Number__c = '1234';
        
        insert SanitTask;
        System.debug('Task Added='+SanitTask.Name);

        //Update Service Requests
        BMCServiceDesk__Incident__c UpdSR1 = new BMCServiceDesk__Incident__c(Id=IncProv.Id, BMCServiceDesk__incidentDescription__c = 'Send Email', BMCServiceDesk__FKStatus__c = ProvStatus.Id);        
        update UpdSR1;
        
        BMCServiceDesk__Incident__c UpdSR2 = new BMCServiceDesk__Incident__c(Id=IncSanit.Id,  BMCServiceDesk__incidentDescription__c = 'Send Email', BMCServiceDesk__FKStatus__c = SanitStatus.Id);        
        update UpdSR2;
        
        Test.stopTest();

    }
    
    static testMethod void BeforeUpdateStatusQueueConfig(){
    }
    
}