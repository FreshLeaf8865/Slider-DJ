//
//  CurlHelper.h
//  Slider
//
//  Created by Dmitry Volkov on 08.07.15.
//  Copyright (c) 2015 Automatic System Metering. All rights reserved.
//

//#ifndef Slider_CurlHelper_h
//#define Slider_CurlHelper_h

#import <curl/curl.h>
#import <string>

class CurlHelper {
public:
    CurlHelper();
    ~CurlHelper();
    
    CurlHelper(const CurlHelper&) = delete;
    CurlHelper operator = (const CurlHelper&) = delete;
    
    bool signIn(const char* user, const char* pass);
    void signOut();
    
    std::string partiesJSON();
    std::string messagesJSON(const char* partyID);
    std::string requestJSON(const char* partyID);
    std::string inventoryJSON(const char* partyID);
    
    bool uploadSongs(const char* partyID);
    
    bool postSelectedSong(const char* partyID, const char* artist,
                         const char* title, const char* path, const char* startTime);
    
    void reset();
    
private:
    CURL * curlHandle;
    std::string authenticityToken;
};

extern CurlHelper* gCurlHelper;

//#endif
