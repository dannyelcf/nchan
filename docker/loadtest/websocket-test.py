#!/usr/bin/env python3
import asyncio
import websockets
import json
import time
import sys

async def websocket_publisher(uri, channel, messages, delay=0.1):
    async with websockets.connect(f"{uri}/ws/{channel}") as websocket:
        for i in range(messages):
            message = f"Message {i+1} at {time.time()}"
            await websocket.send(message)
            print(f"Sent: {message}")
            await asyncio.sleep(delay)

async def websocket_subscriber(uri, channel, duration=10):
    async with websockets.connect(f"{uri}/ws/{channel}") as websocket:
        start_time = time.time()
        message_count = 0
        
        try:
            while time.time() - start_time < duration:
                message = await asyncio.wait_for(websocket.recv(), timeout=1.0)
                message_count += 1
                print(f"Received: {message}")
        except asyncio.TimeoutError:
            pass
        
        print(f"Received {message_count} messages in {duration} seconds")

if __name__ == "__main__":
    if len(sys.argv) < 4:
        print("Usage: websocket-test.py <uri> <channel> <pub|sub> [args...]")
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