--[[
	LuaZMQ - Lua binding for ZeroMQ library

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


	This module uses portion of NumberLua module to offer bitwise AND operation in a case where there's no library for bitwise operations available.
	(Namely: Lua 5.1 and older versions)
	
	https://github.com/davidm/lua-bit-numberlua

	(c) 2008-2011 David Manura.  Licensed under the same terms as Lua (MIT).

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
	THE SOFTWARE.
	(end license)

--]]

local function tryRequire(moduleName)
	local status, M = pcall(require, moduleName)
	if not status then
		return nil, M
	else
		return M
	end
end

local zmq = require 'luazmq'

local bit = tryRequire('bit') or tryRequire('bit32')
local band

if type(bit)=='table' then
	band = bit.band
else
	local floor = math.floor

	local MOD = 2^32
	local MODM = MOD-1

	local function memoize(f)
		local mt = {}
		local t = setmetatable({}, mt)
		function mt:__index(k)
			local v = f(k); t[k] = v
			return v
		end
		return t
	end

	local function make_bitop_uncached(t, m)
		local function bitop(a, b)
			local res,p = 0,1
			while a ~= 0 and b ~= 0 do
				local am, bm = a%m, b%m
				res = res + t[am][bm]*p
				a = (a - am) / m
				b = (b - bm) / m
				p = p*m
			end
			res = res + (a+b)*p
			return res
		end
		return bitop
	end

	local function make_bitop(t)
		local op1 = make_bitop_uncached(t,2^1)
		local op2 = memoize(function(a)
			return memoize(function(b)
				return op1(a, b)
			end)
		end)
		return make_bitop_uncached(op2, 2^(t.n or 1))
	end

	local bxor = make_bitop {[0]={[0]=0,[1]=1},[1]={[0]=1,[1]=0}, n=4}
	band = function(a,b) return ((a+b) - bxor(a,b))/2 end
end

local M = {}

