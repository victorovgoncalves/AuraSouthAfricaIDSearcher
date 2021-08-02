/*
Name: searchSouthAfricaIdLControllerTest
Purpose: Apex controller of Aura Component searchSouthAfricaIdInHolidays
Author: Victor Gonçalves
Date: 2021-07-09

Change Log
2021/07/09 - Victor Gonçalves - searchSouthAfricaIdNumber convert the contactSouthAfricaIdNumber extracted data into contact records, filling standard and custom fields.
2021/07/09 - Victor Gonçalves - getRecordHolidaysByCallout sends callout to get holiday dates based on contact (contactSouthAfricaIdNumber) Birth Day
2021/07/09 - Victor Gonçalves - insertHolidayRecords get the callout data (holidayList) and create Public_Holidays__c records, associated to contacts (contactSouthAfricaIdNumbers)
2021/07/09 - Victor Gonçalves - calloutRequestSync helps the callout of getRecordHolidaysByCallout method
*/
public class searchSouthAfricaIdLController {
@AuraEnabled
    public static Contact searchSouthAfricaIdNumber(Decimal contactSouthAfricaIdNumber,String contactBirthdayDate, String contactGender, String contactCitizen){        
        String dmlErrors = '';
        contactBirthdayDate = contactBirthdayDate.replaceAll(' ','-');
        Decimal birthdayYear = Decimal.valueOf(contactBirthdayDate.substring(0,2))+2000;
        //Decimal todayYear = System.today().year();
        Decimal searchHistory = 1;        
        Contact con = new Contact();
        List<Contact> contacts = new List<Contact>();
        contacts = [SELECT Id,South_Africa_Id_Number__c,Times_Searched__c FROM Contact WHERE South_Africa_Id_Number__c =: contactSouthAfricaIdNumber];
		
        if(contacts.size()>0)
        {
            if(contacts[0].Times_Searched__c != null){
                searchHistory = contacts[0].Times_Searched__c+1;
            }
        }
        
        con.Birthdate = Date.valueOf(contactBirthdayDate);
        con.South_Africa_Id_Number__c = contactSouthAfricaIdNumber;
        //LastName is required for salesforce contacts
        con.LastName = 'CloudSmithsTest'+String.valueOf(System.now());
        con.Gender__c = contactGender;
        con.Citizenship__c = contactCitizen;
        con.Times_Searched__c = searchHistory;
		
        System.debug('contact to Insert : '+con);
        try {
            upsert con South_Africa_Id_Number__c;
        }
        catch (DmlException e) {
            System.debug(e.getMessage());
        }
        return con;
    }
    
    @AuraEnabled
    public static Map<String,String> getRecordHolidaysByCallout(Contact contactRecord){
        Map<String,String> logJsonMap = new Map<String,String>();
        String inboundJson = 'We cannot find any holidays on your birthday, based on your South Africa Id number';
        System.debug('do the callout for this contact:'+contactRecord);
        String apiKey = 'de578d582d8dc51ee7900fcd8fd7a7a58459f6a4';
        String countryAndYear = '&country=ZA&year='+contactRecord.Birthdate.year();
        String calloutEndpointUrl = 'https://calendarific.com/api/v2/holidays'+'?&api_key='+apiKey+countryAndYear;
        List<String> calloutResponse = calloutRequestSync('',calloutEndpointUrl);
        if(calloutResponse[0]=='sucess on request:200')
        {            
            if(calloutResponse[1].contains(String.valueOf(contactRecord.Birthdate)))
            {
                inboundJson = 'Congratulations, you have holidays on your birth date!';                
            }
            logJsonMap.put(inboundJson,calloutResponse[1]);
        }
        else
        {           
            logJsonMap.put(inboundJson,'');
        }
        System.debug('calloutResponse : '+calloutResponse);
        System.debug('logJsonMap : '+logJsonMap);
        return logJsonMap;
    }
    
    @AuraEnabled
    public static Map<Boolean,String> insertHolidayRecords(String holidayList, Contact contactRecord){
        
        Map<Boolean,String> logInsertHolidayList = new Map<Boolean,String>();
        List<Public_Holidays__c> holidaysToUpsert = new List<Public_Holidays__c>();
        holidayList = holidayList.replace('\'','’');
        
        List<String> holidaysList = holidayList.split('}');
        
        if(holidaysList.size()>0){
            for(String s : holidaysList){
                s = s.removeEnd(',').removeStart(',')+'}';
                Map<String, Object> jsonmap = new Map<String, Object>();
                jsonmap = (Map<String, Object>) JSON.deserializeUntyped(s);
                Public_Holidays__c holiday = new Public_Holidays__c(
                    Name=String.valueOf(jsonmap.get('Name')),Date__c=Date.valueOf(String.valueOf(jsonmap.get('Date__c'))),
                    Description__c=String.valueOf(jsonmap.get('Description__c')),Type__c=String.valueOf(jsonmap.get('Type__c'))
                );
                holiday.ExternalId__c = holiday.Name.replace('’','') +' '+ contactRecord.South_Africa_Id_Number__c;
                holiday.Contact_Id_Number__c = contactRecord.Id;
                holidaysToUpsert.add(holiday);
                System.debug('holiday to Insert in list:'+holiday);
            }
        }
        
        if(holidaysToUpsert.size()>0)
        {
            try {
                upsert holidaysToUpsert ExternalId__c;
            } catch (DmlException e) {
                System.debug(e.getMessage());
            }
        }
                
		System.debug('holidayList to Insert : '+holidayList);
        return logInsertHolidayList;
    }
    
    public static List<String> calloutRequestSync(String JsonBody, String EndpointUrl){  	
		HttpRequest req = new HttpRequest();
		req.setEndpoint(EndpointUrl);
		req.setBody(JsonBody);
        req.setMethod('GET');        		
        req.setHeader('Authorization', '');
		req.setHeader('Content-Type', 'application/json');
		Http h = new Http();
        List<String> completeResponse = new List<String>();
        
        system.debug('--- requisição = '+JsonBody);
        HttpResponse res = new HttpResponse();
        try{
            res = h.send(req);
        }
        catch(System.CalloutException e){
            System.debug('The following SOARequestSync exception has occurred: ' + e.getMessage());
            if(res.getStatusCode() == 0)
            {
                res.setStatusCode(504);
                res.setBody('{"errorMessage":"FATAL_ERROR System.CalloutException: Read timed out","errorCode":"0"}');
            }
        }
        		
        Integer returnedStatus = res.getStatusCode();
        String returnedBody = res.getBody();
        
		system.debug('--- return    = '+returnedBody);
		system.debug('--- return    = '+returnedStatus);
		      
		if(returnedStatus==200){
				completeResponse.add('sucess on request:'+returnedStatus);
				completeResponse.add(returnedBody);
		}else {
			completeResponse.add('error on request:'+returnedStatus);
			completeResponse.add(returnedBody);
		}
		return completeResponse;
	}
    
}