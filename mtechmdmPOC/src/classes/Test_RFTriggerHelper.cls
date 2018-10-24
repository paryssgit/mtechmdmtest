@isTest(seeAllData=false)
public class Test_RFTriggerHelper {
    public static BMCServiceDesk__CMDB_Class__c oDeviceAsset;
    
    static testmethod void UnitTest1(){

    //Create Contract
    	MTech_Contract__c oContract = new MTech_Contract__c();
    	
        oContract.Name = '17000000';
    	oContract.IsActive__c = true;
        oContract.Contract_Start_Date__c = Date.newInstance(2017,01,01); //2017-01-01;
        oContract.Contract_End_Date__c = Date.newInstance(2018,12,31); //2017-12-31;
        
        insert oContract;
        
        system.assert(oContract != null);
        
        MTech_Contract__c oContract1 = new MTech_Contract__c();
        oContract1.Name = '17000001';
    	oContract1.IsActive__c = true;
        oContract1.Contract_Start_Date__c = Date.newInstance(2017,01,01); //2017-01-01;
        oContract1.Contract_End_Date__c = Date.newInstance(2018,12,31); //2017-12-31;
        
        insert oContract1;
        
        system.assert(oContract1 != null);
            
    	//Create Device class in CMDB
        oDeviceAsset = new BMCServiceDesk__CMDB_Class__c(BMCServiceDesk__ClassName__c = 'Device', BMCServiceDesk__CMDBClassType__c='Asset',BMCServiceDesk__SuperClass__c='BMC_BaseElement', BMCServiceDesk__Namespace__c='BMC');
        insert oDeviceAsset;
        
        system.assert(oDeviceAsset != null);
        
        //Create Device in CMDB and link it to MTech Contract
        BMCServiceDesk__BMC_BaseElement__c TestDevice = new BMCServiceDesk__BMC_BaseElement__c();
        
        TestDevice.BMCServiceDesk__Name__c = 'TestSR1234'; //Instance Name
        TestDevice.Name = 'TestSR1234';
        TestDevice.BMCServiceDesk__SerialNumber__c = 'TestSR1234'; //Serial #
        TestDevice.BMCServiceDesk__CMDB_Class__c = oDeviceAsset.id;    // Class
        TestDevice.BMCServiceDesk__Model__c = 'iPhone 7inch display';  //Device Description
        TestDevice.Color__c = 'Gold'; //Color
        TestDevice.Device_Type__c = 'iPhone'; //Device Type
        TestDevice.MTech_Contract_Number__c = oContract.Id; //MTech Contract
        
        insert TestDevice;
    	
        system.assertNotEquals(null,TestDevice);
        System.debug('---Test (TestDevice): '+TestDevice.Id+' , '+TestDevice.Name+' , '+TestDevice.MTech_Contract_Number__c);
        
        //Create Device in CMDB and link it to MTech Contract
        BMCServiceDesk__BMC_BaseElement__c TestDevice1 = new BMCServiceDesk__BMC_BaseElement__c();
        
        TestDevice1.BMCServiceDesk__Name__c = 'TestSR5678'; //Instance Name
        TestDevice1.Name = 'TestSR5678';
        TestDevice1.BMCServiceDesk__SerialNumber__c = 'TestSR5678'; //Serial #
        TestDevice1.BMCServiceDesk__CMDB_Class__c = oDeviceAsset.id;    // Class
        TestDevice1.BMCServiceDesk__Model__c = 'iPhoneX 7inch display';  //Device Description
        TestDevice1.Color__c = 'Gold'; //Color
        TestDevice1.Device_Type__c = 'iPhone'; //Device Type
        TestDevice1.MTech_Contract_Number__c = oContract1.Id; //MTech Contract
        
        insert TestDevice1;
    	
        system.assertNotEquals(null,TestDevice1);
        System.debug('---Test (TestDevice1): '+TestDevice1.Id+' , '+TestDevice1.Name+' , '+TestDevice1.MTech_Contract_Number__c);

        Test.startTest();
    	//Create Task1
        BMCServiceDesk__Task__c newTask1 = new BMCServiceDesk__Task__c();
        //newTask.BMCServiceDesk__FKIncident__c = oInc.id;
        newTask1.Configuration_Item__c = TestDevice.Id;
        newtask1.BMCServiceDesk__taskDescription__c = 'Test Task Desc';
        newtask1.OwnerId = UserInfo.getUserId();
        
        insert newTask1;
        
        
        //Create Task2
        BMCServiceDesk__Task__c newTask2 = new BMCServiceDesk__Task__c();
        //newTask.BMCServiceDesk__FKIncident__c = oInc.id;
        newTask2.Configuration_Item__c = null;
        newtask2.BMCServiceDesk__taskDescription__c = 'Test Task Desc';
        //newTask2.Previous_MTech_Contract_Id__c = String.valueOf(TestDevice.Id);
        newtask2.OwnerId = UserInfo.getUserId();
        
        insert newTask2;
        
        
        //Update Task
        BMCServiceDesk__Task__c newTask3 = new BMCServiceDesk__Task__c();
        newTask3.Id = newTask2.Id;
        newTask3.Configuration_Item__c = TestDevice1.Id;
        
        update newTask3;
        
        //Update Task
        BMCServiceDesk__Task__c newTask4 = new BMCServiceDesk__Task__c();
        newTask4.Id = newTask1.Id;
        newTask4.Configuration_Item__c = null;
        
        update newTask4;
        Test.stopTest();

    }

}