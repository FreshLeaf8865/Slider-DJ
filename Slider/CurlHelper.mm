//
//  CurlHelper.m
//  Slider
//
//  Created by Dmitry Volkov on 08.07.15.
//  Copyright (c) 2015 Automatic System Metering. All rights reserved.
//

#import "CurlHelper.h"
#import "HTMLParser.h"

#define HOSTNAME "http://dpi-env-f4v9ch4yn3.elasticbeanstalk.com"

std::string gReadBuffer;

static size_t writeCallback(void *contents, size_t size, size_t nmemb, void *userp)
{
    size_t realsize = size * nmemb;
    gReadBuffer.append((char*)contents, realsize);
    return realsize;
}

static std::string readAuthenticityToken()
{
    NSString* html = [NSString stringWithFormat:@"%s", gReadBuffer.c_str()];
    NSString* token = nil;
    NSError *error = nil;
    HTMLParser *parser = [[HTMLParser alloc] initWithString:html error:&error];
    std::string authenticityToken;
    
    if (error)
    {
        //NSLog(@"Error:%@ FILE: %s LINE: %d ", error, __FILE__, __LINE__);
        return nil;
    }

    HTMLNode *bodyNode = [parser head];
    NSArray *inputNodes = [bodyNode findChildTags:@"meta"];

    for (HTMLNode *inputNode in inputNodes)
    {
        if ([[inputNode getAttributeNamed:@"name"] isEqualToString:@"csrf-token"])
        {
            token = [[inputNode getAttributeNamed:@"content"] copy];
            break;
        }
    }
    
    if (token)
    {
        authenticityToken = [token UTF8String];
    }
    
    return authenticityToken;
}

CurlHelper::CurlHelper() : curlHandle(nullptr)
{
}

CurlHelper::~CurlHelper()
{
    signOut();
}

bool CurlHelper::signIn(const char* user, const char* pass)
{
    curl_global_init( CURL_GLOBAL_ALL );
    curlHandle = curl_easy_init ();
    
    curl_easy_setopt(curlHandle, CURLOPT_USERAGENT,
                     "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1; .NET CLR 1.0.3705; .NET CLR 1.1.4322)");
    curl_easy_setopt(curlHandle, CURLOPT_AUTOREFERER, 1);
    curl_easy_setopt(curlHandle, CURLOPT_FOLLOWLOCATION, 1);
    curl_easy_setopt(curlHandle, CURLOPT_COOKIE, "");
    curl_easy_setopt(curlHandle, CURLOPT_COOKIEJAR, "");
    curl_easy_setopt(curlHandle, CURLOPT_WRITEFUNCTION, writeCallback);
    
    //curl_easy_setopt(curlHandle, CURLOPT_VERBOSE, true);
    curl_easy_setopt(curlHandle, CURLOPT_URL, HOSTNAME"/sign_in");
    
    if (curl_easy_perform(curlHandle) != CURLE_OK)
    {
        return false;
    }
    
    gReadBuffer.clear();
    curl_easy_setopt(curlHandle, CURLOPT_URL, HOSTNAME"/sign_in");
    
    if (curl_easy_perform(curlHandle) != CURLE_OK)
    {
        return false;
    }
    
    char data[1024];
    authenticityToken = readAuthenticityToken();
    
    char *escapedAuthtoken = curl_easy_escape(curlHandle, authenticityToken.c_str(), (int)authenticityToken.length());
    snprintf(data, sizeof(data), "session[username]=%s&session[password]=%s&authenticity_token=%s", user, pass, escapedAuthtoken);
    curl_free(escapedAuthtoken);
    
    curl_easy_setopt(curlHandle, CURLOPT_URL, HOSTNAME"/sessions");
    curl_easy_setopt(curlHandle, CURLOPT_POST, true);
    curl_easy_setopt(curlHandle, CURLOPT_POSTFIELDS, data);
    gReadBuffer.clear();
    
    if (curl_easy_perform(curlHandle) != CURLE_OK)
    {
        return false;
    }

    gReadBuffer.clear();
    curl_easy_setopt(curlHandle, CURLOPT_URL, HOSTNAME"/menu");
    
    if (curl_easy_perform(curlHandle) != CURLE_OK)
    {
        return false;
    }

    authenticityToken = readAuthenticityToken();

    long httpCode = 0;
    curl_easy_getinfo (curlHandle, CURLINFO_RESPONSE_CODE, &httpCode);

    if (200 == httpCode)
    {
        return true; 
    }

    return false;
}

void CurlHelper::signOut()
{
    curl_easy_cleanup(curlHandle);
    curl_global_cleanup();
    curlHandle = nullptr;
}

