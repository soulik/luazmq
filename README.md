LuaZMQ
=====

ZeroMQ binding for Lua

This binding relies on ZeroMQ 4.0.x+ C API!

It's divided into low level C++ part and high level Lua part.
Therefore there are two files luazmq.dll (luazmq.so) and zmq.lua.

Dependencies
============
To build and use LuaZMQ successfully you need:

* ZeroMQ 4.0.x+
* A standards-compliant C++ complier. (Visual Studio 2012 is preferred)
* Lua 5.1.x, LuaJIT 2.0.x
* Lutok - https://github.com/soulik/lutok
* update lua5.1.props so that you've got correct paths for Lua header and library files

Usage
=====

## Req part without polling

```lua
local zmq = require 'zmq'

local context = assert(zmq.context())
local socket = assert(context.socket(zmq.ZMQ_REQ))

socket.options.identity = "A client #1"

assert(socket.connect("tcp://localhost:12345"))

assert(socket.send("Test message"))
local result = assert(socket.recvAll())
print('Returned answer: ', result)

socket.diconnect()

```

## Rep part with polling

```lua
local zmq = require 'zmq'

local context = assert(zmq.context())
local socket = assert(context.socket(zmq.ZMQ_REP))

assert(socket.bind("tcp://*:12345"))

local poll = zmq.poll()
	
poll.add(socket, zmq.ZMQ_POLLIN, function(socket)
	local result = assert(socket.recvAll())
	local identity = socket.options.identity
	local data = "Hello: "..identity..". This is a reply to: "..result
	socket.send(data)
	print('Received: ', result, 'from: ', identity)
end)

while true do
	poll.start()
end

socket.diconnect()
```

## Req & Rep pair with threads
```lua
local req = [[
	local name = "Thread 1"

	local socket,msg = assert(context.socket(zmq.ZMQ_REQ))
	socket.options.identity = name

	local result, msg = assert(socket.connect("tcp://127.0.0.1:12345"))

	local poll = zmq.poll()

	poll.add(socket, zmq.ZMQ_POLLIN, function(socket)
		local result = assert(socket.recvAll())
		if result then
			print(string.format("1 Recieved data: %q", result))
		end
	end)

	socket.send(":)")

	while true do
		poll.start()
	end
	socket.close()
]]

local zmq = require 'zmq'

local context, msg = assert(zmq.context())
local socket,msg = assert(context.socket(zmq.ZMQ_ROUTER))
local result, msg = assert(socket.bind("tcp://*:12345"))

local poll = zmq.poll()

poll.add(socket, zmq.ZMQ_POLLIN, function(socket)
	local name, _, result = unpack(assert(socket.recvMultipart()))
	print(string.format("0 Recieved data: %q from: %q", result, name))

	local data = "Hello: "..tostring(result)
	socket.sendMultipart({name, '', data})
end)

print("0 Waiting for connections")
local t1 = context.thread(req)
while true do
	poll.start()
end
t1.join()
socket.close()
```

## Inproc communication for threads
```lua
local req = [[
	local name = unpack(arg)

	local socket,msg = assert(context.socket(zmq.ZMQ_REQ))
	local result, msg = assert(socket.connect("inproc://test1"))
	local poll = zmq.poll()
	local running = true

	poll.add(socket, zmq.ZMQ_POLLIN, function(socket)
		local result = socket.recvAll()
		if result then
			print(name, string.format("Recieved data: %q", result))
			running = false
		end
	end)

	socket.send("Lorem ipsum dolor sit amet")

	while running do
		poll.start()
	end
	socket.close()
]]

local zmq = require 'zmq'
local THREADS = 10

local context, msg = assert(zmq.context())
local socket,msg = assert(context.socket(zmq.ZMQ_REP))
local result, msg = assert(socket.bind("inproc://test1"))

local poll = zmq.poll()

poll.add(socket, zmq.ZMQ_POLLIN, function(socket)
	local result = socket.recvAll()
	if result then
		print(string.format("0 Recieved data: %q", result))
		local data = "Hello: "..result
		socket.send(data)
	end
end)

print("0 Waiting for connections")
local threads = {}
for i=1,THREADS do
	threads[i] = context.thread(req, string.format("%d", i))
end

while true do
	poll.start()
end

for _, thread in ipairs(threads) do
	thread.join()
end

socket.close()
```

Authors
=======
* Mário Kašuba <soulik42@gmail.com>

Links for further info
======================
For general project information, please visit:

-	http://zeromq.org/ - ZeroMQ library

Copying
=======
Copyright 2013, 2014 Mário Kašuba
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

* Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in the
  documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
