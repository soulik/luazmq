LuaZMQ
======

ZeroMQ binding for Lua

This binding relies on ZeroMQ 4.x.x+ C API! (Currently supports ZeroMQ 4.2 features)

It's divided into low level C++ part and high level Lua part.
Therefore there are two files luazmq.dll (luazmq.so) and zmq.lua.

Dependencies
============
To build and use LuaZMQ successfully you need:

* A standards-compliant C++11 complier
* Lua 5.1.x or LuaJIT 2.0.x+
* CMake 3.1+

This project contains all required library dependencies except Lua library.

Building
========
* cd build
* cmake ..
* Correct Lua library and includes path if needed
* Open project file and compile project using your prefered compiler

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

## Rep part with polling
### With alternative method of poll initialization

```lua
local zmq = require 'zmq'

local context = assert(zmq.context())
local socket = assert(context.socket(zmq.ZMQ_REP))

assert(socket.bind("tcp://*:12345"))

local poll = zmq.poll {
	{socket, zmq.ZMQ_POLLIN, function(socket)
		local result = assert(socket.recvAll())
		local identity = socket.options.identity
		local data = "Hello: "..identity..". This is a reply to: "..result
		socket.send(data)
		print('Received: ', result, 'from: ', identity)
	end},
}

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

## Supervised workers

```lua
local zmq = require 'zmq'

local context, msg = assert(zmq.context())

-- job socket
local socket,msg = assert(context.socket(zmq.ZMQ_DEALER))
assert(socket.bind("inproc://main"))

-- notify socket publisher
local nsocket,msg = assert(context.socket(zmq.ZMQ_PUB))
assert(nsocket.bind("inproc://notify"))

local worker = function(_ctx, ...)
	local zmq = require 'zmq'
	local workerId = select(1, ...)
	local context, msg = assert(zmq.context(_ctx))
	
	-- job socket
	local socket,msg = assert(context.socket(zmq.ZMQ_DEALER))
	assert(socket.connect("inproc://main"))

	-- notify socket subscriber
	local nsocket,msg = assert(context.socket(zmq.ZMQ_SUB))
	assert(nsocket.connect("inproc://notify"))
	nsocket.options.subscribe = 'worker'

	local running = true

	local poll = zmq.poll {
		{socket, zmq.ZMQ_POLLIN, function(socket)
			local arg = socket.recvMultipart()

			local job, id = arg[1], arg[2]

			-- a job command
			if job and id then
				local jobFn = loadstring(job)

				local r,m = pcall(jobFn, id)
				if r then
					socket.sendMultipart {tostring(workerId), tostring(m)}
				else
					socket.send(("Worker #%d Error: %s"):format(tonumber(workerId), tostring(m)))
				end
			else
				socket.send(("Worker #%d Unknown command"):format(tonumber(workerId)))
			end
		end},
		{nsocket, zmq.ZMQ_POLLIN, function(socket)
			local arg = socket.recvMultipart()
			local command = arg[2]

			-- a thread close command
			if command == 'close' then
				running = false
			end
		end},
	}

	while running do
		poll.start(100)
	end
	socket.close()
end

do
	local N = 5
	local Njobs = 100
	local threads = {}
	local results = {}

	-- prepare all worker threads
    for i=1,N do
    	local thread = assert(context.thread2(worker, i))
		table.insert(threads, thread)
	end

	local poll = zmq.poll {
		{socket, zmq.ZMQ_POLLIN, function(socket)
			-- store worker result
			local reply = socket.recvMultipart()
			if reply and (#reply >=2 ) then
				local tmp = ("%s - from worker ID: %d"):format(reply[2], tonumber(reply[1]))
				table.insert(results, tmp)
			end
		end},
	}

	-- generic job function sent as a byte-code dump
    local jobFn = string.dump(
    	function(i)
    		return ("Job #%d"):format(tonumber(i))
    	end
    )

	-- generic job function sent as a source string
   	local jobSrc = [==[
   		local i = select(1, ...)
   		return ("Job #%d"):format(tonumber(i))
   	]==]

	print('Ready to process')

	-- send jobs to all workers
    for i=1,Njobs do
    	if i % 2 == 0 then
	    	socket.sendMultipart {jobFn, tostring(i)}
    	else
	    	socket.sendMultipart {jobSrc, tostring(i)}
    	end
    end

	print('Waiting for results')
    -- wait for sufficient amount of results
	while (#results < Njobs) do
		poll.start()
	end

	for _, result in ipairs(results) do
		print(result)
	end

	-- send 'close' command to all workers
   	nsocket.sendMultipart {'worker', 'close'}
end

print('Exiting')
```

## Simple ZeroMQ Web server

```lua
local zmq = require 'zmq'

local context = assert(zmq.context())
local socket = assert(context.socket(zmq.ZMQ_STREAM))
socket.options.stream_notify = true
socket.options.ipv6 = true
assert(socket.bind("tcp://*:80"))

local poll = zmq.poll {
	{socket, zmq.ZMQ_POLLIN, function(socket)
		local identity = socket.options.identity
		local id = assert(socket.recv())
		local data = assert(socket.recv())
		if #data>0 then
			assert(socket.send(id, zmq.ZMQ_SNDMORE))
			assert(socket.send([[
HTTP/1.0 200 OK
Content-Type: text/plain

Hello, World!]], zmq.ZMQ_SNDMORE))

			assert(socket.send(id, zmq.ZMQ_SNDMORE))
			assert(socket.send("", zmq.ZMQ_SNDMORE))
		end
	end},
}

while true do
	poll.start()
end
socket.disconnect()
```

## Simple ZeroMQ Web client

```lua
local zmq = require 'zmq'

local context = assert(zmq.context())
local socket = assert(context.socket(zmq.ZMQ_STREAM))
socket.options.stream_notify = true
socket.options.ipv6 = true
assert(socket.connect("tcp://www.google.com:80"))
local identity = socket.options.identity
local once = false

local poll = zmq.poll {
	{socket, zmq.ZMQ_POLLIN, function(socket)
		local id = assert(socket.recv())
		local data = assert(socket.recv())
		if #data>0 then
			print(("%q\n%q"):format(zmq.tohex(id), data))
		end

		if not once then
			assert(socket.send(id, zmq.ZMQ_SNDMORE))
			assert(socket.send([[
GET / HTTP/1.1

]], zmq.ZMQ_SNDMORE))
			once = true
		end
	end},
}

while true do
	poll.start()
end
socket.disconnect()
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
Copyright 2013, 2014, 2015 Mário Kašuba
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