local constants = {
	ZMQ_PAIR = 					0,
    ZMQ_PUB =					1,
    ZMQ_SUB =					2,
    ZMQ_REQ =					3,
    ZMQ_REP =					4,
    ZMQ_DEALER =				5,
    ZMQ_ROUTER =				6,
    ZMQ_PULL =					7,
    ZMQ_PUSH =					8,
    ZMQ_XPUB =					9,
    ZMQ_XSUB =					10,
    ZMQ_STREAM =				11,

    ZMQ_XREQ = 					5, --ZMQ_DEALER
    ZMQ_XREP = 					6, --ZMQ_ROUTER

    ZMQ_SERVER =				12,
    ZMQ_CLIENT =				13,
                       	
    ZMQ_AFFINITY =				4,
    ZMQ_IDENTITY =				5,
    ZMQ_SUBSCRIBE =				6,
    ZMQ_UNSUBSCRIBE =			7,
    ZMQ_RATE =					8,
    ZMQ_RECOVERY_IVL =			9,
    ZMQ_SNDBUF =				11,
    ZMQ_RCVBUF =				12,
    ZMQ_RCVMORE =				13,
    ZMQ_FD =					14,
    ZMQ_EVENTS =				15,
    ZMQ_TYPE =					16,
    ZMQ_LINGER =				17,
    ZMQ_RECONNECT_IVL =			18,
    ZMQ_BACKLOG =				19,
    ZMQ_RECONNECT_IVL_MAX =		21,
    ZMQ_MAXMSGSIZE =			22,
    ZMQ_SNDHWM =				23,
    ZMQ_RCVHWM =				24,
    ZMQ_MULTICAST_HOPS =		25,
    ZMQ_RCVTIMEO =				27,
    ZMQ_SNDTIMEO =				28,
    ZMQ_LAST_ENDPOINT =			32,
    ZMQ_ROUTER_MANDATORY =		33,
    ZMQ_TCP_KEEPALIVE =			34,
    ZMQ_TCP_KEEPALIVE_CNT =		35,
    ZMQ_TCP_KEEPALIVE_IDLE =	36,
    ZMQ_TCP_KEEPALIVE_INTVL =	37,
    ZMQ_TCP_ACCEPT_FILTER =		38,
    ZMQ_IMMEDIATE =				39,
    ZMQ_XPUB_VERBOSE =			40,
    ZMQ_ROUTER_RAW =			41,
    ZMQ_IPV6 =					42,
    ZMQ_MECHANISM =				43,
    ZMQ_PLAIN_SERVER =			44,
    ZMQ_PLAIN_USERNAME =		45,
    ZMQ_PLAIN_PASSWORD =		46,
    ZMQ_CURVE_SERVER =			47,
    ZMQ_CURVE_PUBLICKEY =		48,
    ZMQ_CURVE_SECRETKEY =		49,
    ZMQ_CURVE_SERVERKEY =		50,
    ZMQ_PROBE_ROUTER =			51,
    ZMQ_REQ_CORRELATE =			52,
    ZMQ_REQ_RELAXED =			53,
    ZMQ_CONFLATE =				54,
    ZMQ_ZAP_DOMAIN =			55,

	ZMQ_ROUTER_HANDOVER = 		56,
	ZMQ_TOS =					57,
	ZMQ_CONNECT_RID =			61,
	ZMQ_GSSAPI_SERVER =			62,
	ZMQ_GSSAPI_PRINCIPAL =		63,
	ZMQ_GSSAPI_SERVICE_PRINCIPAL =	64,
	ZMQ_GSSAPI_PLAINTEXT =		65,
	ZMQ_HANDSHAKE_IVL =			66,
	ZMQ_SOCKS_PROXY =			68,
	ZMQ_XPUB_NODROP =			69,
	ZMQ_BLOCKY =				70,
	ZMQ_XPUB_MANUAL =			71,
	ZMQ_XPUB_WELCOME_MSG =		72,
	ZMQ_STREAM_NOTIFY =			73,
	ZMQ_INVERT_MATCHING = 		74,
	ZMQ_HEARTBEAT_IVL = 		75,
	ZMQ_HEARTBEAT_TTL = 		76,
	ZMQ_HEARTBEAT_TIMEOUT = 	77,
	ZMQ_XPUB_VERBOSE_UNSUBSCRIBE = 	78,
	ZMQ_CONNECT_TIMEOUT = 		79,
	ZMQ_TCP_RETRANSMIT_TIMEOUT =	80,
	ZMQ_THREAD_SAFE = 			81,
	ZMQ_TCP_RECV_BUFFER =		82,
	ZMQ_TCP_SEND_BUFFER =		83,
	ZMQ_MULTICAST_MAXTPDU =		84,
	ZMQ_VMCI_BUFFER_SIZE =		85,
	ZMQ_VMCI_BUFFER_MIN_SIZE =	86,
	ZMQ_VMCI_BUFFER_MAX_SIZE =	87,
	ZMQ_VMCI_CONNECT_TIMEOUT =	88,

	ZMQ_MORE =					1,
	ZMQ_SRCFD = 				2,
	ZMQ_SHARED = 				3,

	ZMQ_DONTWAIT =				1,
	ZMQ_SNDMORE =				2,

	ZMQ_NULL =					0,
	ZMQ_PLAIN =					1,
	ZMQ_CURVE =					2,
	ZMQ_GSSAPI = 				3,

	ZMQ_EVENT_CONNECTED =		0x0001,
	ZMQ_EVENT_CONNECT_DELAYED =	0x0002,
	ZMQ_EVENT_CONNECT_RETRIED =	0x0004,
	ZMQ_EVENT_LISTENING =		0x0008,
	ZMQ_EVENT_BIND_FAILED =		0x0010,
	ZMQ_EVENT_ACCEPTED =		0x0020,
	ZMQ_EVENT_ACCEPT_FAILED =	0x0040,
	ZMQ_EVENT_CLOSED =			0x0080,
	ZMQ_EVENT_CLOSE_FAILED =	0x0100,
	ZMQ_EVENT_DISCONNECTED =	0x0200,
	ZMQ_EVENT_MONITOR_STOPPED =	0x0400,
	ZMQ_EVENT_ALL =				0xFFFF,

	ZMQ_POLLIN =				1,
	ZMQ_POLLOUT =				2,
	ZMQ_POLLERR =				4,
	ZMQ_POLLPRI =				8,

	ZMQ_IO_THREADS = 			1,
	ZMQ_MAX_SOCKETS = 			2,
	ZMQ_SOCKET_LIMIT = 			3,
	ZMQ_THREAD_PRIORITY = 		3,
	ZMQ_THREAD_SCHED_POLICY = 	4,

	ZMQ_IO_THREADS_DFLT = 		1,
	ZMQ_MAX_SOCKETS_DFLT = 		1023,
	ZMQ_THREAD_PRIORITY_DFLT = 	-1,
	ZMQ_THREAD_SCHED_POLICY_DFLT = -1,
}

