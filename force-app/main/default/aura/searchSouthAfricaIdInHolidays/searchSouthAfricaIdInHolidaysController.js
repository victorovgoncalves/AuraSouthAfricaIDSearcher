({
	doInit : function(component, event, helper) {		
	},
    
    changedSouthAfricaIdNumber: function(component, event, helper){
        component.set('v.hideContactFromDatabase', true);
        var newvalue = event.getSource().get("v.value");
        
        console.log('newvalue : '+newvalue);
        
        var inputfield = event.getSource();        
        var errorMessage = '';
        var southAfricaIdString = newvalue.substr(0,2)+' '+newvalue.substr(2,2)+' '+newvalue.substr(4,2);
        var today = $A.localizationService.formatDate(new Date(), "YYYY-MM-DD");
        
        console.log('today.getFullYear() : '+today.toString().substr(0,4));
        console.log('southAfricaIdString : '+southAfricaIdString);
        
        if((2000+parseInt(newvalue.substr(0,2)))>parseInt(today.toString().substr(0,4)))
        {
            southAfricaIdString = '19'+newvalue.substr(0,2)+' '+newvalue.substr(2,2)+' '+newvalue.substr(4,2);
        }
        else
        {
            southAfricaIdString = '20'+newvalue.substr(0,2)+' '+newvalue.substr(2,2)+' '+newvalue.substr(4,2);
        }

        var birthdayDate = $A.localizationService.formatDate(southAfricaIdString, "yyyy MM dd");
        var genderCode = newvalue.substr(6,4);
        var citizenCode = newvalue.substr(10,1);
        var checkSumCode = newvalue.substr(12,1);
        
        console.log('birthdayDate : '+birthdayDate);
        console.log('newvalue.toString().length : '+newvalue.toString().length);
        
        if(newvalue.toString().length != 13)
        {            
            errorMessage = 'Enter a 13 digit number'
            inputfield.setCustomValidity(errorMessage);
            component.set('v.hideSearchButton', true);
        }
        else if(birthdayDate.toString() == 'Invalid Date')
        {            
            errorMessage = 'Invalid South Africa Id number';
            inputfield.setCustomValidity(errorMessage);
            component.set('v.hideSearchButton', true);
        }
        else if(citizenCode != '0' && citizenCode != '1')
        {            
            errorMessage = 'Invalid South Africa Id number';
            inputfield.setCustomValidity(errorMessage);
            component.set('v.hideSearchButton', true);
        }
        else
        {
            errorMessage = '';
            inputfield.setCustomValidity(errorMessage);
            component.set('v.inputSouthAfricaIdNumber', newvalue);
            component.set('v.hideSearchButton', false);
            component.set('v.inputBirthdate', birthdayDate);
            
            if(parseInt(genderCode)<=4999)
            {
                component.set('v.inputGender', 'Female');
            }
            else
            {
                component.set('v.inputGender', 'Male');
            }
            
            if(parseInt(citizenCode)==0)
            {
                component.set('v.inputCitizenship', 'SA citizen');
            }
            else
            {
                component.set('v.inputCitizenship', 'Permanent resident');
            }

        }

    },
    
    searchId: function(component, event, helper){
        component.set('v.hideContactFromDatabase', true);
        var cSouthAfricaIdNumber = component.get('v.inputSouthAfricaIdNumber');
        var cBirthdayDate = component.get('v.inputBirthdate');
        var cGender = component.get('v.inputGender');
        var cCitizen = component.get('v.inputCitizenship');

        var searchInDatabase = component.get("c.searchSouthAfricaIdNumber");
        searchInDatabase.setParams({
            contactSouthAfricaIdNumber: cSouthAfricaIdNumber,
            contactBirthdayDate: cBirthdayDate,
            contactGender: cGender,
            contactCitizen: cCitizen
        });
        searchInDatabase.setCallback(this, function(response){             
            var returnedValue = response.getReturnValue();            
            console.log('retorno do apex:'+JSON.stringify(returnedValue));
            component.set('v.recordId', returnedValue.Id);
            component.set('v.outputSouthAfricaIdNumber', returnedValue.South_Africa_Id_Number__c);
            component.set('v.outputBirthdate', returnedValue.Birthdate);
            component.set('v.outputGender', returnedValue.Gender__c);
            component.set('v.outputCitizenship', returnedValue.Citizenship__c);
            component.set('v.outputTimesSearched', returnedValue.Times_Searched__c);
            var sendHolidaysCallout = component.get("c.getRecordHolidaysByCallout");
            sendHolidaysCallout.setParams({
                contactRecord: returnedValue
            });
            sendHolidaysCallout.setCallback(this, function(response){
                var returnedCalloutMap = response.getReturnValue();
                console.log('Object.keys(returnedCalloutMap)[0] : '+Object.keys(returnedCalloutMap)[0]);
                if(Object.keys(returnedCalloutMap)[0] == 'We cannot find any holidays on your birthday, based on your South Africa Id number')
                {
                    var toastEventFailed = $A.get("e.force:showToast");                
                    toastEventFailed.setParams({
                        "title": "Sorry",
                        "type": "error",
                        "message": Object.keys(returnedCalloutMap)[0]
                    });
                    toastEventFailed.fire();
                }
                else
                {
                    var holidaysOnBithdayJson = Object.values(returnedCalloutMap)[0];                    
                    var holidaysOnBithdayObj = JSON.parse(holidaysOnBithdayJson);
                    var holidaysOnBithdaySize = holidaysOnBithdayObj.response.holidays.length;
                    var holidaysResume = '';
                    var holidays = '';
                    var i = 0;
                    console.log('holidaysOnBithdaySize:'+holidaysOnBithdaySize);
                    console.log('holidaysOnBithdayJson:'+holidaysOnBithdayJson);
                    for(i=0; i<holidaysOnBithdaySize ; i++)
                    {                        
                        if(holidaysOnBithdayObj.response.holidays[i].date.iso == cBirthdayDate.replace(/ /g, '-'))
                        {                            
                            holidaysResume = holidaysResume+holidaysOnBithdayObj.response.holidays[i].description;
                            if(holidays != '')
                            {
                                holidays = holidays + ','
                            }
                            holidays = holidays + '{"Name":"'+holidaysOnBithdayObj.response.holidays[i].name+'",'
                            holidays = holidays + '"Description__c":"'+holidaysOnBithdayObj.response.holidays[i].description+'",'
                            holidays = holidays + '"Date__c":"'+holidaysOnBithdayObj.response.holidays[i].date.iso+'",'
                            holidays = holidays + '"Type__c":"'+holidaysOnBithdayObj.response.holidays[i].type+'"}'
                        }
                    }
                    if(holidays != '')
                    {
                        var insertHolidays = component.get("c.insertHolidayRecords");
                        insertHolidays.setParams({
                            holidayList: holidays,
                            contactRecord: returnedValue,
                        });
                        insertHolidays.setCallback(this, function(response){
                            var insertHolidaysResults = response.getReturnValue();
                        });
                        $A.enqueueAction(insertHolidays);
                    }
                    console.log('holidays:'+holidays);
                    var toastEventFailed = $A.get("e.force:showToast");                
                    toastEventFailed.setParams({
                        "title": Object.keys(returnedCalloutMap)[0],
                        "type": "success",
                        "message": holidaysResume
                    });
                    toastEventFailed.fire();
                }
                //console.log('retorno do callout:'+JSON.stringify(returnedCalloutMap));
                component.set('v.hideContactFromDatabase', false);
            });    
            $A.enqueueAction(sendHolidaysCallout);
        });
        $A.enqueueAction(searchInDatabase);
    }
 
})