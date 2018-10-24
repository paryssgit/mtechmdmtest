public class MultiDeviceHelper {

	public string SRId;
    public string csvAsString{get;set;}
    public string[] csvFileLines{get;set;}

    public MultiDeviceHelper(string newSRId)
    {
        SRId = newSRId;
    }
    
    public void ReadAttachment()
    {
        List<Attachment> oAttach= new List<Attachment>();
        List<MTech_Devices__c> MTDs = new List<MTech_Devices__c>();
        
        
        csvFileLines = new String[]{};
        System.Debug('****SRId: '+ SRId);
                
        //Read Attachment
        //MTech_Devices__c MTD = new MTech_Devices__c();
            
        oAttach = [SELECT Id, Name, OwnerId, ParentId, Body FROM Attachment where ParentId =: SRId];
        csvAsString = EncodingUtil.base64Encode(oAttach[0].Body);
                
        csvFileLines=csvAsString.split('\n');
        //System.Debug('----Attachment Rows: '+ csvFileLines.size());

        //Create records in MTech_Devices__c
        for(integer i=1;i<csvFileLines.size();i++)
        {
            string[] csvRecordData = csvFileLines[i].split(',');
            //Check if Serial # exists in CMDB
            
            if(csvRecordData.size()>0){
                MTech_Devices__c MTD = new MTech_Devices__c();
                MTD.Name = csvRecordData[0];
                MTD.Serial_Number__c = csvRecordData[0];
                MTD.Customer_Name__c = csvRecordData[1];
                MTD.Device_Type__c = csvRecordData[2];
                MTD.Device_Description__c = csvRecordData[3];
                MTD.Device_Color__c = csvRecordData[4];
                MTD.Problem_Description__c = csvRecordData[5];
                MTD.Warranty_Claim__c = true;
                MTD.SR_Number__c = SRId;
                
                MTDs.add(MTD);
                System.Debug('----New Device added');
            }
        }
        insert MTDs;
    }
    
	public void CreateDevices()
    {
        List<MTech_Devices__c> MTechDvs = new List<MTech_Devices__c>();
        List<MTech_Devices__c> newMTechDvs = new List<MTech_Devices__c>();
        BMCServiceDesk__BMC_BaseElement__c newDevice = new BMCServiceDesk__BMC_BaseElement__c();
        
        //Get Class Id for 'MTech_Devices'    
    	BMCServiceDesk__CMDB_Class__c MTechClass = new BMCServiceDesk__CMDB_Class__c ();
    	MTechClass = [SELECT Id, Name FROM BMCServiceDesk__CMDB_Class__c WHERE BMCServiceDesk__ClassName__c = 'MTech_Devices'];

        List<BMCServiceDesk__BMC_BaseElement__c> CheckDevice = new List<BMCServiceDesk__BMC_BaseElement__c>();
        
        MTechDvs = [Select Id,Serial_Number__c,Device_Type__c,Device_Description__c,Device_Color__c,Problem_Description__c from MTech_Devices__c WHERE SR_Number__c=:SRId];
            
        //Check if Serial # exists in CMDB
        for(MTech_Devices__c md : MTechDvs){
                
        CheckDevice = [Select id, BMCServiceDesk__Name__c from BMCServiceDesk__BMC_BaseElement__c where BMCServiceDesk__SerialNumber__c=:md.Serial_Number__c];
        if(CheckDevice.isEmpty()){
            System.Debug('----Creating New Device in CMDB');
            //--Create new Device with Serial#
            newDevice.BMCServiceDesk__Name__c = md.Serial_Number__c;  //Serial #
            newDevice.BMCServiceDesk__SerialNumber__c = md.Serial_Number__c;  //Serial #
            newDevice.BMCServiceDesk__CMDB_Class__c = MTechClass.id;
            newDevice.BMCServiceDesk__Model__c = md.Device_Description__c; //Device Description
            newDevice.Color__c = md.Device_Color__c; //Color
            newDevice.Device_Type__c = md.Device_Type__c; //Device Type
            
            newMTechDvs.add(md);
            System.Debug('----New Device added');
            }
        }
        if (newMTechDvs.size()>0)
            insert newMTechDvs;
        
        CreateLinkTasks(MTechDvs);
    }
    
    public void CreateLinkTasks(List<MTech_Devices__c> MDev)
    {
        List<BMCServiceDesk__Task__c> newTasks = new List<BMCServiceDesk__Task__c>();
        for(MTech_Devices__c md : MDev)
        {
            //Create Tasks
            BMCServiceDesk__Task__c aTask = new BMCServiceDesk__Task__c();
        	
            aTask.BMCServiceDesk__FKIncident__c = md.id;
        	aTask.Configuration_Item__c = md.Serial_Number__c;
        	//newtask.Repair_Service__c = csvRecordData[5];
        	aTask.BMCServiceDesk__taskDescription__c = md.Problem_Description__c;
        	aTask.OwnerId = UserInfo.getUserId();
            
            newTasks.add(aTask);
        }
        insert newTasks;
    }
}