local socket_option_names = {
    ['AFFINITY'] = 				constants.ZMQ_AFFINITY,
    ['IDENTITY'] = 				constants.ZMQ_IDENTITY,
    ['SUBSCRIBE'] = 			constants.ZMQ_SUBSCRIBE,
    ['UNSUBSCRIBE'] = 			constants.ZMQ_UNSUBSCRIBE,
    ['RATE'] = 					constants.ZMQ_RATE,
    ['RECOVERY_IVL'] = 			constants.ZMQ_RECOVERY_IVL,
    ['SNDBUF'] = 				constants.ZMQ_SNDBUF,
    ['RCVBUF'] = 				constants.ZMQ_RCVBUF,
    ['RCVMORE'] = 				constants.ZMQ_RCVMORE,
    ['FD'] = 					constants.ZMQ_FD,
    ['EVENTS'] = 				constants.ZMQ_EVENTS,
    ['TYPE'] = 					constants.ZMQ_TYPE,
    ['LINGER'] = 				constants.ZMQ_LINGER,
    ['RECONNECT_IVL'] = 		constants.ZMQ_RECONNECT_IVL,
    ['BACKLOG'] = 				constants.ZMQ_BACKLOG,
    ['RECONNECT_IVL_MAX'] = 	constants.ZMQ_RECONNECT_IVL_MAX,
    ['MAXMSGSIZE'] = 			constants.ZMQ_MAXMSGSIZE,
    ['SNDHWM'] = 				constants.ZMQ_SNDHWM,
    ['RCVHWM'] = 				constants.ZMQ_RCVHWM,
    ['MULTICAST_HOPS'] = 		constants.ZMQ_MULTICAST_HOPS,
    ['RCVTIMEO'] = 				constants.ZMQ_RCVTIMEO,
    ['SNDTIMEO'] = 				constants.ZMQ_SNDTIMEO,
    ['LAST_ENDPOINT'] = 		constants.ZMQ_LAST_ENDPOINT,
    ['ROUTER_MANDATORY'] = 		constants.ZMQ_ROUTER_MANDATORY,
    ['TCP_KEEPALIVE'] = 		constants.ZMQ_TCP_KEEPALIVE,
    ['TCP_KEEPALIVE_CNT'] = 	constants.ZMQ_TCP_KEEPALIVE_CNT,
    ['TCP_KEEPALIVE_IDLE'] = 	constants.ZMQ_TCP_KEEPALIVE_IDLE,
    ['TCP_KEEPALIVE_INTVL'] = 	constants.ZMQ_TCP_KEEPALIVE_INTVL,
    ['TCP_ACCEPT_FILTER'] = 	constants.ZMQ_TCP_ACCEPT_FILTER,
    ['IMMEDIATE'] = 			constants.ZMQ_IMMEDIATE,
    ['XPUB_VERBOSE'] = 			constants.ZMQ_XPUB_VERBOSE,
    ['ROUTER_RAW'] = 			constants.ZMQ_ROUTER_RAW,
    ['IPV6'] = 					constants.ZMQ_IPV6,
    ['MECHANISM'] = 			constants.ZMQ_MECHANISM,
    ['PLAIN_SERVER'] = 			constants.ZMQ_PLAIN_SERVER,
    ['PLAIN_USERNAME'] = 		constants.ZMQ_PLAIN_USERNAME,
    ['PLAIN_PASSWORD'] = 		constants.ZMQ_PLAIN_PASSWORD,
    ['CURVE_SERVER'] = 			constants.ZMQ_CURVE_SERVER,
    ['CURVE_PUBLICKEY'] = 		constants.ZMQ_CURVE_PUBLICKEY,
    ['CURVE_SECRETKEY'] = 		constants.ZMQ_CURVE_SECRETKEY,
    ['CURVE_SERVERKEY'] = 		constants.ZMQ_CURVE_SERVERKEY,
    ['PROBE_ROUTER'] = 			constants.ZMQ_PROBE_ROUTER,
    ['REQ_CORRELATE'] = 		constants.ZMQ_REQ_CORRELATE,
    ['REQ_RELAXED'] = 			constants.ZMQ_REQ_RELAXED,
    ['CONFLATE'] = 				constants.ZMQ_CONFLATE,
    ['ZAP_DOMAIN'] =			constants.ZMQ_ZAP_DOMAIN,
    ['ROUTER_HANDOVER'] =		constants.ZMQ_ROUTER_HANDOVER,
	['TOS'] =					constants.ZMQ_TOS,
	['CONNECT_RID'] =			constants.ZMQ_CONNECT_RID,
	['GSSAPI_SERVER'] =			constants.ZMQ_GSSAPI_SERVER,
	['GSSAPI_PRINCIPAL'] =		constants.ZMQ_GSSAPI_PRINCIPAL,
	['GSSAPI_SERVICE_PRINCIPAL'] =	constants.ZMQ_GSSAPI_SERVICE_PRINCIPAL,
	['GSSAPI_PLAINTEXT'] =		constants.ZMQ_GSSAPI_PLAINTEXT,
	['HANDSHAKE_IVL'] =			constants.ZMQ_HANSHAKE_IVL,
	['SOCKS_PROXY'] =			constants.ZMQ_SOCKS_PROXY,
	['XPUB_NODROP'] =			constants.ZMQ_XPUB_NODROP,
	['BLOCKY'] =				constants.ZMQ_BLOCKY,
	['XPUB_MANUAL'] =			constants.ZMQ_XPUB_MANUAL,
	['XPUB_WELCOME_MSG'] =		constants.ZMQ_XPUB_WELCOME_MSG,
	['STREAM_NOTIFY'] =			constants.ZMQ_STREAM_NOTIFY,
}

