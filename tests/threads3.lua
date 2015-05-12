local zmq = require 'zmq'

local CHUNK_SIZE = 25000

local client_thread = [[
	local CHUNK_SIZE,pipeId = unpack(arg)
	--local pipe =  assert(context.pipe(pipeID, 'connect'))

    local dealer = assert(context.socket(zmq.ZMQ_DEALER))
    dealer.options.RCVHWM = 1
    dealer.options.SNDHWM = 1
    dealer.connect("tcp://127.0.0.1:6000")

    local total = 0       -- Total bytes received
    local chunks = 0      -- Total chunks received

    local f1 = io.open("testdata.out","wb")
	local w = zmq.stopwatch()
	print(w)

    while true do
        -- ask for next chunk
        assert(dealer.sendMultipart({
            "fetch",
            string.format("%d", total),
            string.format("%i", CHUNK_SIZE)
        }))

        local chunk,msg = assert(dealer.recv(CHUNK_SIZE))
        --print(string.format("Chunk: %q", chunk), msg or "No error")
        f1:write(chunk)

        chunks = chunks + 1
        size = #chunk
        total = total + size
        if size < CHUNK_SIZE then
            break   -- Last chunk received; exit
        end
	end
	local wr = w.stop()

	f1:close()

	local sec = wr/1000000
	local speed = total/(sec*1000)

    print(string.format("%i chunks received, %i bytes, %0.3f s, average speed: %0.3f KB/s", chunks, total, sec, speed))
    --pipe.send("OK")
]]

--[[
 The server thread waits for a chunk request from a client,
 reads that chunk and sends it back to the client:
]]--

local server_thread = [[
	local CHUNK_SIZE = unpack(arg)
    local f1 = assert(io.open("testdata", "rb"))

    local router = assert(context.socket(zmq.ZMQ_ROUTER))
    router.bind("tcp://*:6000")

    while true do
        -- First frame in each message is the sender identity
        -- Second frame is "fetch" command

        local msg = router.recvMultipart()
        local identity, command, offset_str, chunksz_str = unpack(msg)
        assert(command == "fetch")

        local offset = tonumber(offset_str)
        local chunksz = tonumber(chunksz_str)

        -- Read chunk of data from file
        f1:seek('set', offset)
        
        local data = f1:read(chunksz)

        -- Send resulting chunk to client
        --print('Sending', zmq.tohex(identity))
        router.sendMultipart({identity, data})
	end
]]

-- The main task is just the same as in the first model.

-- generate unique ID
math.randomseed(os.time())
local pipeID = zmq.tohex(string.char(math.random(256)-1, math.random(256)-1, math.random(256)-1, math.random(256)-1))
print("Using address:", pipeID)
local context = zmq.context()
local pipe = context.pipe(pipeID, 'bind')

-- loop until client tells us it's done
--print(pipe.recv())

local context, msg = assert(zmq.context())

local threads = {}

-- client thread
threads[1] = context.thread(client_thread, CHUNK_SIZE, pipeId)

-- server thread
threads[2] = context.thread(server_thread, CHUNK_SIZE)

for i, thread in ipairs(threads) do
	print("Joining #",i)
	thread.join()
	print(thread.result())
end
