global class IncomingDevice_Safeware implements Messaging.InboundEmailHandler{

    //List to store all lines of the email body
    public static list<String> AllLines;    

    public string sFromEmail;
    public String sBody;
    public String sSubject;
    public string TaskQueueId;
    
    public static string REQDEFNAME = 'Incoming Single Device Request';
    //public string SAFEWAREUSERNAME = 'claims@safeware.com';
        
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope env){
        //Create an inboundEmailResult object for returning the result of email service.
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();

        //Add the email plain text into the local variable
        sBody = email.plainTextBody != null ? email.plainTextBody : email.htmlBody;
            
        //Add the email from Address text into the local variable
        sFromEmail = email.fromAddress;
    
        //Add the email subject into the local variable
        sSubject = email.subject;

        TaskQueueId = String.valueOf([Select Id,QueueId,Queue.Name From QueueSobject Where SobjectType='BMCServiceDesk__Task__c' and  Queue.Name = 'Warehouse'].QueueId);
        
        if(sSubject==Label.SAFEWARE_REPAIR_REQUEST_SUBJECT)
            ProcessRepairRequest(sFromEmail,sSubject,sBody,TaskQueueId);
        else if(sSubject==Label.SAFEWARE_PROVISIONING_REQUEST_SUBJECT || sSubject==Label.SAFEWARE_SANITATION_REQUEST_SUBJECT)
            ProcessProvisioningRequest(sFromEmail,sSubject,sBody,TaskQueueId);
        
        // Set the result to true.
        result.success = true;

        // Return the result for the  Email Service
        return result;
    }
    
    public static void ProcessRepairRequest(String sFromEmail,String sSubject,String sBody,String TaskQueueId){
        string AccountName;
        string AccountId;
        string UserId;
        string sLogs = '';
        string tempLine;

        string SerialNumber;
        string CustomerName;
        string CustomerEmail;
        string ReturnAddress;
        string DeviceType;
        string DeviceDesc;
        string DeviceColor;
        string ProbDesc;
        boolean WarrantyClaim;
        string ContractNumber;
        string ServiceContractNumber;
        boolean ShipLableNeeded;
        boolean ShipBox;
        String sDeductible;
        
        AllLines = new list<String>();
        //Incoming email will be in text format. Email Body lines are separated by '<br>'
        AllLines = sBody.split('<br>');
        System.debug('***AllLines - '+AllLines);
        
        User[] usr = [Select Id,BMCServiceDesk__Account_ID__c,BMCServiceDesk__Account_Name__c from User where username =: sFromEmail];
        if(usr.size() > 0){
            AccountName = usr[0].BMCServiceDesk__Account_Name__c;
            UserId = usr[0].Id;
            sLogs = sLogs + 'AccountName='+AccountName+',UserId='+UserId;
            System.debug('***sLogs1='+sLogs);
        }
        else{
            sLogs = sLogs + 'ERROR: User ' + sFromEmail + 'does not exist in Remedyforce';
            System.debug('***sLogs1='+sLogs);

            return;
        }
        
        for(String line : AllLines){
            if( line.contains('Account Name:'))
                AccountName =  usr[0].BMCServiceDesk__Account_Name__c;
            
            if( line.contains('Serial Number:')){
                SerialNumber = line.SubStringAfter(':').trim();
                
                if(SerialNumber.length()>24)
                    SerialNumber=SerialNumber.mid(0,24);
            }

            if( line.contains('Customer Name:')){
                CustomerName = line.SubStringAfter(':').trim();
                
                if(CustomerName.length()>254)
                    CustomerName=CustomerName.mid(0,254);
            }
            
            if( line.contains('Customer Email Address:'))
                CustomerEmail = line.SubStringAfter(':').trim();
            
            if( line.contains('Return Address:')){
                ReturnAddress = line.SubStringAfter(':').trim();

                if(ReturnAddress.length()>254)
                    ReturnAddress = ReturnAddress.mid(0,254);
            }
            
            if( line.contains('Device Type:'))
                DeviceType = line.SubStringAfter(':').trim();
            
            if( line.contains('Device Description:')){
                DeviceDesc = line.SubStringAfter(':').trim();
                
                if(DeviceDesc.length()>49)
                    DeviceDesc = DeviceDesc.mid(0,49);
            }
            
            if( line.contains('Device Color:'))
                DeviceColor = line.SubStringAfter(':').trim();
            
            if( line.contains('Problem Description:'))
                ProbDesc = line.SubStringAfter(':').trim();
            
            if( line.contains('Warranty Claim:')) {
                tempLine = line.SubStringAfter(':').trim();
                if(tempLine.trim()=='Y')
                    WarrantyClaim = true;
                else
                    WarrantyClaim = false;
            }
            
            if( line.contains('Service Contract Number:')){
                ServiceContractNumber = line.SubStringAfter(':').trim();
            
                if (ServiceContractNumber.length()>19)
                    ServiceContractNumber = ServiceContractNumber.mid(0,19);
            }
            
            if( line.contains('Shipping Label Needed:')){
                tempLine = line.SubStringAfter(':').trim();
            
                if(tempLine.trim()=='Y')
                    ShipLableNeeded = true;
                else
                    ShipLableNeeded = false;
            }

            if( line.contains('Ship Box:')){
                tempLine = line.SubStringAfter(':').trim();
                
                if(tempLine.trim()=='Y')
                    ShipBox = true;
                else
                    ShipBox = false;
            }
            
            if( line.contains('Deductible:'))
                sDeductible = line.SubStringAfter(':').trim();
        }
        
        sLogs = sLogs + ',SerialNumber='+SerialNumber+',CustomerName='+CustomerName+',CustomerEmail='+CustomerEmail+',DeviceType='+DeviceType+',DeviceColor='+DeviceColor+',WarrantyClaim='+tempLine.trim()+' ,ServiceContractNumber='+ServiceContractNumber+', ShipLableNeeded='+ String.valueOf(ShipLableNeeded)+', ShipBox='+String.valueOf(ShipBox);
        System.debug('***sLogs2='+sLogs);
        
        //Create SR
        BMCServiceDesk__SRM_RequestDefinition__c reqDef = [Select Id,BMCServiceDesk__FKCategory__c,BMCServiceDesk__FKBusinessService__c,BMCServiceDesk__FKServiceOffering__c from BMCServiceDesk__SRM_RequestDefinition__c where Name =: REQDEFNAME];
        System.debug('***reqDef - '+reqDef.Id);
        System.debug('***userId - '+userId);
        //Create Request Detail
        BMCServiceDesk__SRM_RequestDetail__c oRD = new BMCServiceDesk__SRM_RequestDetail__c(
            BMCServiceDesk__FKClient__c = Id.valueOf(UserId),   //userinfo.getUserId(),
            BMCServiceDesk__FKRequestDefinition__c = reqDef.Id,
            BMCServiceDesk__ServiceRequest__c = REQDEFNAME,
            BMCServiceDesk__ApprovalRequired__c = false
        );
        insert oRD;
        
        System.debug('***AccountId='+AccountId+','+'AccountName='+usr[0].BMCServiceDesk__Account_Name__c+','+'SerialNumber='+SerialNumber+','+'CustomerName='+CustomerName);
        //System.debug('AccountId='+AccountId+','+'AccountName='+AccountName+','+'SerialNumber='+SerialNumber+','+'CustomerName='+CustomerName);
        System.debug('***ReturnAddress='+ReturnAddress+','+'DeviceType='+DeviceType+','+'DeviceDesc='+DeviceDesc+','+'DeviceColor='+DeviceColor+','+'ProbDesc='+ProbDesc);
        System.debug('***WarrantyClaim='+WarrantyClaim+','+' ,ServiceContractNumber='+ServiceContractNumber+'reqDef.BMCServiceDesk__FKCategory__c='+reqDef.BMCServiceDesk__FKCategory__c+','+'reqDef.BMCServiceDesk__FKBusinessService__c='+reqDef.BMCServiceDesk__FKBusinessService__c);
        System.debug('***reqDef.Id='+reqDef.Id+','+'reqDef.BMCServiceDesk__FKServiceOffering__c='+reqDef.BMCServiceDesk__FKServiceOffering__c+','+'oRD.Id='+oRD.Id);
        System.debug('***REQDEFNAME='+REQDEFNAME+','+'CustomerEmail='+CustomerEmail+','+'TaskQueueId='+TaskQueueId);
        
        //Create Incident
        BMCServiceDesk__Incident__c oInc = new BMCServiceDesk__Incident__c(
            Account_Name__c = Id.valueOf( usr[0].BMCServiceDesk__Account_ID__c),
            SR_Serial__c = SerialNumber,
            Repair_Customer_Name__c = CustomerName,
            Shipping_Address__c = ReturnAddress,
            SR_Device_Type__c = DeviceType,
            SR_Model__c = DeviceDesc,
            SR_Color__c = DeviceColor,
            BMCServiceDesk__incidentDescription__c = ProbDesc,
            SR_Warranty__c = WarrantyClaim,
            Need_a_Shipping_Label__c = ShipLableNeeded,
            Need_a_Shipping_Label_Box__c = ShipBox,
            BMCServiceDesk__FKCategory__c = reqDef.BMCServiceDesk__FKCategory__c,
            BMCServiceDesk__FKClient__c = Id.valueOf(UserId),   //userinfo.getUserId(),
            BMCServiceDesk__FKBusinessService__c = reqDef.BMCServiceDesk__FKBusinessService__c,
            BMCServiceDesk__FKRequestDefinition__c = reqDef.Id,
            BMCServiceDesk__FKServiceOffering__c = reqDef.BMCServiceDesk__FKServiceOffering__c,
            BMCServiceDesk__FKRequestDetail__c = oRD.Id,
            BMCServiceDesk__Service_Request_Title__c = REQDEFNAME,
            BMCServiceDesk__IncidentType__c = 'Service Request',
            Repair_Customer_Email__c = CustomerEmail,
            OwnerId = TaskQueueId,
            Purchase_Order__c = ServiceContractNumber,
            Deductible__c = Decimal.valueOf(sDeductible)
        );
        insert oInc;
        System.debug('***Incident created='+oInc.Name);
        
        //Update Request Detail with Incident number
        BMCServiceDesk__SRM_RequestDetail__c updateRD = [Select BMCServiceDesk__FKIncident__c from BMCServiceDesk__SRM_RequestDetail__c where id =: oRD.id];
        updateRD.BMCServiceDesk__FKIncident__c = oInc.id;
        update updateRD;

        //Get Class Id for 'Device'    
        BMCServiceDesk__CMDB_Class__c DeviceClass = [SELECT Id FROM BMCServiceDesk__CMDB_Class__c WHERE BMCServiceDesk__ClassName__c = 'Device'];
        
        //BMCServiceDesk__BMC_BaseElement__c[] DeviceCIs = [Select id,Name,BMCServiceDesk__Name__c from BMCServiceDesk__BMC_BaseElement__c where BMCServiceDesk__SerialNumber__c =: SerialNumber];
        BMCServiceDesk__BMC_BaseElement__c[] DeviceCIs = [Select id,Name,BMCServiceDesk__Name__c from BMCServiceDesk__BMC_BaseElement__c where BMCServiceDesk__Name__c =: SerialNumber OR  MTech_Asset__c =: SerialNumber OR MTech_Serial__c =: SerialNumber OR MTech_IMEI__c =: SerialNumber];
        
        BMCServiceDesk__Task__c aTask = new BMCServiceDesk__Task__c();
        
        
        if(DeviceCIs.size() == 0)
        {
            //Create new Device in CMDB
            BMCServiceDesk__BMC_BaseElement__c BE = new BMCServiceDesk__BMC_BaseElement__c();
            
            BE.BMCServiceDesk__Name__c = SerialNumber;  //Serial #
            BE.BMCServiceDesk__SerialNumber__c = SerialNumber;  //Serial #
            BE.MTech_Asset__c = SerialNumber;  //Serial #
            BE.MTech_Serial__c = SerialNumber;  //Serial #
            BE.MTech_IMEI__c = SerialNumber;  //Serial #
            BE.BMCServiceDesk__CMDB_Class__c = DeviceClass.id;
            BE.BMCServiceDesk__Model__c = DeviceDesc; //Device Description
            BE.Color__c = DeviceColor; //Color
            BE.Device_Type__c = DeviceType; //Device Type
            
            insert BE;
            System.debug('***New Device Registered='+BE.Name);
            
            //Link newly created Configuration Item to Task
            aTask.Configuration_Item__c = BE.Id;
        }
        else{
            System.debug('***Existing Device found='+DeviceCIs[0].Name);
            //Link existing Configuration Item to Task
            aTask.Configuration_Item__c = DeviceCIs[0].Id;
        }
            
        aTask.BMCServiceDesk__FKIncident__c = oInc.Id;
        aTask.RFIncident__c = oInc.Id;
        aTask.BMCServiceDesk__taskDescription__c = ProbDesc;
        aTask.Problem_Description__c = ProbDesc;
        aTask.Task_Status__c = 'Receiving';
        aTask.Device_Color__c = DeviceColor;
        aTask.Device_Type__c = DeviceType;
        aTask.Account_Name__c = AccountName;
        aTask.Received_Date__c = system.today(); 
        aTask.BMCServiceDesk__openDateTime__c = system.today(); 
        aTask.Serial_Number_In__c = SerialNumber;
        aTask.Service_Customer_Name__c = CustomerName;
        aTask.Warranty__c = WarrantyClaim;
        aTask.Device_Description__c = DeviceDesc;
        aTask.OwnerId = Id.valueOf(TaskQueueId);
        aTask.Purchase_Order_Number__c = ServiceContractNumber;
        aTask.BMCServiceDesk__taskType__c = 'Repair';

        insert aTask;
        System.debug('***Task created='+aTask.Name);
        
        //Link Configuration Item (Device) to Task
        BMCServiceDesk__BMC_CommonCILink__c CILink = new BMCServiceDesk__BMC_CommonCILink__c();
            
            CILink.BMCServiceDesk__FKTask__c = aTask.id;
            CILink.BMCServiceDesk__CIInstance__c = aTask.Configuration_Item__c;
            CILink.BMCServiceDesk__ObjectName__c = 'Task__c';
            CILink.BMCServiceDesk__ObjectRecordID__c = 'TSK-' + aTask.id;
        
        insert CILink;
        System.debug('***Task CI link created='+CILink.Name);
    }
    
    public static void ProcessProvisioningRequest(String sFromEmail,String sSubject,String sBody,String TaskQueueId){
        string AccountName;
        string sLogs = '';
        string tempLine;

        String Quantity;
        String RequestType;
        string CustomerName;
        String ManagerEmail;
        string CustomerEmail;
        String FName;
        String LName;
        string ReturnAddress;
        string ServiceContractNumber;
        String ProbDesc;
        String Category;
        
        AllLines = new list<String>();
        //Incoming email will be in text format. Email Body lines are separated by '<br>'
        AllLines = sBody.split('<br>');
        System.debug('---AllLines - '+AllLines);
        
        for(String line : AllLines){
            if( line.contains('Account Name:'))
                AccountName =  line.SubStringAfter(':').trim();         //usr[0].BMCServiceDesk__Account_Name__c;
            
            if( line.contains('Device Quantity:'))
                Quantity =  line.SubStringAfter(':').trim();
            
            if( line.contains('Request Type:')){
                RequestType =  line.SubStringAfter(':').trim();
                
                if(RequestType=='Sanitation')
                    Category='Sanitation';
                else
                    Category='Provisioning';
            }
            
            if( line.contains('Customer Name:')){
                CustomerName = line.SubStringAfter(':').trim();
                
                if(CustomerName.length()>254)
                    CustomerName=CustomerName.mid(0,254);
            }

            if( line.contains('EndUser First Name:'))
                FName = line.SubStringAfter(':').trim();
            
           if( line.contains('EndUser Last Name:'))
                LName = line.SubStringAfter(':').trim();
            
            if( line.contains('Customer Email Address:'))
                CustomerEmail = line.SubStringAfter(':').trim();

            if( line.contains('Manager Email Address:'))
                ManagerEmail = line.SubStringAfter(':').trim();
            
            if( line.contains('Return Address:')){
                ReturnAddress = line.SubStringAfter(':').trim();

                if(ReturnAddress.length()>254)
                    ReturnAddress = ReturnAddress.mid(0,254);
            }
            
            if( line.contains('Service Contract Number:')){
                ServiceContractNumber = line.SubStringAfter(':').trim();
            
                if (ServiceContractNumber.length()>19)
                    ServiceContractNumber = ServiceContractNumber.mid(0,19);
            }
            
            if( line.contains('Problem Description:'))
                ProbDesc = line.SubStringAfter(':').trim();
        }
        
        sLogs = sLogs + ',CustomerName='+CustomerName+',CustomerEmail='+CustomerEmail +',ManagerEmail='+ManagerEmail +' ,ServiceContractNumber='+ServiceContractNumber;
        System.debug('---sLogs2='+sLogs);
        
         //Get Category Id
        Id CategoryId = [Select Id from BMCServiceDesk__Category__c where Name=:Category].Id;
        
        Id UserId = [Select Id,BMCServiceDesk__Account_ID__c,BMCServiceDesk__Account_Name__c from User where username =: sFromEmail].Id;

        Account Ac = [Select Id from Account where Name =:AccountName];
        
        Contact EmailContact;
        List<Contact> lstContacts = new List<Contact>([SELECT Id,Email,Customer_Name__c,Customer_Email__c,Manager_Email__c FROM Contact where Email=: CustomerEmail]);

        List<Contact> UpdContacts = new List<Contact>();
        if(lstContacts.size()==0){
            //Create Contact
            Contact Ct = new Contact(AccountId=Ac.Id,RFAccount__c=Ac.Id,FirstName=FName,LastName=LName,Customer_Name__c=CustomerName,Email=CustomerEmail,Customer_Email__c=CustomerEmail,Manager_Email__c=ManagerEmail);
            insert ct;
            System.debug('---New Contact Created- '+ Ct.FirstName + ' ' + Ct.LastName);
            EmailContact = ct;
        }
        else
            EmailContact = lstContacts[0];
        
        
        //Create SR
        BMCServiceDesk__SRM_RequestDefinition__c reqDef = [Select Id,BMCServiceDesk__FKCategory__c,BMCServiceDesk__FKBusinessService__c,BMCServiceDesk__FKServiceOffering__c from BMCServiceDesk__SRM_RequestDefinition__c where Name =: REQDEFNAME];
        System.debug('---reqDef - '+reqDef.Id);
        System.debug('---userId - '+userId);
        //Create Request Detail
        BMCServiceDesk__SRM_RequestDetail__c oRD = new BMCServiceDesk__SRM_RequestDetail__c(
            BMCServiceDesk__FKClient__c = UserId,   //userinfo.getUserId(),
            BMCServiceDesk__FKRequestDefinition__c = reqDef.Id,
            BMCServiceDesk__ServiceRequest__c = REQDEFNAME,
            BMCServiceDesk__ApprovalRequired__c = false
        );
        insert oRD;
        
        //System.debug('AccountName='+usr[0].BMCServiceDesk__Account_Name__c+','+','+'CustomerName='+CustomerName);
        System.debug('---ReturnAddress='+ReturnAddress+',');
        System.debug(' ,ServiceContractNumber='+ServiceContractNumber+'reqDef.BMCServiceDesk__FKCategory__c='+Category+','+'reqDef.BMCServiceDesk__FKBusinessService__c='+reqDef.BMCServiceDesk__FKBusinessService__c);
        System.debug('reqDef.Id='+reqDef.Id+','+'reqDef.BMCServiceDesk__FKServiceOffering__c='+reqDef.BMCServiceDesk__FKServiceOffering__c+','+'oRD.Id='+oRD.Id);
        System.debug('REQDEFNAME='+REQDEFNAME+','+'CustomerEmail='+CustomerEmail+','+'TaskQueueId='+TaskQueueId);
        
        //Create Incident
        BMCServiceDesk__Incident__c oInc = new BMCServiceDesk__Incident__c(
            Account_Name__c = Ac.Id,
            Device_Quantity__c = Integer.valueOf(Quantity),
            BMCServiceDesk__FKContact__c = EmailContact.Id,
            Repair_Customer_Name__c = CustomerName,
            Repair_Customer_Email__c = CustomerEmail,
            Customer_Manager_Email__c = ManagerEmail,
            Shipping_Address__c = ReturnAddress,
            BMCServiceDesk__incidentDescription__c = ProbDesc,
            BMCServiceDesk__FKCategory__c = CategoryId,
            BMCServiceDesk__FKClient__c = UserId,   //userinfo.getUserId(),
            BMCServiceDesk__FKBusinessService__c = reqDef.BMCServiceDesk__FKBusinessService__c,
            BMCServiceDesk__FKRequestDefinition__c = reqDef.Id,
            BMCServiceDesk__FKServiceOffering__c = reqDef.BMCServiceDesk__FKServiceOffering__c,
            BMCServiceDesk__FKRequestDetail__c = oRD.Id,
            BMCServiceDesk__Service_Request_Title__c = REQDEFNAME,
            BMCServiceDesk__IncidentType__c = 'Service Request',
            OwnerId = TaskQueueId,
            Purchase_Order__c = ServiceContractNumber,
            MTech_Priority__c = '1 - Urgent'
        );
        insert oInc;
        System.debug('---Incident created='+oInc.Name);
        
        //Update Request Detail with Incident number
        BMCServiceDesk__SRM_RequestDetail__c updateRD = [Select BMCServiceDesk__FKIncident__c from BMCServiceDesk__SRM_RequestDetail__c where id =: oRD.id];
        updateRD.BMCServiceDesk__FKIncident__c = oInc.id;
        update updateRD;

        List<BMCServiceDesk__Task__c> ProvTasks = new List<BMCServiceDesk__Task__c>();
        
        if(Integer.valueOf(Quantity)>0){
            for(Integer i=0;i<Integer.valueOf(Quantity);i++){
                BMCServiceDesk__Task__c aTask = new BMCServiceDesk__Task__c();
                
                aTask.BMCServiceDesk__FKIncident__c = oInc.Id;
                aTask.RFIncident__c = oInc.Id;
                //aTask.BMCServiceDesk__taskDescription__c = ProbDesc;
                aTask.Problem_Description__c = 'Blank Task';
                aTask.Task_Status__c = 'Receiving';
                aTask.Account_Name__c = AccountName;
                aTask.Received_Date__c = system.today(); 
                aTask.BMCServiceDesk__openDateTime__c = system.today(); 
                aTask.Service_Customer_Name__c = CustomerName;
                aTask.OwnerId = Id.valueOf(TaskQueueId);
                aTask.Purchase_Order_Number__c = ServiceContractNumber;
                aTask.BMCServiceDesk__taskType__c = 'Provisioning';
            
                ProvTasks.add(aTask);
                System.debug('---Task Added='+aTask.Name);
            }
        }
        insert ProvTasks;
    }
}