local socket_options = {
    [constants.ZMQ_AFFINITY] =				'i64',
    [constants.ZMQ_IDENTITY] =				's',
    [constants.ZMQ_SUBSCRIBE] =				's',
    [constants.ZMQ_UNSUBSCRIBE] =			's',
    [constants.ZMQ_RATE] =					'i',
    [constants.ZMQ_RECOVERY_IVL] =			'i',
    [constants.ZMQ_SNDBUF] =				'i',
    [constants.ZMQ_RCVBUF] =				'i',
    [constants.ZMQ_RCVMORE] =				'b',
    [constants.ZMQ_FD] =					'iptr',
    [constants.ZMQ_EVENTS] =				'i',
    [constants.ZMQ_TYPE] =					'i',
    [constants.ZMQ_LINGER] =				'i',
    [constants.ZMQ_RECONNECT_IVL] =			'i',
    [constants.ZMQ_BACKLOG] =				'i',
    [constants.ZMQ_RECONNECT_IVL_MAX] =		'i',
    [constants.ZMQ_MAXMSGSIZE] =			'i64',
    [constants.ZMQ_SNDHWM] =				'i',
    [constants.ZMQ_RCVHWM] =				'i',
    [constants.ZMQ_MULTICAST_HOPS] =		'i',
    [constants.ZMQ_RCVTIMEO] =				'i',
    [constants.ZMQ_SNDTIMEO] =				'i',
    [constants.ZMQ_LAST_ENDPOINT] =			's',
    [constants.ZMQ_ROUTER_MANDATORY] =		'i',
    [constants.ZMQ_TCP_KEEPALIVE] =			'i',
    [constants.ZMQ_TCP_KEEPALIVE_CNT] =		'i',
    [constants.ZMQ_TCP_KEEPALIVE_IDLE] =	'i',
    [constants.ZMQ_TCP_KEEPALIVE_INTVL] =	'i',
    [constants.ZMQ_TCP_ACCEPT_FILTER] =		's',
    [constants.ZMQ_IMMEDIATE] =				'i',
    [constants.ZMQ_XPUB_VERBOSE] =			'i',
    [constants.ZMQ_ROUTER_RAW] =			'b',
    [constants.ZMQ_IPV6] =					'b',
    [constants.ZMQ_MECHANISM] =				'i',
    [constants.ZMQ_PLAIN_SERVER] =			'b',
    [constants.ZMQ_PLAIN_USERNAME] =		's',
    [constants.ZMQ_PLAIN_PASSWORD] =		's',
    [constants.ZMQ_CURVE_SERVER] =			'b',
    [constants.ZMQ_CURVE_PUBLICKEY] =		's',
    [constants.ZMQ_CURVE_SECRETKEY] =		's',
    [constants.ZMQ_CURVE_SERVERKEY] =		's',
    [constants.ZMQ_PROBE_ROUTER] =			'i',
    [constants.ZMQ_REQ_CORRELATE] =			'b',
    [constants.ZMQ_REQ_RELAXED] =			'b',
    [constants.ZMQ_CONFLATE] =				'b',
    [constants.ZMQ_ZAP_DOMAIN] =			's',
    [constants.ZMQ_ROUTER_HANDOVER] =		'b',
	[constants.ZMQ_TOS] =					'i',
	[constants.ZMQ_CONNECT_RID] =			's',
	[constants.ZMQ_GSSAPI_SERVER] =			'b',
	[constants.ZMQ_GSSAPI_PRINCIPAL] =		's',
	[constants.ZMQ_GSSAPI_SERVICE_PRINCIPAL] =	's',
	[constants.ZMQ_GSSAPI_PLAINTEXT] =		'b',
	[constants.ZMQ_HANDSHAKE_IVL] =			'i',
	[constants.ZMQ_SOCKS_PROXY] =			's',
	[constants.ZMQ_XPUB_NODROP] =			'b',
	[constants.ZMQ_BLOCKY] =				'b',
	[constants.ZMQ_XPUB_MANUAL] =			'b',
	[constants.ZMQ_XPUB_WELCOME_MSG] =		'b',
	[constants.ZMQ_STREAM_NOTIFY] =			'b',
}