std::string CurlHelper::partiesJSON()
{
    gReadBuffer.clear();
    curl_easy_setopt(curlHandle, CURLOPT_URL, HOSTNAME"/my_parties.json");
    curl_easy_perform(curlHandle);
    return gReadBuffer;
}

std::string CurlHelper::messagesJSON(const char* partyID)
{
    char url[512];
    snprintf(url, sizeof(url), "%s/parties/%s/messages.json", HOSTNAME, partyID);
    gReadBuffer.clear();
    curl_easy_setopt(curlHandle, CURLOPT_URL, url);
    curl_easy_perform(curlHandle);
    
    return gReadBuffer;
}

std::string CurlHelper::requestJSON(const char* partyID)
{
    char url[512];
    snprintf(url, sizeof(url), "%s/parties/%s/requests.json", HOSTNAME, partyID);
    gReadBuffer.clear();
    curl_easy_setopt(curlHandle, CURLOPT_URL, url);
    curl_easy_perform(curlHandle);
    
    return gReadBuffer;
}

std::string CurlHelper::inventoryJSON(const char* partyID)
{
    char url[512];
    snprintf(url, sizeof(url), "%s/parties/%s/inventory.json", HOSTNAME, partyID);
    gReadBuffer.clear();
    curl_easy_setopt(curlHandle, CURLOPT_URL, url);
    curl_easy_perform(curlHandle);
    
    return gReadBuffer;
}

bool CurlHelper::uploadSongs(const char* partyID)
{
    char url[1024] = {0};
    snprintf(url, sizeof(url), "%s/parties/%s/putinventory.json", HOSTNAME, partyID);

    struct curl_httppost *formpost=NULL;
    struct curl_httppost *lastptr=NULL;
    
    curl_formadd(&formpost,
                 &lastptr,
                 CURLFORM_COPYNAME, "authenticity_token",
                 CURLFORM_COPYCONTENTS, authenticityToken.c_str(),
                 CURLFORM_END);
    
    curl_formadd(&formpost,
                 &lastptr,
                 CURLFORM_COPYNAME, "inventory",
                 CURLFORM_FILE, "inventory.json",
                 CURLFORM_END);
    
    curl_easy_setopt(curlHandle, CURLOPT_URL, url);
    curl_easy_setopt(curlHandle, CURLOPT_VERBOSE, true);
    curl_easy_setopt(curlHandle, CURLOPT_COOKIE, "");
    curl_easy_setopt(curlHandle, CURLOPT_COOKIEJAR, "");
    curl_easy_setopt(curlHandle, CURLOPT_HTTPPOST, formpost);
    curl_easy_setopt(curlHandle, CURLOPT_CUSTOMREQUEST, "PUT");
    
    long httpCode = 0;
    CURLcode res = curl_easy_perform(curlHandle);
    curl_easy_getinfo (curlHandle, CURLINFO_RESPONSE_CODE, &httpCode);

    if (CURLE_OK == res && 201 == httpCode)
    {
        return true;
    }
    
    return false;
}


// Post selected song for third window on slider panel to the server
bool CurlHelper::postSelectedSong(const char* partyID, const char* artist,
                                  const char* title, const char* path, const char* startTime)
{
    char url[1024] = {0};

    snprintf(url, sizeof(url), "%s/new_playlist_entry.json", HOSTNAME);

    char data[4096] = {0};
    char *escapedAuthtoken = curl_easy_escape(curlHandle, authenticityToken.c_str(), (int)authenticityToken.length());
    snprintf(data, sizeof(data), "party_id=%s&artist=%s&title=%s&filename=%s&startTime=%s&authenticity_token=%s",
             partyID, artist, title, path, startTime, escapedAuthtoken);
    curl_free(escapedAuthtoken);

    curl_easy_setopt(curlHandle, CURLOPT_VERBOSE, true);
    curl_easy_setopt(curlHandle, CURLOPT_URL, url);
    curl_easy_setopt(curlHandle, CURLOPT_POST, true);
    curl_easy_setopt(curlHandle, CURLOPT_POSTFIELDS, data);

    long httpCode = 0;
    CURLcode res = curl_easy_perform(curlHandle);
    curl_easy_getinfo (curlHandle, CURLINFO_RESPONSE_CODE, &httpCode);

    if (CURLE_OK == res && 201 == httpCode)
    {
        return true;
    }

    return false;
}

void CurlHelper::reset()
{
    curl_easy_reset(curlHandle);
    curl_easy_setopt(curlHandle, CURLOPT_WRITEFUNCTION, writeCallback);
}
