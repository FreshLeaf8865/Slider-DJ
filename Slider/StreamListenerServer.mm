//
//  Server.m
//  Slider
//
//  Created by Dmitry Volkov on 18.08.15.
//  Copyright (c) 2015 Automatic System Metering. All rights reserved.
//


#import "StreamListenerServer.h"
#import "AppDelegate.h"
#import "ArtistAndTitleTableViewController.h"

static StreamListenerServer * gServer = nullptr;

StreamListenerServer ::StreamListenerServer  (unsigned short port) :
serverSocket(port),
tcpServer(new Poco::Net::TCPServerConnectionFactoryImpl<ServerConnection>(), serverSocket),
activeConnections(0),
statusBar(nil),
statusItem(nil)
{
    statusBar = [NSStatusBar systemStatusBar];
    statusItem = [statusBar statusItemWithLength:NSVariableStatusItemLength];
    
    [statusItem setHighlightMode:NO];
    [statusItem setEnabled:YES];
    [statusItem setLength:275];
    
    gServer = this;
}

StreamListenerServer::~StreamListenerServer()
{
    
}

void StreamListenerServer ::start()
{
    tcpServer.start();
    
    [statusItem setTitle:@"Server don't have active connections"];
    NSImage* image =[NSImage imageNamed:@"server_stop.png"];
    [statusItem setImage:image];
}

void StreamListenerServer ::stop()
{
    tcpServer.stop();
}

StreamListenerServer * StreamListenerServer ::serverInstance(unsigned short port)
{
    static StreamListenerServer * pServer = nullptr;
    
    if (nullptr == pServer)
    {
        pServer = new StreamListenerServer(port);
    }
    
    return pServer;
}

void StreamListenerServer::onNewConnection(Poco::Net::StreamSocket& ss)
{
    // Add your code
    NSLog(@"New connection from host: %s", ss.peerAddress().host().toString().c_str());
 
    [gAppDelegate showNotification:
     [NSString stringWithFormat:@"New connection from host: %s", ss.peerAddress().host().toString().c_str()]];
    
    ++activeConnections;
    
    NSString* topBarTitle = [NSString stringWithFormat:@"Server have %d active connections", activeConnections];
    
    [statusItem setTitle:topBarTitle];
    NSImage* image =[NSImage imageNamed:@"server_run.png"];
    [statusItem setImage:image];
    
    [gAppDelegate susuccessfullyConnectedClient];
}

void StreamListenerServer::onCloseConnection(Poco::Net::StreamSocket& ss)
{
    // Add your code
    NSLog(@"Close connection from host: %s", ss.peerAddress().host().toString().c_str());
    
    [gAppDelegate showNotification:
    [NSString stringWithFormat:@"Close connection from host: %s", ss.peerAddress().host().toString().c_str()]];
    
    --activeConnections;
    
    if (activeConnections <= 0)
    {
        [statusItem setTitle:@"Server don't have active connections"];
        NSImage* image =[NSImage imageNamed:@"server_stop.png"];
        [statusItem setImage:image];
    }
    else
    {
        NSString* topBarTitle = [NSString stringWithFormat:@"Server have %d active connections", activeConnections];
        
        [statusItem setTitle:topBarTitle];
        NSImage* image =[NSImage imageNamed:@"server_run.png"];
        [statusItem setImage:image];
    }
    
    [gAppDelegate connectionHasBeenLost];
}

void StreamListenerServer::onConnectionFinished(Poco::Net::StreamSocket& ss)
{
    // Add your code
    NSLog(@"Finish connection from host: %s", ss.peerAddress().host().toString().c_str());
    
    [gAppDelegate showNotification:
    [NSString stringWithFormat:@"Finish connection from host: %s", ss.peerAddress().host().toString().c_str()]];
    
   
}

void StreamListenerServer::onReceivingBytes(Poco::Net::StreamSocket& ss, std::string bytes)
{
    // Add your code
    NSLog(@"Receive bytes: %s, size %lu", bytes.c_str(), bytes.length());
    
    [gAppDelegate showNotification:
    [NSString stringWithFormat:@"Receive bytes: %s, size %lu", bytes.c_str(), bytes.length()]];
    
   // NSString* str = [NSString stringWithFormat:@"%s", bytes.c_str()];
    
    // It's callback for add song & title to bottom table view
   // [gArtistAndTitleTableViewController addNewSong:str andTitle:@"NoTitle" andPath:@"NoPath"];
}

StreamListenerServer ::ServerConnection::ServerConnection(const Poco::Net::StreamSocket& ss) :
Poco::Net::TCPServerConnection(ss), server(gServer)
{
    
}

void StreamListenerServer::ServerConnection::run()
{
    enum : int { MaxReadBufferSize = 512 };
    Poco::Timespan timeOut(10,0);
    char readBuffer[MaxReadBufferSize];
    std::string bytes;
    
    server->onNewConnection(socket());
    
    for (;;)
    {
        if (socket().poll(timeOut,Poco::Net::Socket::SELECT_READ))
        {
            int readBytes = 0;
            int totalReadBytes = 0;
            
            try
            {
                do
                {
                    readBytes = socket().receiveBytes(readBuffer, MaxReadBufferSize);
                    bytes.insert(bytes.end(), readBuffer, readBuffer + readBytes);
                    totalReadBytes += readBytes;
                }
                while (socket().available() > 0);
            }
            catch (Poco::Exception& exc)
            {
                break;
            }
            
            if (0 == totalReadBytes)
            {
                server->onCloseConnection(socket());
                break;
            }
            else
            {
                // Remove 2 last return carriage bytes
                bytes.erase(bytes.end() - 2, bytes.end());
                server->onReceivingBytes(socket(), bytes);
                bytes.clear();
            }
        }
    }
    
    server->onConnectionFinished(socket());
}