local setupSocket
local DEFAULT_BUFFER_SIZE = 4096

M.setBufferSize = function(value)
	DEFAULT_BUFFER_SIZE = value
end

M.context = function(context, io_threads, DEBUG)
	local contextOwner
	if context then
		contextOwner = false
	else
		contextOwner = true
	end
	local context, msg = context or assert(zmq.init(io_threads))
	
	if not context then
		return false, msg
	end

	local options = {}
	setmetatable(options, {
		__index = function(t, name)
		    local optionID
			if type(name)=='string' then
				optionID = socket_option_names[name:upper()]
				assert(optionID, 'Unknown option')
			elseif type(name)=='number' then
			    optionID = name
			else
				error('Unknown option')
			end
			return zmq.get(context, optionID)
		end,
		__newindex = function(t, name, value)
		    local optionID
			if type(name)=='string' then
				optionID = socket_option_names[name:upper()]
				assert(optionID, 'Unknown option')
			elseif type(name)=='number' then
			    optionID = name
			else
				error('Unknown option')
			end

			local optionValue
			if type(value)=='boolean' then
				optionValue = value and 1 or 0
			else
				optionValue = tonumber(value)
			end
			zmq.set(context, optionID, optionValue)
		end,
	})

	local lfn = {
		socket = function(_type)
			local socket, msg = zmq.socket(context, _type)
			if not socket then
				return false, msg
			end

			function setupSocket(socket)
				local socket = socket
				local closed = false
				local options = {}
		
				setmetatable(options, {
					__index = function(t, name)
						local index
						if type(name)=="number" then
							index = name
						elseif type(name) == "string" then
							index = socket_option_names[string.upper(name)]
						end

						local _type = socket_options[index]
						if _type then
							if _type == 'i32' or _type=='i' then
								return assert(zmq.socketGetOptionI32(socket, index))
							elseif _type == 'i64' then
								return assert(zmq.socketGetOptionI64(socket, index))
							elseif _type == 'iptr' then
								return assert(zmq.socketGetOptionIptr(socket, index))
							elseif _type == 's' then
								return assert(zmq.socketGetOptionS(socket, index))
							elseif _type == 'b' then
								return assert(zmq.socketGetOptionI32(socket, index) == 1)
							else
								error('Unknown socket option')
							end
						end
					end,
					__newindex = function(t, name, value)
						local index
						if type(name)=="number" then
							index = name
						elseif type(name) == "string" then
							index = socket_option_names[string.upper(name)]
						end

						local _type = socket_options[index]
						if _type then
							if _type == 'i32' or _type == 'i' then
								return assert(zmq.socketSetOptionI32(socket, index, tonumber(value)))
							elseif _type == 'i64' then
								return assert(zmq.socketSetOptionI64(socket, index, tonumber(value)))
							elseif _type == 'iptr' then
								return assert(zmq.socketSetOptionIptr(socket, index, tonumber(value)))
							elseif _type == 's' then
								return assert(zmq.socketSetOptionS(socket, index, tostring(value)))
							elseif _type == 'b' then
								return assert(zmq.socketSetOptionI32(socket, index, (value and 1) or 0))
							end
						end
					end,
				})

				local lfn = {
					connect = function(endpoint)
						return zmq.connect(socket, endpoint)
					end,
					disconnect = function(endpoint)
						return zmq.disconnect(socket, endpoint)
					end,
					bind = function(endpoint)
						return zmq.bind(socket, endpoint)
					end,
					unbind = function(endpoint)
						return zmq.unbind(socket, endpoint)
					end,
					recv = function(len, flags)
						return zmq.recv(socket, len, flags)
					end,
					recvAll = function(flags)
						return zmq.recvAll(socket, flags)
					end,
					send = function(str, flags)
						local str = str or ''
						return zmq.send(socket, str, flags)
					end,
					recvMultipart = function(bufferLength)
						return zmq.recvMultipart(socket, flags, bufferLength or DEFAULT_BUFFER_SIZE)
					end,
					sendMultipart = function(t, flags, bufferLength)
						return zmq.sendMultipart(socket, t, flags, bufferLength or DEFAULT_BUFFER_SIZE)
					end,
					sendID = function(id)
						assert(id)
						return zmq.sendMultipart(socket, {id, ''}, constants.ZMQ_SNDMORE)
					end,
					close = function()
						if not closed then
							assert(zmq.close(socket))
							closed = true
						end
					end,
					msg = function(size)
						local zmsg,msg
						if type(size)=="string" then
							zmsg,msg = zmq.msgInit(#size)
							if zmsg then
							   zmq.msgSetData(zmsg, size)
							end
						elseif type(size) == "number" then
							zmsg,msg = zmq.msgInit(size)
						else
							zmsg,msg = zmq.msgInit()
						end
						if not zmsg then
							return false, msg
						end

						local options = {}
						setmetatable(options, {
							__index = function(t, name)
								return zmq.msgGet(zmsg, name)
							end,
							__newindex = function(t, name, value)
								zmq.msgSet(zmsg, name, value)
							end,						
						})

						local lfn = {
							options = options,

							copy = function(dest)
								return zmq.msgCopy(zmsg, dest)
							end,
							move = function(dest)
								return zmq.msgMove(zmsg, dest)
							end,
							send = function(flags)
								return zmq.msgSend(zmsg, socket, flags)
							end,
							recv = function(flags)
								return zmq.msgRecv(zmsg, socket, flags)
							end,
						}

						local mt = getmetatable(zmsg)
						mt.__index = function(t, fn)
							if (fn == "size") then
								return zmq.msgSize(zmsg)
							elseif (fn == "more") then
								return (zmq.msgMore(zmsg) == 1)
							elseif (fn == "data") then
								return zmq.msgGetData(zmsg)
							else
								return lfn[fn]
							end
						end
						mt.__newindex = function(t, name, value)
							if name == "data" then
								zmq.msgSetData(zmsg, value)
							end
						end
						mt.__gc = function()
							if DEBUG then
								print('Closing msg object')
							end
							zmq.msgClose(zmsg)
						end

						return zmsg
					end,
					options = options,
					monitor = function(endpoint, events)
						return zmq.socketMonitor(socket, endpoint, events)
					end,
				}

				local mt = getmetatable(socket)
				mt.__index = function(t, fn)
					if fn == "more" then
						local more = zmq.socketGetOptionI32(socket, constants.ZMQ_RCVMORE)
						return (more == 1)
					else
						return lfn[fn]
					end
				end
				mt.__newindex = function()
				end
				mt.__gc = function()
					if DEBUG then
						print('Closing socket')
					end
					lfn.close()
				end
				return socket
			end

			return setupSocket(socket)
		end,
		shutdown = function()
			assert(zmq.shutdown(context))
		end,
		thread = function(code, ...)
			local arg = {...}
			local finalCode = {[[
local zmq = require 'zmq'
local context = assert(zmq.context(assert(select(1, ...))))
local arg = {]]}
			
			for _, value in ipairs(arg) do
				if type(value)=="bool" then
					table.insert(finalCode, tostring(value))
				elseif type(value)=="number" then
					table.insert(finalCode, tostring(value))
				elseif type(value)=="string" then
					table.insert(finalCode, string.format("%q", value))
				elseif type(value)=="function" then
					table.insert(finalCode, string.format("loadstring(%q)", string.dump(value)))
				else
					error("Thread parameters can be booleans, numbers, string and functions w/o upvalues")
				end
				table.insert(finalCode, ',')
			end
			table.insert(finalCode, "}\n")
			table.insert(finalCode, code)
			local code = table.concat(finalCode)

			local thread = zmq.thread(context, code, DEBUG)
			local mt = getmetatable(thread)
			local lfn = {
				join = function()
					zmq.joinThread(thread)
				end,
				result = function()
					return zmq.getThreadResult(thread)
				end
			}
			mt.__index = function(t, fn)
				return lfn[fn]
			end
			mt.__gc = function()
				zmq.freeThread(thread)
			end

			return thread
		end,
		pipe = function(id, pairType)
			local pair = assert(context.socket(constants.ZMQ_PAIR))
			pair.options.LINGER = 0
			pair.options.SNDHWM = 1
			pair.options.RCVHWM = 1

			if pairType=="bind" then
				pair.bind("inproc://"..id)
			elseif pairType=="connext" then
				pair.connect("inproc://"..id)
			end
			return pair
		end,
		options = options,
	}
	local mt = getmetatable(context)
	mt.__index = function(t, fn)
		return lfn[fn]
	end
	mt.__gc = function()
		if contextOwner then
			if DEBUG then
				print('Closing context')
			end
			assert(zmq.term(context))
		end
	end
	return context
end

M.version = function()
	return zmq.version()
end

M.sleep = function(n)
	zmq.sleep(n)
end

M.stopwatch = function()
	local stopwatch = zmq.stopwatchStart()
	local closed = false
	local lfn = {
		stop = function()
			if not closed then
				closed = true
				return zmq.stopwatchStop(stopwatch)
			end
		end,
	}
	local mt = getmetatable(stopwatch)
	mt.__index = function(t, fn)
		return lfn[fn]
	end
	mt.__gc = function()
		lfn.stop()
	end
	return stopwatch
end

M.poll = function(initPollItems)
	local poll = zmq.pollNew()
	local pollItems = {}
	setmetatable(pollItems, { __mode = 'k'})
	local items = {}

	setmetatable(items, {
		__index = function(t, id)
			local v = zmq.pollGet(poll, id)
			if v then
				local s = v.socket
				local i = pollItems[s]
				return {socket = s, revents = v.revents, flags = i[1], fn = i[2]}
			end
		end,
		__newindex = function(t, id, v)
			local s = v.socket
			local flags = v.flags
			pollItems[s] = {flags, v.fn}
			zmq.pollSet(poll, id, {socket = s, fd = 0, events = flags, revents = 0})
		end,
		__len = function(t)
			return zmq.pollSize(poll)
		end,
	})

	local socketCache = {}
	setmetatable(socketCache, {
		__mode = 'v',
	})
	local function getRawSocket(s)
		local smt = getmetatable(s)
		if smt then
			return smt.__raw
		end
	end

	local lfn = {
		items = items,
		start = function(timeout)
			local signaledItems = assert(zmq.poll(poll, timeout))
			if signaledItems > 0 then
				local size = zmq.pollSize(poll)
				for i=0,size-1 do
					local v = zmq.pollGet(poll, i) 
					if v then
						local rawSocket = getRawSocket(v.socket)
						local s = socketCache[rawSocket]
						assert(s, 'Invalid socket')
						local pollItem = pollItems[i+1]

						if pollItem then
							if band(v.revents, pollItem[1]) > 0 then
								local flags = pollItem[1]
								local fn = pollItem[2]
								if type(fn) == "function" then
									fn(s, v.revents)
								end
							end
						end
					end
				end
			end
		end,
		add = function(s, flags, fn)
			local rawSocket = getRawSocket(s)
			
			table.insert(pollItems, {flags, fn})

			if not socketCache[rawSocket] then
				socketCache[rawSocket] = s
			end

			zmq.pollSet(poll,
				{socket = s, fd = s.options.FD, events = flags, revents = 0}
			)
		end,
	}

	local mt = getmetatable(poll)
	mt.__index = function(t, fn)
		return lfn[fn]
	end
	mt.__gc = function()
		zmq.pollFree(poll)
	end

	if type(initPollItems)=='table' then
		for _, pollItem in pairs(initPollItems) do
			if type(pollItem)=='table' then
				local socket, pollType, fn = unpack(pollItem)
				poll.add(socket, pollType, fn)
			end
		end
	end
	return poll
end

M.atomic = function()
    local counter = zmq.atomicCounterNew()

    local lfn = {
    	inc = function()
    		return zmq.atomicCounterInc(counter)
    	end,
    	dec = function()
    		return zmq.atomicCounterDec(counter)
    	end,
    }

	local mt = getmetatable(counter)
	mt.__index = function(t, fn)
		if fn=='value' then
			return zmq.atomicCounterValue(counter)
		else
			return lfn[fn]
		end
	end
	mt.__newindex = function(t, fn, v)
		if fn=='value' then
			assert(type(v)=='number')
			return zmq.atomicCounterSet(counter, v)
		end		
	end
	mt.__gc = function()
		zmq.atomicCounterDestroy(counter)
	end
	return counter
end

M.proxy = function(forward, backend, capture)
	zmq.proxy(forward, backend, capture)
end

M.Z85_encode = function(str)
	return zmq.Z85Encode(str)
end

M.Z85_decode = function(str)
	return zmq.Z85Decode(str)
end

M.curveKeypair = function(str)
	return zmq.curveKeypair()
end

M.tohex = function(s, sep)
	local t = {}
	for i=1,#s do
		table.insert(t, string.format("%02X", string.byte(s, i)))
	end
	return table.concat(t, sep)
end

M.ID = function(n)
	local n = n or 8
	math.randomseed(os.time())
	local t = {}
	for i=1,n do
		t[i] = math.random(256)-1
	end
	return M.Z85_encode(string.char(unpack(t)))
end

M.has = zmq.has

setmetatable(M, {
	__index = constants,
	__newindex = function(t, n, v)
	end,
})

return M