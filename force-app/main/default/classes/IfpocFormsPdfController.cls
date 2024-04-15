public without sharing class IfpocFormsPdfController {
    
    public String recordId { get; set; }
    public Map<String, Map<String, String>> attachmentMap { get; set; }
    public String context { get; set; }
    public List<P1_Project_Proposal__c> recordFields { get; set; }
    //public List<Work_Plan__c> workPlanData { get; set; }
    public boolean isP1ProjectProposal{ get; set; }
    
    private static Map<String, Schema.SObjectField> fieldMap = new Map<String, Schema.SObjectField>();
    public IfpocFormsPdfController() {
        recordId = ApexPages.currentPage().getParameters().get('id');
        context = ApexPages.currentPage().getParameters().get('context');
        System.debug('Context =>'+context);
        if(context == 'P1 Project Proposal'){
            List<Custom_File__c> customFileList = [Select Id, Name, P1_Project_Proposal__c, Attachment_Id__c, Rich_Text__c From Custom_File__c Where P1_Project_Proposal__c =: recordId];
            attachmentMap = new Map<String, Map<String, String>>();
            
            for(Custom_File__c cf : customFileList){
                String attachmentUrl = getRelatedFilesByRecordId(cf.Attachment_Id__c, URL.getOrgDomainURL().toExternalForm());
                Map<String, String> fileDetails = new Map<String, String>();
                fileDetails.put('attachmentUrl', attachmentUrl.replace('salesforce.com','site.com'));
                if(String.isNotBlank(cf.Rich_Text__c)){
                    fileDetails.put('richText', cf.Rich_Text__c);
                }else{
                    fileDetails.put('richText', '');
                }
                attachmentMap.put(cf.Name, fileDetails);
            }
            System.debug('attachmentMap ' + attachmentMap);
            recordFields =	database.query(buildP1PrposalQuery(' WHERE ID =: recordId'));
            isP1ProjectProposal = true;
            String myGeneratedFile = 'P1ProjectProposal.pdf';
            ApexPages.currentPage().getHeaders().put('content-disposition', 'inline; filename='+myGeneratedFile);
            System.debug('recordFields =>'+recordFields);
        }
    }
    private static String getRelatedFilesByRecordId(String attachmentId, String origin) {
        String baseUrl = origin;
        String attachmentUrl = baseUrl + '/GrantmakingPortal/servlet/servlet.FileDownload?file='+attachmentId;
        return attachmentUrl;
    }
    
    public Boolean isDemoRichText1Present {
        get {
            return attachmentMap.containsKey('Demo_Rich_Text__c');
        }
    }
    
    public Boolean isDemoRichText2Present {
        get {
            return attachmentMap.containsKey('Demo_Rich_Text_2__c');
        }
    }

    
    public static String buildP1PrposalQuery(String whereCondition){
        Schema.SObjectType sobjectTypeObj = Schema.getGlobalDescribe().get('P1_Project_Proposal__c');
        Schema.DescribeSObjectResult obj = sobjectTypeObj.getDescribe(); 
        String sObjName = sobjectTypeObj.getDescribe().getName();
        fieldMap = Schema.getGlobalDescribe().get(sObjName).getDescribe().fields.getMap();
        Set<String> SobjectFields = fieldMap.keySet();
        List<String> fieldsInList = new List<String>(SobjectFields);
        return 'SELECT ' + String.join(fieldsInList, ',') + ' FROM '+ sObjName + ' ' + whereCondition;
    }
}