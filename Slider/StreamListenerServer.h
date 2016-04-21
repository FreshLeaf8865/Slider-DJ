//
//  Server.h
//  Slider
//
//  Created by Dmitry Volkov on 18.08.15.
//  Copyright (c) 2015 Automatic System Metering. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Poco/Net/StreamSocket.h"
#import "Poco/Net/ServerSocket.h"
#import "Poco/Net/TCPServer.h"
#import "Poco/Net/TCPServerConnectionFactory.h"
#import "Poco/Net/TCPServerConnection.h"


class StreamListenerServer  {
private:
    StreamListenerServer(unsigned short port);
    StreamListenerServer(const StreamListenerServer &) = delete;
    StreamListenerServer & operator = (const StreamListenerServer &) = delete;
    ~StreamListenerServer();
    
public:
    // You can extend inteface with other method from TCPServer if need much functionality
    void start();
    void stop();
    
    static StreamListenerServer * serverInstance(unsigned short port);
    
    class ServerConnection : public Poco::Net::TCPServerConnection {
    public:
        ServerConnection(const Poco::Net::StreamSocket& ss);
        
        virtual void run();
        
    private:
        StreamListenerServer* server;
    };

protected:
    virtual void onNewConnection(Poco::Net::StreamSocket& ss);
    
    virtual void onCloseConnection(Poco::Net::StreamSocket& ss);
    
    virtual void onConnectionFinished(Poco::Net::StreamSocket& ss);
    
    virtual void onReceivingBytes(Poco::Net::StreamSocket& ss, std::string bytes);
    
private:
    Poco::Net::ServerSocket serverSocket;
    Poco::Net::TCPServer tcpServer;
    int activeConnections;
    NSStatusBar* statusBar;
    NSStatusItem* statusItem;
};

// It must be only one instance of Server class so we use singelton for that
StreamListenerServer* serverInstance(unsigned short port);




