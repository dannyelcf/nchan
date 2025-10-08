#!/usr/bin/env python3
import asyncio
import websockets
import time
import sys
import json

async def websocket_publisher(uri, channel, messages, delay=0.1):
    """Publish messages to a WebSocket channel"""
    try:
        async with websockets.connect(f"{uri}/ws/{channel}") as websocket:
            print(f"📤 Connected to {uri}/ws/{channel} for publishing")
            for i in range(messages):
                message = f"WebSocket message {i+1} at {time.time():.2f}"
                await websocket.send(message)
                print(f"Sent: {message}")
                if delay > 0:
                    await asyncio.sleep(delay)
    except Exception as e:
        print(f"❌ Publisher error: {e}")

async def websocket_subscriber(uri, channel, duration=10):
    """Subscribe to messages from a WebSocket channel"""
    try:
        async with websockets.connect(f"{uri}/ws/{channel}") as websocket:
            print(f"📥 Connected to {uri}/ws/{channel} for subscribing")
            start_time = time.time()
            message_count = 0
            
            while time.time() - start_time < duration:
                try:
                    message = await asyncio.wait_for(websocket.recv(), timeout=1.0)
                    message_count += 1
                    print(f"Received: {message}")
                except asyncio.TimeoutError:
                    continue
                except websockets.exceptions.ConnectionClosed:
                    print("Connection closed")
                    break
            
            print(f"✅ Received {message_count} messages in {duration} seconds")
            return message_count
    except Exception as e:
        print(f"❌ Subscriber error: {e}")
        return 0

if __name__ == "__main__":
    if len(sys.argv) < 4:
        print("Usage: websocket-test.py <uri> <channel> <mode> [args...]")
        print("Modes:")
        print("  pub <messages> [delay] - Publish messages")
        print("  sub <duration> - Subscribe for duration")  
        sys.exit(1)
    
    uri = sys.argv[1]
    channel = sys.argv[2]
    mode = sys.argv[3]
    
    if mode == "pub":
        messages = int(sys.argv[4]) if len(sys.argv) > 4 else 10
        delay = float(sys.argv[5]) if len(sys.argv) > 5 else 0.1
        asyncio.run(websocket_publisher(uri, channel, messages, delay))
    elif mode == "sub":
        duration = int(sys.argv[4]) if len(sys.argv) > 4 else 10
        asyncio.run(websocket_subscriber(uri, channel, duration))
    else:
        print(f"Unknown mode: {mode}")
        sys.exit(1)