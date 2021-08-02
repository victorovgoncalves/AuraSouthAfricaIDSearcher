/*
Name: searchSouthAfricaIdLControllerTest
Purpose: test all methods of searchSouthAfricaIdLController apex class 
Author: Victor Gonçalves
Date: 2021-07-09

Change Log
2021/07/09 - Victor Gonçalves - searchSouthAfricaId() method created
*/
@isTest
public class searchSouthAfricaIdLControllerTest {
    
    @isTest
    static void searchSouthAfricaId(){    
        Contact con1 = searchSouthAfricaIdLController.searchSouthAfricaIdNumber(decimal.valueOf('8101019999051'),'1981-01-01','Male','SA citizen');
        Contact con2 = searchSouthAfricaIdLController.searchSouthAfricaIdNumber(decimal.valueOf('8101019999051'),'1981-01-01','Male','SA citizen');
        Test.setMock(HttpCalloutMock.class, new holidaysCalloutMock());
        Test.startTest();
        Map<String,String> resultsJson = searchSouthAfricaIdLController.getRecordHolidaysByCallout(con2);
        Test.stopTest();    
        Map<Boolean,String> holidaysInsertResults = searchSouthAfricaIdLController.insertHolidayRecords('{"Name":"New Years Day","Description__c":"New Year’s Day is celebrated with a blend of both diversity and tradition in countries such as South Africa on January 1 each year.","Date__c":"1981-01-01","Type__c":"National holiday"}',con2);
    }

}