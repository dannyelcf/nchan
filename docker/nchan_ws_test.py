#!/usr/bin/env python3

import asyncio
import websockets
import json
import sys
import signal
import threading
import time
from datetime import datetime

class NchanWebSocketTest:
    def __init__(self, host, channel):
        self.host = host
        self.channel = channel
        self.messages_received = []
        self.connected = False
        self.subscriber_task = None
        
    async def subscriber(self):
        uri = f"ws://{self.host}/ws/{self.channel}"
        print(f"📡 Connecting to WebSocket: {uri}")
        
        try:
            async with websockets.connect(uri) as websocket:
                self.connected = True
                print(f"✅ Connected to channel '{self.channel}'")
                print("📥 Listening for messages... (Press Ctrl+C to stop)")
                
                async for message in websocket:
                    timestamp = datetime.now().strftime("%H:%M:%S")
                    print(f"[{timestamp}] 📨 Received: {message}")
                    self.messages_received.append(message)
                    
        except websockets.exceptions.ConnectionClosed:
            print("🔌 WebSocket connection closed")
        except Exception as e:
            print(f"❌ WebSocket error: {e}")
        finally:
            self.connected = False
    
    def publisher(self):
        """Publish messages via HTTP to test integration"""
        import urllib.request
        import urllib.parse
        
        time.sleep(2)  # Wait for subscriber to connect
        
        messages = [
            f"Test message 1 - {datetime.now()}",
            f"WebSocket integration test - {datetime.now()}",
            f"Final test message - {datetime.now()}"
        ]
        
        for i, msg in enumerate(messages, 1):
            try:
                url = f"http://{self.host.replace(':8082', ':8080')}/pub/{self.channel}"
                data = msg.encode('utf-8')
                req = urllib.request.Request(url, data=data, method='POST')
                
                print(f"📤 Publishing message {i}: {msg}")
                response = urllib.request.urlopen(req)
                
                if response.getcode() == 200:
                    print(f"✅ Message {i} published successfully")
                else:
                    print(f"⚠️  Message {i} publish returned status {response.getcode()}")
                    
                time.sleep(1)
                
            except Exception as e:
                print(f"❌ Failed to publish message {i}: {e}")
    
    async def run_test(self):
        print("🚀 Starting Nchan WebSocket test...")
        print(f"Host: {self.host}")
        print(f"Channel: {self.channel}")
        print()
        
        # Start subscriber
        self.subscriber_task = asyncio.create_task(self.subscriber())
        
        # Start publisher in a separate thread
        publisher_thread = threading.Thread(target=self.publisher)
        publisher_thread.daemon = True
        publisher_thread.start()
        
        try:
            # Wait for subscriber (will run until interrupted)
            await self.subscriber_task
        except asyncio.CancelledError:
            print("\n🛑 Test interrupted")
        except KeyboardInterrupt:
            print("\n🛑 Test stopped by user")
        
        print(f"\n📊 Test Results:")
        print(f"   Messages received: {len(self.messages_received)}")
        if self.messages_received:
            print("   Messages:")
            for i, msg in enumerate(self.messages_received, 1):
                print(f"   {i}. {msg}")
        
        return len(self.messages_received)

def signal_handler(signum, frame):
    print("\n🛑 Stopping WebSocket test...")
    sys.exit(0)

if __name__ == "__main__":
    signal.signal(signal.SIGINT, signal_handler)
    
    host = sys.argv[1] if len(sys.argv) > 1 else "localhost:8082"
    channel = sys.argv[2] if len(sys.argv) > 2 else f"ws_test_{int(time.time())}"
    
    test = NchanWebSocketTest(host, channel)
    
    try:
        asyncio.run(test.run_test())
    except KeyboardInterrupt:
        pass
    
    print("🎉 WebSocket test completed!")