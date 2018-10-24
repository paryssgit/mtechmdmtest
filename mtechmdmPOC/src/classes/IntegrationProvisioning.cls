@RestResource(urlMapping='/CreateProvisioningOrder/*')

global class IntegrationProvisioning {
    @HttpPost
    global static String CreateProvisioningSRTask(){
        String response;
        String request = RestContext.request.requestBody.toString();
        String strContentType = RestContext.request.headers.get('Content-Type') ;

        System.debug('Request: '+request);

        try{
            if(strContentType.contains('xml'))
                response = serializeXML(request);
            else if(strContentType.contains('json'))
                response = serializeJSON(request);
        }
        catch(Exception e){
            response='Error: '+e.getMessage();
        }
        return response;
    }
    
    public class DataWrapper{

        public string Account_Name;
        public string Device_Quantity;
        public string Customer_Name;
        public string Customer_Email;
        public string Contact_FName;
        public string Contact_LName;
        public string Manager_Email;
        public string Phone;
        public string Shipping_Address;
        public string Problem_Description;
        public string Purchase_Order;

       	//public DataWrapper(){}
    }
    
    //Content_Type = XML
    public static string serializeXML(string sRrequest){       
        
        DataWrapper oWrapper = new DataWrapper();
        string xmlString = sRrequest;
        Dom.Document doc = new DOM.Document();
        doc.load(xmlString);
        DOM.XmlNode ProvisioningNode = doc.getRootElement();

        list<WS_CreateProvisioningOrder__mdt> WSmdt = new list<WS_CreateProvisioningOrder__mdt>([Select Id,Label from WS_CreateProvisioningOrder__mdt]);
        
        //if(rootNode.getNodeType()==DOM.XmlNodeType.ELEMENT){
            for(DOM.XmlNode child: ProvisioningNode.getChildElements()){
                system.debug('***Node Name: '+child.getName()+' , '+child.getText().Trim());
                
                if(child.getName()=='Phone'){
                    oWrapper.Phone= child.getText().Trim(); 
                    system.debug('***oWrapper.Phone: '+oWrapper.Phone);
                }
                    
                if(child.getName()=='Account_Name'){
                    oWrapper.Account_Name= child.getText().Trim();
                    system.debug('***oWrapper.Account_Name: '+oWrapper.Account_Name);
                }

                if(child.getName()=='Purchase_Order'){
                    oWrapper.Purchase_Order= child.getText().Trim();
                	system.debug('***oWrapper.Purchase_Order: '+oWrapper.Purchase_Order);
                }

                if(child.getName()=='Shipping_Address'){
                    oWrapper.Shipping_Address= child.getText().Trim();
                	system.debug('***oWrapper.Shipping_Address: '+oWrapper.Shipping_Address);
                }
                
                if(child.getName()=='Device_Quantity'){
                    oWrapper.Device_Quantity= child.getText().Trim();
                	system.debug('***oWrapper.Device_Quantity: '+oWrapper.Device_Quantity);
                }
                
                if(child.getName()=='Problem_Description'){
                    oWrapper.Problem_Description= child.getText().Trim();
                	system.debug('***oWrapper.Problem_Description: '+oWrapper.Problem_Description);
                }
                
                if(child.getName()=='Customer_Email'){
                    oWrapper.Customer_Email= child.getText().Trim();
                	system.debug('***oWrapper.Customer_Email: '+oWrapper.Customer_Email);
                }
                
                if(child.getName()=='Contact_FName'){
                    oWrapper.Contact_FName= child.getText().Trim();
                	system.debug('***oWrapper.Contact_FName: '+oWrapper.Contact_FName);
                }
                
                if(child.getName()=='Contact_LName'){
                    oWrapper.Contact_LName= child.getText().Trim();
                	system.debug('***oWrapper.Contact_LName: '+oWrapper.Contact_LName);
                }
                
                if(child.getName()=='Manager_Email'){
                    oWrapper.Manager_Email= child.getText().Trim();
                	system.debug('***oWrapper.Manager_Email: '+oWrapper.Manager_Email);
                }
                
                if(child.getName()=='Customer_Name'){
                    oWrapper.Customer_Name= child.getText().Trim();
                	system.debug('***oWrapper.Customer_Name: '+oWrapper.Customer_Name);       
            	}
     		}
            //}
        
        return CreateSRTasks(oWrapper);
    }
    
    //Content_Type = JSON
    public static string serializeJSON(string sRequest){
		system.debug('***Inside serializeJSON');
        System.debug('sRequest - '+ sRequest );
        
        system.debug('***deserialize: '+(DataWrapper) System.JSON.deserialize(sRequest, DataWrapper.class));
		DataWrapper oWrapper =   (DataWrapper) System.JSON.deserialize(sRequest, DataWrapper.class);

        system.debug('======oWrapper.Account_Name: '+oWrapper.Account_Name);
        return CreateSRTasks(oWrapper);
    }
    
    //Create Service Request and Tasks
    private static string CreateSRTasks(DataWrapper oSRData){
        System.debug('***Entry CreateSRTasks');
        string UserId;
        string REQDEFNAME = 'WebService_Provisioning';
        string TaskQueueId;
		BMCServiceDesk__Incident__c SR = new BMCServiceDesk__Incident__c();
        
        try{
            list<User> usr = [Select Id from User where username = 'integrationuser@mtechmdm.com'];
            if(usr.size() > 0)
                UserId = usr[0].Id;
            
            system.debug('***oSRData.Account_Name: '+oSRData.Account_Name);
            List<Account> Ac = [Select Id from Account where Name =: oSRData.Account_Name];
            if(Ac.size() < 1)
                return 'Error: Account does not exist. Please Contact MTech Support for more information.';
            
            TaskQueueId = String.valueOf([Select Id,QueueId,Queue.Name From QueueSobject Where SobjectType='BMCServiceDesk__Task__c' and  Queue.Name = 'Warehouse'].QueueId);
            
            //Create Request Detail
            BMCServiceDesk__SRM_RequestDefinition__c reqDef = [Select Id,BMCServiceDesk__FKCategory__c,BMCServiceDesk__FKBusinessService__c,BMCServiceDesk__FKServiceOffering__c from BMCServiceDesk__SRM_RequestDefinition__c where Name =: REQDEFNAME];
            System.debug('***reqDef - '+reqDef.Id);
            System.debug('***userId - '+userId);
            BMCServiceDesk__SRM_RequestDetail__c oRD = new BMCServiceDesk__SRM_RequestDetail__c(
                BMCServiceDesk__FKClient__c = Id.valueOf(UserId),
                BMCServiceDesk__FKRequestDefinition__c = reqDef.Id,
                BMCServiceDesk__ServiceRequest__c = REQDEFNAME,
                BMCServiceDesk__ApprovalRequired__c = false
            );
            insert oRD;
            System.debug('***CreateSRTasks: Request Detail \''+ oRD.Id +'\' created');
            
            //Create Provisioning Service Request
            SR.Client_Phone__c=oSRData.Phone;
            SR.Purchase_Order__c=oSRData.Purchase_Order;
            SR.Shipping_Address__c=oSRData.Shipping_Address;
            SR.Problem_Description__c=oSRData.Problem_Description;
            SR.Client_Phone__c=oSRData.Customer_Name;
            SR.Client_Phone__c=oSRData.Customer_Email;
            SR.Client_Phone__c=oSRData.Manager_Email;
            SR.Repair_Customer_Name__c=oSRData.Customer_Name;    
            SR.Account_Name__c = Ac[0].Id;
            
            //SR.BMCServiceDesk__FKCategory__c = reqDef.BMCServiceDesk__FKCategory__c;
            SR.BMCServiceDesk__FKBusinessService__c = reqDef.BMCServiceDesk__FKBusinessService__c;
            SR.BMCServiceDesk__FKRequestDefinition__c = reqDef.Id;
            SR.BMCServiceDesk__FKServiceOffering__c = reqDef.BMCServiceDesk__FKServiceOffering__c;
            SR.BMCServiceDesk__FKRequestDetail__c = oRD.Id;
                
            insert SR;
            System.debug('***CreateSRTasks: Service Request \''+ SR.Id +'\' created');
            
            //Update Request Detail with SR number
            BMCServiceDesk__SRM_RequestDetail__c updateRD = [Select BMCServiceDesk__FKIncident__c from BMCServiceDesk__SRM_RequestDetail__c where id =: oRD.id];
            updateRD.BMCServiceDesk__FKIncident__c = SR.id;
            update updateRD;
            
            //Create Tasks and link it to SR
            List<BMCServiceDesk__Task__c> SRTasks = new List<BMCServiceDesk__Task__c>();
            
            if(Integer.valueOf(oSRData.Device_Quantity)>0){
                for(Integer i=0;i<Integer.valueOf(oSRData.Device_Quantity);i++){
                    BMCServiceDesk__Task__c aTask = new BMCServiceDesk__Task__c();
                    
                    aTask.BMCServiceDesk__FKIncident__c = SR.Id;
                    aTask.RFIncident__c = SR.Id;
                    aTask.Problem_Description__c = 'Blank Task';
                    aTask.Task_Status__c = 'Receiving';
                    aTask.Account_Name__c = oSRData.Account_Name;
                    aTask.Received_Date__c = system.today(); 
                    aTask.BMCServiceDesk__openDateTime__c = system.today(); 
                    aTask.Service_Customer_Name__c = oSRData.Customer_Name;
                    aTask.OwnerId = Id.valueOf(TaskQueueId);
                    aTask.Purchase_Order_Number__c = oSRData.Purchase_Order;
                
                    SRTasks.add(aTask);
                }
            }
            insert SRTasks;
            
            System.debug('***CreateSRTasks: '+ oSRData.Device_Quantity+' Task(s) created.');
        }
        catch(Exception e){
            return 'Error: '+e.getMessage();
        }
        return 'Service Request Created: '+SR.Id;
    }
}