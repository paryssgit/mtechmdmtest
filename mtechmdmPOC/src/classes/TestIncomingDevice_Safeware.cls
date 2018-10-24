@isTest(seeAllData = false)
public class TestIncomingDevice_Safeware {
    
    //public User demoUser;
    public static string DemoUserId = '';
    public static BMCServiceDesk__CMDB_Class__c oCls;
    public static BMCServiceDesk__CMDB_Class__c oDeviceAsset;
    public static string REQUESTDEFINITION = 'Incoming Single Device Request';
    public static User demoUser;

    public static testMethod void CreateTestData(){
        //Create RF Account
        Account ac = new Account(Name='Test Account',BMCServiceDesk__Remedyforce_Account__c=true);
        insert ac;
        
        //Get Profile Id for ServiceDesk Client profile
        Profile pf = [Select Id,Name from Profile where Name='ServiceDesk Client'];
        
        //Create Demo User
        demoUser = new User(Username='demouseremailaddress@email.com',Email='demouseremailaddress@email.com',FirstName='Demo',LastName='User',ProfileId=pf.Id,Alias='DemoUser',TimeZoneSidKey='America/New_York',LocaleSidKey='en_US',EmailEncodingKey='ISO-8859-1',LanguageLocaleKey='en_US',BMCServiceDesk__Account_Name__c=ac.Name,BMCServiceDesk__Account_ID__c=ac.Id);
        insert demoUser;
        
        DemoUserId = demoUser.Id;
        
        //Link Account to User
        BMCServiceDesk__User_Account_Link__c UALink = new BMCServiceDesk__User_Account_Link__c(BMCServiceDesk__FKAccount__c=ac.Id,BMCServiceDesk__FKUser__c= demoUser.Id);
        insert UALink;
        System.assert(UALink != null);
        System.assert(demoUser.BMCServiceDesk__Account_Name__c != null);
        
        //BMCServiceDesk__CMDB_Class__c oCls;
        oCls = new BMCServiceDesk__CMDB_Class__c(BMCServiceDesk__ClassName__c = 'BMC_BusinessService', BMCServiceDesk__CMDBClassType__c='CI',BMCServiceDesk__SuperClass__c='BMC_BaseElement', BMCServiceDesk__Namespace__c='BMC');
        insert oCls;
        
        //BMCServiceDesk__CMDB_Class__c oDeviceAsset;
        oDeviceAsset = new BMCServiceDesk__CMDB_Class__c(BMCServiceDesk__ClassName__c = 'Device', BMCServiceDesk__CMDBClassType__c='Asset',BMCServiceDesk__SuperClass__c='BMC_BaseElement', BMCServiceDesk__Namespace__c='BMC');
        insert oDeviceAsset;
        
        //Create Service
        BMCServiceDesk__BMC_BaseElement__c oService = new BMCServiceDesk__BMC_BaseElement__c(
            BMCServiceDesk__CMDB_Class__c = oCls.Id,
            BMCServiceDesk__Name__c = 'Test Incoming Device Service',
            BMCServiceDesk__ServiceType__c = 'BusinessService'
        );
        insert oService;
        system.assert(oService.Id != null);
        
        //Create Service Offering
        BMCServiceDesk__BMC_BaseElement__c oOffering = new BMCServiceDesk__BMC_BaseElement__c(
            BMCServiceDesk__CMDB_Class__c = oCls.Id,
            BMCServiceDesk__FKBusinessService__c = oService.Id,
            BMCServiceDesk__Name__c = 'Test Incoming Device Service Offering',
            BMCServiceDesk__ServiceType__c = 'Offering'
        );
        insert oOffering;
        system.assert(oOffering.Id != null);
        
        //Create Category
        BMCServiceDesk__Category__c oCat = new BMCServiceDesk__Category__c(Name = 'Device Repair Service', BMCServiceDesk__AvailableForIncidents__c=true, BMCServiceDesk__AvailableForServiceCatalog__c=true);
        insert oCat;
        //Create Category
        BMCServiceDesk__Category__c oCat1 = new BMCServiceDesk__Category__c(Name = 'Provisioning', BMCServiceDesk__AvailableForIncidents__c=true, BMCServiceDesk__AvailableForServiceCatalog__c=true);
        insert oCat1;
        //Create Category
        BMCServiceDesk__Category__c oCat2 = new BMCServiceDesk__Category__c(Name = 'Sanitation', BMCServiceDesk__AvailableForIncidents__c=true, BMCServiceDesk__AvailableForServiceCatalog__c=true);
        insert oCat2;

        system.assert(oCat.Id != null);
        system.assert(oCat1.Id != null);
        system.assert(oCat2.Id != null);
        
        //Create Request detail Template
        BMCServiceDesk__SYSTemplate__c oSRTemplate = new BMCServiceDesk__SYSTemplate__c(Name='Test SR Template',BMCServiceDesk__templateFor__c='Request Detail');
        insert oSRTemplate;
        system.assert(oSRTemplate.Id != null);

        //Create Incident Template        
        BMCServiceDesk__SYSTemplate__c oIncTemplate = new BMCServiceDesk__SYSTemplate__c(Name='Test Inc Template',BMCServiceDesk__templateFor__c='Incident');
        insert oIncTemplate;
        system.assert(oIncTemplate.Id != null);
        
        //Create Request Definition
        string SRName = 'Incoming Single Device Request';   //Incoming Single Device Request
        BMCServiceDesk__SRM_RequestDefinition__c reqDef = new BMCServiceDesk__SRM_RequestDefinition__c(BMCServiceDesk__FKCategory__c=oCat.Id,BMCServiceDesk__FKBusinessService__c=oService.Id,BMCServiceDesk__FKServiceOffering__c=oOffering.Id,Name=SRName,BMCServiceDesk__serviceRequestTitle__c=SRName);
        insert reqDef;
        system.assert(reqDef.Id != null);
        
        //create a new Repair Email and envelope object
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        
        // setup the data for the email
        email.subject = 'Safeware Repair Claim';
        email.fromname = demoUser.Alias;
        email.fromAddress = 'demouseremailaddress@email.com';
        
        Test.startTest();
 
        //Instance of class
        IncomingDevice_Safeware emailProcess = new IncomingDevice_Safeware();
        user TestUsr = [select Id From User Where id=: userinfo.getUserId()];
        
        email.plainTextBody = '--Account Name: Test Account' + '<br>';
        email.plainTextBody = email.plainTextBody + '--Serial Number: 1234567' + '<br>';
        email.plainTextBody = email.plainTextBody + '--Customer Name: Redlands Christian School Attn' + '<br>';
        email.plainTextBody = email.plainTextBody + '--Customer Email Address: mwiers@redlandschristian.org' + '<br>';
        email.plainTextBody = email.plainTextBody + '--Return Address: 105 Tennessee St, , Redlands, CA, 92373' + '<br>';
        email.plainTextBody = email.plainTextBody + '--Device Type: Tablet' + '<br>';
        email.plainTextBody = email.plainTextBody + '--Device Description: ACER C740-C4PE' + '<br>';
        email.plainTextBody = email.plainTextBody + '--Device Color: Black' + '<br>';
        email.plainTextBody = email.plainTextBody + '--Problem Description: Test' + '<br>';
        email.plainTextBody = email.plainTextBody + '--Warranty Claim: Y' + '<br>';
        email.plainTextBody = email.plainTextBody + '--Service Contract Number: 1018507' + '<br>';
        email.plainTextBody = email.plainTextBody + '--Shipping Label Needed: Y' + '<br>';
        email.plainTextBody = email.plainTextBody + '--Ship Box: Y' + '<br>';
        email.plainTextBody = email.plainTextBody + '--Deductible: 1234.56' + '<br>';
        
        try{
            System.assert(demoUser.Id != null);
            system.runAs(TestUsr){

            emailProcess.handleInboundEmail(email, env);
            }
        }catch(Exception e){}
        
        //Test.stopTest();
        
        //create a new Provisioning Email and envelope object
        Messaging.InboundEmail email1 = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env1 = new Messaging.InboundEnvelope();
        
        // setup the data for the email
        email1.subject = 'Safeware Provisioning Claim';
        email1.fromname = demoUser.Alias;
        email1.fromAddress = 'demouseremailaddress@email.com';
        
        //Instance of class
        IncomingDevice_Safeware emailProcess1 = new IncomingDevice_Safeware();

        email1.plainTextBody = '--Request Type: Provisioning' + '<br>';
        email1.plainTextBody = email1.plainTextBody + '--Device Quantity: 3' + '<br>';
        email1.plainTextBody = email1.plainTextBody + '--Account Name: Test Account' + '<br>';
        email1.plainTextBody = email1.plainTextBody + '--Customer Name: Redlands Christian School Attn' + '<br>';
        email1.plainTextBody = email1.plainTextBody + '--EndUser First Name: John' + '<br>';
        email1.plainTextBody = email1.plainTextBody + '--EndUser Last Name: Doe' + '<br>';
        email1.plainTextBody = email1.plainTextBody + '--Customer Email Address: customer@redlandschristian.org' + '<br>';
        email1.plainTextBody = email1.plainTextBody + '--Manager Email Address: manager@redlandschristian.org' + '<br>';
        email1.plainTextBody = email1.plainTextBody + '--Return Address: 105 Tennessee St, , Redlands, CA, 92373' + '<br>';
        email1.plainTextBody = email1.plainTextBody + '--Problem Description: Test' + '<br>';
        email1.plainTextBody = email1.plainTextBody + '--Service Contract Number: 1018507' + '<br>';
        
        try{
            System.assert(demoUser.Id != null);
            system.runAs(TestUsr){
            //Calling method
            emailProcess1.handleInboundEmail(email1, env1);
            }
        }catch(Exception e){}
        

        //create a new Sanitation Email and envelope object
        Messaging.InboundEmail email2 = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env2 = new Messaging.InboundEnvelope();
        
        // setup the data for the email
        email2.subject = 'Safeware Sanitation Claim';
        email2.fromname = demoUser.Alias;
        email2.fromAddress = 'demouseremailaddress@email.com';
        
        //Instance of class
        IncomingDevice_Safeware emailProcess2 = new IncomingDevice_Safeware();

        email2.plainTextBody = '--Request Type: Sanitation' + '<br>';
        email2.plainTextBody = email2.plainTextBody + '--Device Quantity: 3' + '<br>';
        email2.plainTextBody = email2.plainTextBody + '--Account Name: Test Account' + '<br>';
        email2.plainTextBody = email2.plainTextBody + '--Customer Name: Redlands Christian School Attn' + '<br>';
        email1.plainTextBody = email1.plainTextBody + '--EndUser First Name: John' + '<br>';
        email1.plainTextBody = email1.plainTextBody + '--EndUser Last Name: Doe' + '<br>';
        email2.plainTextBody = email2.plainTextBody + '--Customer Email Address: customer@redlandschristian.org' + '<br>';
        email2.plainTextBody = email2.plainTextBody + '--Manager Email Address: manager@redlandschristian.org' + '<br>';
        email2.plainTextBody = email2.plainTextBody + '--Return Address: 105 Tennessee St, , Redlands, CA, 92373' + '<br>';
        email2.plainTextBody = email2.plainTextBody + '--Problem Description: Test' + '<br>';
        email2.plainTextBody = email2.plainTextBody + '--Service Contract Number: 1018507' + '<br>';
        
        try{
            System.assert(demoUser.Id != null);
            system.runAs(TestUsr){

            emailProcess2.handleInboundEmail(email2, env2);
            }
        }catch(Exception e){}

        
        Test.stopTest();

    }
}