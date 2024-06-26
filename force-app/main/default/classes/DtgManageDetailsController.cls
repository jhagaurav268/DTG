/**
* @description       : 
* @author            : ChangeMeIn@UserSettingsUnder.SFDoc
* @group             : 
* @last modified on  : 03-26-2024
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public without sharing class DtgManageDetailsController {
    private static final Blob key = EncodingUtil.convertFromHex('00112233445566778899AABBCCDDEEFF00112233445566778899AABBCCDDEEFF');
    private static final Blob iv = EncodingUtil.convertFromHex('00112233445566778899AABBCCDDEEFF');
    private static Map<String, Schema.SObjectField> fieldMap = new Map<String, Schema.SObjectField>();
    
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getMultiSelectPicklistFieldValues(String context) {
        List<Map<String, String>> listOfPicklistMap = new List<Map<String, String>>();
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        Schema.sObjectType sObjType;
        String sObjApiName;
        if(String.isNotBlank(context)){
            switch on context {
                when 'P1 Project Proposal' {
                    sObjType = gd.get('P1_Project_Proposal__c');
                }
                when else {
                    sObjType = null;
                }
            }
        }        
        try { 
            if(sObjType != null){           
                sObjApiName = sObjType.getDescribe().getName(); 
            }               
            Schema.DescribeSObjectResult describeResult = Schema.getGlobalDescribe().get(sObjApiName).getDescribe();
            Schema.DescribeFieldResult fieldResult = describeResult.fields.getMap().get('Project_Lead_1_Degree__c').getDescribe();
            
            if (fieldResult != null && (fieldResult.getType() == Schema.DisplayType.MULTIPICKLIST)) {
                List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();                
                for (Schema.PicklistEntry picklistEntry : picklistEntries) {
                    Map<String,String> picklistMap = new Map<String,String>{
                        'label' => picklistEntry.getLabel(),
                            'value' => picklistEntry.getValue()
                            };
                                listOfPicklistMap.add(picklistMap);
                }
            }
            
        } catch (Exception ex) {
            // Handle any exceptions, such as invalid object or field API names
            System.debug('Error retrieving picklist values: ' + ex.getMessage());
        }
        return listOfPicklistMap;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getPicklistFieldValues(String context, String apiName) {
        List<Map<String, String>> listOfPicklistMap = new List<Map<String, String>>();
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        Schema.sObjectType sObjType;
        String sObjApiName;
        if(String.isNotBlank(context)){
            switch on context {
                when 'P1 Project Proposal' {
                    sObjType = gd.get('P1_Project_Proposal__c');
                }
                when else {
                    sObjType = null;
                }
            }
        }        
        try { 
            if(sObjType != null){           
                sObjApiName = sObjType.getDescribe().getName(); 
            }               
            Schema.DescribeSObjectResult describeResult = Schema.getGlobalDescribe().get(sObjApiName).getDescribe();
            Schema.DescribeFieldResult fieldResult = describeResult.fields.getMap().get(apiName).getDescribe();
            
            
            if (fieldResult != null) {
                List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();                
                for (Schema.PicklistEntry picklistEntry : picklistEntries) {
                    Map<String,String> picklistMap = new Map<String,String>{
                        'label' => picklistEntry.getLabel(),
                            'value' => picklistEntry.getValue()
                            };
                                listOfPicklistMap.add(picklistMap);
                }
            }
            
        } catch (Exception ex) {
            // Handle any exceptions, such as invalid object or field API names
            System.debug('Error retrieving picklist values: ' + ex.getMessage());
        }
        return listOfPicklistMap;
    }
    
    @AuraEnabled
    public static Map<Object,Object> upsertData(Map<String,Object> data, Id recordId, String context, Boolean isSubmit){
        try{
            Boolean isSuccess = true;
            Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
            Schema.sObjectType sObjType;
            sObject sobj;
            
            List<String> skipFields;
            
            switch on context {
                when 'P1 Project Proposal' {
                    sObjType = gd.get('P1_Project_Proposal__c');
                    sobj = sObjType.newSObject();
                    skipFields = new List<String> {'IsDeleted','Name','Total_Project_Funding__c','CreatedById'};
                        }   
                when else {}
            }
            
            Map<String, Schema.SObjectField> fieldTypeMap = sObjType.getDescribe().fields.getMap();
            
            for(String fieldName : data.keySet()){
                if(skipFields.contains(fieldName)) continue;
                Schema.SObjectField field = fieldTypeMap.get(fieldName);
                if(String.isNotblank(String.valueOf(field))){
                    Schema.DisplayType fieldDataType = field.getDescribe().getType();
                    
                    if(fieldDataType == Schema.DisplayType.Currency || fieldDataType == Schema.DisplayType.Double || fieldDataType == Schema.DisplayType.Integer || fieldDataType == Schema.DisplayType.Boolean){
                        String strValue; 
                        if(data.get(fieldName) == 0){
                            strValue = null;
                        }else{
                            strValue  = (String) data.get(fieldName);
                        }
                        
                        if(String.isNotBlank(strValue)){
                            sobj.put(fieldName, Decimal.valueOf(strValue));
                        }else{
                            sobj.put(fieldName, null);
                        }
                    }else if(Schema.DisplayType.MultiPicklist === fieldDataType || Schema.DisplayType.String == fieldDataType || Schema.DisplayType.Picklist == fieldDataType || Schema.DisplayType.TextArea == fieldDataType ||  Schema.DisplayType.URL == fieldDataType || Schema.DisplayType.PHONE == fieldDataType || Schema.DisplayType.EMAIL == fieldDataType || Schema.DisplayType.date == fieldDataType || Schema.DisplayType.Boolean == fieldDataType ){
                        sobj.put(fieldName,(String) data.get(fieldName));
                    }else if(Schema.DisplayType.Boolean == fieldDataType){
                        Boolean booleanValue  = (Boolean) data.get(fieldName);
                        sobj.put(fieldName,booleanValue);
                    }
                }
            }
            if(recordId != null){
                sobj.put('Id', recordId);
            }
            System.debug('upsert...'+sobj);
            Database.UpsertResult result = database.upsert(sobj);
            if(!result.isSuccess()) {
                isSuccess = false;
            }else{
                recordId = result.getId();
                if (result.isCreated()) {
                    if(data.containsKey('Demo_Rich_Text__c')) {
                        insertCustomFile((String)data.get('Demo_Rich_Text__c'), result.getId(), 'Demo_Rich_Text__c');
                    }
                    if(data.containsKey('Demo_Rich_Text_2__c')) {
                        insertCustomFile((String)data.get('Demo_Rich_Text_2__c'), result.getId(), 'Demo_Rich_Text_2__c');
                    }
                }
            }
            
            if(context == 'P1 Project Proposal' && isSuccess) {
                String nextCollaborator = (String)sobj.get('Next_Collaborator__c');
                if(String.isNotBlank(nextCollaborator)) {
                    String encryptedToken = encrypt(recordId);
                    sendEmail(nextCollaborator, encryptedToken);
                    if(isSubmit == true){
                        createP1ProjectProposalPDF(recordId);
                    }
                }
            }
            
            return new Map<Object,Object>{'success' => isSuccess , 'id' => recordId};
                }Catch(Exception ex){
                    System.debug(ex.getMessage());
                    return null;
                }
    }
    
    private static void insertCustomFile(String imageData, String recordId, String name) {
        System.debug('imagedata ' + imagedata);
        System.debug('recordId ' + recordId);
        Integer startIndex = imageData.indexOf('base64');
        String base64Data = '';
        if (startIndex != -1) {
            String base64Substring = imageData.substring(startIndex + 7);
            
            Integer endIndex = base64Substring.indexOf('"');
            if (endIndex != -1) {
                base64Data = base64Substring.substring(0, endIndex);
            }
        }
        String textContent = imageData.stripHtmlTags();
        Blob fileBlob = EncodingUtil.base64Decode(base64Data);
        Custom_File__c existingFile = [SELECT Id, Attachment_Id__c FROM Custom_File__c WHERE P1_Project_Proposal__c = :recordId LIMIT 1];
        
        if (existingFile != null) {
            existingFile.Rich_Text__c = imageData.stripHtmlTags();
            update existingFile;
            
            Attachment existingAttachment = [SELECT Id FROM Attachment WHERE Id = :existingFile.Attachment_Id__c];
            existingAttachment.Body = fileBlob;
            update existingAttachment;
        } else {
            Custom_File__c cf = new Custom_File__c();
            cf.P1_Project_Proposal__c = recordId;
            cf.Rich_Text__c = imageData.stripHtmlTags();
            cf.Name = name;
            
            insert cf;
            
            Attachment attachment = new Attachment();
            attachment.ParentId = cf.Id;
            attachment.Name = name + '.png'; 
            attachment.Body = fileBlob;
            attachment.ContentType = 'image/png';
            
            insert attachment;
            
            cf.Attachment_Id__c = attachment.Id;
            update cf;
        }
        
        /*Custom_File__c cf = new Custom_File__c();
        cf.P1_Project_Proposal__c = recordId;
        cf.Rich_Text__c = textContent;
        cf.Name = name;
        insert cf;
        
        Blob fileBlob = EncodingUtil.base64Decode(base64Data);

        Attachment attachment = new Attachment();
        attachment.ParentId = cf.Id;
        attachment.Name = '65.png';
        attachment.Body = fileBlob;
        attachment.ContentType = 'image/png';
        
        insert attachment;
        
        Attachment attWithSharing = [SELECT Id FROM Attachment WHERE Id = :attachment.Id];
        attWithSharing.IsPrivate = false;
        update attWithSharing;
        
        cf.Attachment_Id__c = attachment.Id;
        update cf;*/
    }
    
    @Future(callout=true)                                  
    public static void createP1ProjectProposalPDF(String p1ProjectProposalId) {
        Blob body;
        try {
            PageReference pageRef = new PageReference('https://ifpoc--dev.sandbox.my.site.com/GrantmakingPortal/apex/IFPOCformPdf?id='+p1ProjectProposalId+'&context=P1%20Project%20Proposal');
            body = pageRef.getContentAsPDF();
            
            sendEmail( p1ProjectProposalId,body);
        }catch(System.Exception ex){
            system.debug('Exception e:::'+ex);
        }
    }
    
    public static void sendEmail(string p1ProjectProposalId,blob body){    
        system.debug('body -----'+body);
        List<OrgWideEmailAddress> lstEmailAddress=[select Id from OrgWideEmailAddress WHERE Address='nandkishor@cloudsciencelabs.com'];
        
        List<String> emailAddresses = new List<String>();
        emailAddresses.add('gaurav@cloudsciencelabs.com');
        EmailTemplate et = [SELECT Id,Subject, Body FROM EmailTemplate WHERE DeveloperName = 'Notify_on_new_P1_Project_Proposal' LIMIT 1];
        String emailBody = et.Body;        
        
        Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
        efa.setFileName('p1ProjectProposal.pdf');
        efa.setBody(body);
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(emailAddresses);
        mail.setTemplateId(et.Id);
        mail.setSubject(et.Subject);
        mail.setHTMLBody(emailBody);
        mail.setFileAttachments(new Messaging.EmailFileAttachment[] {efa});
        mail.setOrgWideEmailAddressId(lstEmailAddress[0].Id);
        
        try {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
        catch(Exception ex){
            System.debug('error in send email in p1 Project Proposal======' +ex.getMessage());
        }  
    }
    
    public static String encrypt(String input) {
        Blob data = Blob.valueOf(input);
        Blob encryptedData = Crypto.encrypt('AES256', key, iv, data);
        
        String encryptedString = EncodingUtil.base64Encode(encryptedData);
        System.debug('encryptedString ' + encryptedString);
        return encryptedString;
    }
    
    private static String decrypt(String encryptedString) {
        Blob encryptedData = EncodingUtil.base64Decode(encryptedString);
        
        Blob decryptedData = Crypto.decrypt('AES256', key, iv, encryptedData);
        
        String decryptedString = decryptedData.toString();
        return decryptedString;
    }
    
    private static void sendEmail(String recipient, String encryptedToken) {
        String emailContent = 'Your encrypted token: ' + encryptedToken;
        List<OrgWideEmailAddress> lstEmailAddress=[select Id from OrgWideEmailAddress WHERE Address='nandkishor@cloudsciencelabs.com'];
        
        Messaging.SingleEmailMessage mymail = new Messaging.SingleEmailMessage();
        String[] toaddresses = new String[] {recipient}; 
            
            mymail.setToAddresses(toAddresses);
        mymail.setSubject('Here is you token as a next collaborator');
        mymail.setPlainTextBody(emailContent);
        mymail.setHtmlBody(emailContent);
        mymail.setOrgWideEmailAddressId(lstEmailAddress[0].Id);
        
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mymail });
    }
    
    /*@AuraEnabled(cacheable=true)
    public static List<ContentDocument> getRelatedFiles(Id loiId) {
        List<ContentDocument> files = new List<ContentDocument>();
        for(ContentDocumentLink link : [SELECT ContentDocumentId, ContentDocument.Title 
        FROM ContentDocumentLink 
        WHERE LinkedEntityId = :loiId]) {
        files.add(new ContentDocument(Id = link.ContentDocumentId, Title = link.ContentDocument.Title));
        }
        return files;
    }*/
    @AuraEnabled(cacheable=true)
    public static List<ContentDocument> getRelatedFiles(Id loiId) {
        List<ContentDocument> files = new List<ContentDocument>();
        
        List<ContentDocumentLink> contentDocumentLinks = [SELECT ContentDocumentId, ContentDocument.Title
                                                          FROM ContentDocumentLink
                                                          WHERE LinkedEntityId = :loiId];
        
        Set<Id> contentDocumentIds = new Set<Id>();
        for (ContentDocumentLink link : contentDocumentLinks) {
            contentDocumentIds.add(link.ContentDocumentId);
        }
        
        List<ContentDocument> relatedContentDocuments = [SELECT Id, Title FROM ContentDocument WHERE Id IN :contentDocumentIds];
        
        files.addAll(relatedContentDocuments);
        
        return files;
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<Object,Object> fetchRecordDetails(Map<String, Object> filter, String context, String origin){
        try {
            switch on context {
                when 'P1 Project Proposal' {
                    string token = (String) filter.get('token');
                    Id recordId = (Id) decrypt(token);
                    List<Custom_File__c> customFileList = [Select Id, Name, P1_Project_Proposal__c, Attachment_Id__c, Rich_Text__c From Custom_File__c Where P1_Project_Proposal__c =: recordId];
                    System.debug('customFileList size ' + customFileList.size());
                    
                    Map<String, Map<String, String>> attachmentMap = new Map<String, Map<String, String>>();
                    
                    for(Custom_File__c cf : customFileList){
                        String attachmentUrl = getRelatedFilesByRecordId(cf.Attachment_Id__c, origin);
                        Map<String, String> fileDetails = new Map<String, String>();
                        fileDetails.put('attachmentUrl', attachmentUrl.replace('salesforce.com','site.com'));
                        fileDetails.put('richText', cf.Rich_Text__c);
                        attachmentMap.put(cf.Name, fileDetails);
                    }
                    
                    if(recordId != null){
                        System.debug('Query '+ buildP1ProjectProposalQuery(' WHERE Id =: recordId '));
                        return new Map<Object,Object>{ 'data' => new List<SObject>{database.query(buildP1ProjectProposalQuery(' WHERE Id =: recordId '))},'attachments' => attachmentMap,'success' => true};
                            }else{}
                }
                
                when else {}
            }
            return new Map<Object,Object>();
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage() + ex.getlinenumber());
        }   
    }
    
    private static String getRelatedFilesByRecordId(String attachmentId, String origin) {
        String baseUrl = origin;
        String attachmentUrl = baseUrl + '/servlet/servlet.FileDownload?file='+attachmentId;
        return attachmentUrl;
    }
    
    private static String buildP1ProjectProposalQuery(String whereCondition){
        Schema.SObjectType sobjectTypeObj = Schema.getGlobalDescribe().get('P1_Project_Proposal__c');
        Schema.DescribeSObjectResult obj = sobjectTypeObj.getDescribe(); 
        
        String sObjName = sobjectTypeObj.getDescribe().getName();
        fieldMap = Schema.getGlobalDescribe().get(sObjName).getDescribe().fields.getMap();
        Set<String> SobjectFields = fieldMap.keySet();
        List<String> fieldsInList = new List<String>(SobjectFields);
        return 'SELECT ' + String.join(fieldsInList, ',') + ' FROM '+ sObjName + ' ' + whereCondition;
    }
    
    private static String buildP2p4ProjectProposalQuery(String whereCondition){
        Schema.SObjectType sobjectTypeObj = Schema.getGlobalDescribe().get('P2_P4_Proposal_Budget__c');
        Schema.DescribeSObjectResult obj = sobjectTypeObj.getDescribe(); 
        
        String sObjName = sobjectTypeObj.getDescribe().getName();
        fieldMap = Schema.getGlobalDescribe().get(sObjName).getDescribe().fields.getMap();
        Set<String> SobjectFields = fieldMap.keySet();
        List<String> fieldsInList = new List<String>(SobjectFields);
        return 'SELECT ' + String.join(fieldsInList, ',') + ' FROM '+ sObjName + ' ' + whereCondition;
    }
}