/*
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
*/

#include "common.h"
#include <thread>

namespace LuaZMQ {
	struct pollArray_t {
		std::vector<zmq_pollitem_t> items;
	};

	inline void lua_pushZMQ_error(lutok2::State & state){
		state.stack->push<const std::string &>(zmq_strerror(zmq_errno()));
	}

	struct threadData {
		std::thread thread;
		std::string result;
	};

#define BUFFER_SIZE	4096
#define MAX_BUFFER_SIZE 1024*1024*16	//Maximum buffer size for recvMultipart

#define getZMQobject(n) *(static_cast<void**>(stack->to<void*>((n))))
#define getThread(n) *(static_cast<threadData **>(stack->to<void*>((n))))
#define pushUData(v) {void ** s = static_cast<void**>(stack->newUserData(sizeof(void*))); *s = (v); stack->newTable(); stack->setMetatable();}
#define pushSocket(v) {void ** s = static_cast<void**>(stack->newUserData(sizeof(void*)));	*s = (v); stack->newTable(); stack->setField<void*>("__raw", (v)); stack->setMetatable();}

	int lua_zmqInit(lutok2::State & state){
		void * context = zmq_ctx_new();
		Stack * stack = state.stack;
		if (!context){
			stack->push<bool>(false);
			lua_pushZMQ_error(state);
			return 2;
		}else{
			pushUData(context);
			return 1;
		}
	}

	int lua_zmqTerm(lutok2::State & state){
		Stack * stack = state.stack;
		if (state.stack->is<LUA_TUSERDATA>(1)){
			if (zmq_ctx_term(getZMQobject(1)) != 0){
				state.stack->push<bool>(false);
				lua_pushZMQ_error(state);
				return 2;
			}
		}
		return 0;
	}

	int lua_zmqShutdown(lutok2::State & state){
		Stack * stack = state.stack;
		if (state.stack->is<LUA_TUSERDATA>(1)){
			if (zmq_ctx_shutdown(getZMQobject(1)) != 0){
				state.stack->push<bool>(false);
				lua_pushZMQ_error(state);
				return 2;
			}
		}
		return 0;
	}

	int lua_zmqThread(lutok2::State & state){
		Stack * stack = state.stack;
		int parameters_count = stack->getTop();
		if ((parameters_count >= 2) && stack->is<LUA_TUSERDATA>(1) && stack->is<LUA_TSTRING>(2)){
			bool debug = false;
			if (stack->is<LUA_TBOOLEAN>(3)){
				debug = stack->to<bool>(3);
			}
			//shared variables
			const std::string code = stack->to<const std::string>(2);
			void * zmqObj = getZMQobject(1);

			threadData * luaThread = new threadData;

			luaThread->thread = std::thread([&](std::string & code, void * zmqObj, std::string & result){
				lutok2::State & thread_state = lutok2::State();
				thread_state.openLibs();
				try{
					thread_state.loadString(code);

					void ** s = static_cast<void**>(thread_state.stack->newUserData(sizeof(void*)));
					*s = zmqObj;
					thread_state.stack->newTable();
					thread_state.stack->setMetatable();

					thread_state.stack->pcall(1,0,0);
				}catch(std::exception & e){
					result = e.what();
					if (debug){
						printf("Thread error: %s\n",e.what());
					}
				}
			}, code, zmqObj, std::ref(luaThread->result));
			pushUData(luaThread);
			return 1;
		}else{
			stack->push<bool>(false);
			stack->push<const std::string &>("Two parameters are expected: ZMQ context and thread code!");
			return 2;
		}
		return 0;
	}

	int lua_zmqGetThreadResult(lutok2::State & state){
		Stack * stack = state.stack;
		if (stack->is<LUA_TUSERDATA>(1)){
			threadData * luaThread = getThread(1);
			stack->push<const std::string &>(luaThread->result);
			return 1;
		}
		return 1;
	}

	int lua_zmqJoinThread(lutok2::State & state){
		Stack * stack = state.stack;
		if (stack->is<LUA_TUSERDATA>(1)){
			threadData * luaThread = getThread(1);
			if (luaThread->thread.joinable()){
				luaThread->thread.join();
			}else{
				luaThread->thread.detach();
			}
		}
		return 0;
	}

	int lua_zmqFreeThread(lutok2::State & state){
		Stack * stack = state.stack;
		if (stack->is<LUA_TUSERDATA>(1)){
			threadData * luaThread = getThread(1);
			delete luaThread;
		}
		return 0;
	}

	int lua_zmqGet(lutok2::State & state){
		Stack * stack = state.stack;
		if (stack->is<LUA_TUSERDATA>(1) && stack->is<LUA_TNUMBER>(2)){
			int result = zmq_ctx_get(getZMQobject(1), stack->to<int>(2));
			if (result == -1){
				stack->push<bool>(false);
				lua_pushZMQ_error(state);
				return 2;
			}else{
				stack->push<int>(result);
				return 1;
			}
		}
		return 0;
	}

	int lua_zmqSet(lutok2::State & state){
		Stack * stack = state.stack;
		if (stack->is<LUA_TUSERDATA>(1) && stack->is<LUA_TNUMBER>(2) && stack->is<LUA_TNUMBER>(3)){
			if (zmq_ctx_set(getZMQobject(1), stack->to<int>(2), stack->to<int>(3)) == -1){
				stack->push<bool>(false);
				lua_pushZMQ_error(state);
				return 2;
			}
		}
		return 0;
	}

	int lua_zmqSocket(lutok2::State & state){
		Stack * stack = state.stack;
		if (stack->is<LUA_TUSERDATA>(1) && stack->is<LUA_TNUMBER>(2)){
			int type = stack->to<int>(2);
			void * context = getZMQobject(1);
			void * socket = zmq_socket(context, type);
			if (socket){
				pushSocket(socket);
				return 1;
			}else{
				stack->push<bool>(false);
				lua_pushZMQ_error(state);
				return 2;
			}
		}
		stack->push<bool>(false);
		return 1;
	}

	int lua_zmqClose(lutok2::State & state){
		Stack * stack = state.stack;
		if (stack->is<LUA_TUSERDATA>(1)){
			if (zmq_close(getZMQobject(1)) != 0){
				stack->push<bool>(false);
				lua_pushZMQ_error(state);
				return 2;
			}
		}
		return 0;
	}

	int lua_zmqSetSockOpt(lutok2::State & state){
		Stack * stack = state.stack;
		if (stack->is<LUA_TUSERDATA>(1) && stack->is<LUA_TNUMBER>(2)){
			const void * value = nullptr;
			std::string str;
			size_t size = 0;
			int option = stack->to<int>(2);
			if (stack->is<LUA_TNUMBER>(3)){
				int v = stack->to<int>(3);
				value = static_cast<const void *>(&v);
				size = sizeof(v);
			}else if (stack->is<LUA_TSTRING>(3)){
				str = stack->to<const std::string>();
				value = const_cast<const char *>(str.c_str());
				size = str.length();
			}
			int result = zmq_setsockopt(getZMQobject(1), option, value, size);
			if (result == -1){
				stack->push<bool>(false);
				lua_pushZMQ_error(state);
				return 2;
			}else{
				stack->push<bool>(true);
				return 1;
			}
		}
		return 0;
	}

	int lua_zmqGetSockOptI(lutok2::State & state){
		Stack * stack = state.stack;
		if (stack->is<LUA_TUSERDATA>(1) && stack->is<LUA_TNUMBER>(2)){
			int v = 0;
			void * value = &v;
			size_t size = sizeof(v);
			int option = stack->to<int>(2);

			if (zmq_getsockopt(getZMQobject(1), option, value, &size) == -1){
				stack->push<bool>(false);
				lua_pushZMQ_error(state);
				return 2;
			}else{
				stack->push<int>(v);
				return 1;
			}
		}
		return 0;
	}
	int lua_zmqGetSockOptS(lutok2::State & state){
		Stack * stack = state.stack;
		if (stack->is<LUA_TUSERDATA>(1) && stack->is<LUA_TNUMBER>(2)){
			char v[1024];
			void * value = v;
			size_t size = sizeof(v);
			int option = stack->to<int>(2);

			if (zmq_getsockopt(getZMQobject(1), option, value, &size) == -1){
				stack->push<bool>(false);
				lua_pushZMQ_error(state);
				return 2;
			}else{
				stack->pushLString(std::string(v, size));
				return 1;
			}
		}
		return 0;
	}

	int lua_zmqPollNew(lutok2::State & state){
		Stack * stack = state.stack;
		pollArray_t * poll = new pollArray_t;
		if (poll){
			if (stack->is<LUA_TNUMBER>(1)){
				poll->items.reserve(stack->to<int>(1));
			}

			pushUData(poll);
			return 1;
		}
		return 0;
	}
	int lua_zmqPollFree(lutok2::State & state){
		Stack * stack = state.stack;
		if (stack->is<LUA_TUSERDATA>(1)){
			pollArray_t * poll = static_cast<pollArray_t *>(getZMQobject(1));
			if (poll){
				poll->items.clear();
				delete poll;
			}
		}
		return 0;
	}

	int lua_zmqPollGet(lutok2::State & state){
		Stack * stack = state.stack;
		if (stack->is<LUA_TUSERDATA>(1) && stack->is<LUA_TNUMBER>(2)){
			pollArray_t * poll = static_cast<pollArray_t *>(getZMQobject(1));
			if (poll){
				size_t index = stack->to<int>(2);
				if ((index>=0) && (index<poll->items.size())){
					zmq_pollitem_t & item = poll->items[index];
					stack->newTable();
						stack->pushLiteral("socket");
						pushSocket(item.socket);
						stack->setTable();

						stack->setField<int>("fd", static_cast<int>(item.fd));
						stack->setField<int>("events", static_cast<int>(item.events));
						stack->setField<int>("revents", static_cast<int>(item.revents));
					return 1;
				}
			}
		}
		return 0;
	}

	int lua_zmqPollSet(lutok2::State & state){
		Stack * stack = state.stack;
		if (stack->is<LUA_TUSERDATA>(1)){
			pollArray_t * poll = static_cast<pollArray_t *>(getZMQobject(1));
			if (poll){
				if (stack->is<LUA_TNUMBER>(2) && stack->is<LUA_TTABLE>(3)){
					size_t index = stack->to<int>(2);
					if ((index>=0) && (index<poll->items.size())){
						zmq_pollitem_t & item = poll->items[index];

						stack->getField("socket", 3);
						if (stack->is<LUA_TUSERDATA>(-1)){
							item.socket = getZMQobject(-1);
						}
						stack->pop(1);

						stack->getField("fd", 3);
						if (stack->is<LUA_TNUMBER>(-1)){
							item.fd = stack->to<int>(-1);
						}
						stack->pop(1);

						stack->getField("events", 3);
						if (stack->is<LUA_TNUMBER>(-1)){
							item.events = static_cast<short>(stack->to<int>(-1));
						}
						stack->pop(1);

						stack->getField("revents", 3);
						if (stack->is<LUA_TNUMBER>(-1)){
							item.revents = static_cast<short>(stack->to<int>(-1));
						}
						stack->pop(1);

						stack->push<bool>(true);
						return 1;
					}
				}else if (stack->is<LUA_TTABLE>(2)){
					zmq_pollitem_t item;

					stack->getField("socket", 2);
					if (stack->is<LUA_TUSERDATA>(-1)){
						item.socket = getZMQobject(-1);
					}
					stack->pop(1);

					stack->getField("fd", 2);
					if (stack->is<LUA_TNUMBER>(-1)){
						item.fd = stack->to<int>(-1);
					}
					stack->pop(1);

					stack->getField("events", 2);
					if (stack->is<LUA_TNUMBER>(-1)){
						item.events = static_cast<short>(stack->to<int>(-1));
					}
					stack->pop(1);

					stack->getField("revents", 2);
					if (stack->is<LUA_TNUMBER>(-1)){
						item.revents = static_cast<short>(stack->to<int>(-1));
					}
					stack->pop(1);

					poll->items.push_back(item);
					stack->push<bool>(true);
					return 1;
				}
			}
		}
		return 0;
	}

	int lua_zmqPollSize(lutok2::State & state){
		Stack * stack = state.stack;
		if (stack->is<LUA_TUSERDATA>(1)){
			pollArray_t * poll = static_cast<pollArray_t *>(getZMQobject(1));
			if (poll){
				stack->push<int>(poll->items.size());
				return 1;
			}
		}
		return 0;
	}

	int lua_zmqPoll(lutok2::State & state){
		Stack * stack = state.stack;
		if (stack->is<LUA_TUSERDATA>(1)){
			pollArray_t * poll = static_cast<pollArray_t *>(getZMQobject(1));
			if (poll){
				zmq_pollitem_t *items = poll->items.data();
				if (items && poll->items.size()>0){
					int timeout = -1;
					if (stack->is<LUA_TNUMBER>(2)){
						timeout = stack->to<int>(2);
					}
					int result = zmq_poll(items, poll->items.size(), timeout);
					if (result < 0){
						stack->push<bool>(false);
						lua_pushZMQ_error(state);
						return 2;
					}else{
						stack->push<int>(result);
						return 1;
					}
				}
			}
		}
		return 0;
	}

	int lua_zmqBind(lutok2::State & state){
		Stack * stack = state.stack;
		if (stack->is<LUA_TUSERDATA>(1) && stack->is<LUA_TSTRING>(2)){
			if (zmq_bind(getZMQobject(1), stack->to<const std::string>(2).c_str()) != 0){
				stack->push<bool>(false);
				lua_pushZMQ_error(state);
				return 2;
			}else{
				stack->push<bool>(true);
				return 1;
			}
		}
		return 0;
	}

	int lua_zmqUnbind(lutok2::State & state){
		Stack * stack = state.stack;
		if (stack->is<LUA_TUSERDATA>(1) && stack->is<LUA_TSTRING>(2)){
			if (zmq_unbind(getZMQobject(1), stack->to<const std::string>(2).c_str()) != 0){
				stack->push<bool>(false);
				lua_pushZMQ_error(state);
				return 2;
			}else{
				stack->push<bool>(true);
				return 1;
			}
		}
		return 0;
	}

	int lua_zmqConnect(lutok2::State & state){
		Stack * stack = state.stack;
		if (stack->is<LUA_TUSERDATA>(1) && stack->is<LUA_TSTRING>(2)){
			if (zmq_connect(getZMQobject(1), stack->to<const std::string>(2).c_str()) != 0){
				stack->push<bool>(false);
				lua_pushZMQ_error(state);
				return 2;
			}else{
				stack->push<bool>(true);
				return 1;
			}
		}
		return 0;
	}

	int lua_zmqDisconnect(lutok2::State & state){
		Stack * stack = state.stack;
		if (stack->is<LUA_TUSERDATA>(1) && stack->is<LUA_TSTRING>(2)){
			if (zmq_disconnect(getZMQobject(1), stack->to<const std::string>(2).c_str()) != 0){
				stack->push<bool>(false);
				lua_pushZMQ_error(state);
				return 2;
			}else{
				stack->push<bool>(true);
				return 1;
			}
		}
		return 0;
	}

	int lua_zmqProxy(lutok2::State & state){
		Stack * stack = state.stack;
		if (stack->is<LUA_TUSERDATA>(1) && stack->is<LUA_TUSERDATA>(2)){
			void * frontend = getZMQobject(1);
			void * backend = getZMQobject(2);
			void * capture = nullptr;
			if (stack->is<LUA_TUSERDATA>(3)){
				capture = getZMQobject(3);
			}
			zmq_proxy(frontend, backend, capture);
		}
		return 0;
	}
#if (ZMQ_VERSION_MAJOR>=4) && (ZMQ_VERSION_MINOR>=0) && (ZMQ_VERSION_PATCH>=5)
	int lua_zmqProxySteerable(lutok2::State & state){
		Stack * stack = state.stack;
		if (stack->is<LUA_TUSERDATA>(1) && stack->is<LUA_TUSERDATA>(2)){
			void * frontend = getZMQobject(1);
			void * backend = getZMQobject(2);
			void * capture = nullptr;
			if (stack->is<LUA_TUSERDATA>(3)){
				capture = getZMQobject(3);
			}
			void * control = getZMQobject(4);
			zmq_proxy_steerable(frontend, backend, capture, control);
		}
		return 0;
	}
#endif
	int lua_zmqVersion(lutok2::State & state){
		Stack * stack = state.stack;
		int major = 0, minor= 0, patch = 0;
		zmq_version(&major, &minor, &patch);
		stack->push<int>(major);
		stack->push<int>(minor);
		stack->push<int>(patch);
		return 3;
	}

	int lua_zmqRecv(lutok2::State & state){
		Stack * stack = state.stack;
		if (stack->is<LUA_TUSERDATA>(1)){
			size_t len = BUFFER_SIZE;
			if (stack->is<LUA_TNUMBER>(2)){
				len = stack->to<int>(2);
			}
			if (len>0){
				int flags = 0;
				if (stack->is<LUA_TNUMBER>(3)){
					flags = stack->to<int>(3);
				}
				char * buffer = static_cast<char*>(_alloca(len));
				int result = zmq_recv(getZMQobject(1), buffer, len, flags);
				if (result < 0){
					stack->push<bool>(false);
					lua_pushZMQ_error(state);
					return 2;
				}else{
					stack->pushLString(std::string(buffer, (result <= len) ? result : len));
					stack->push<int>(result);
					return 2;
				}
			}
		}
		return 0;
	}

	int lua_zmqRecvAll(lutok2::State & state){
		Stack * stack = state.stack;
		if (stack->is<LUA_TUSERDATA>(1)){
			int flags = 0;
			if (stack->is<LUA_TNUMBER>(2)){
				flags = stack->to<int>(2);
			}
			//input buffer size
			size_t bufferSize = BUFFER_SIZE;
			if (stack->is<LUA_TNUMBER>(3)){
				bufferSize = stack->to<int>(3);
			}

			char * buffer = static_cast<char*>(_alloca(bufferSize));
			void * socket = getZMQobject(1);
			int more=1;
			size_t moreSize = sizeof(more);

			std::string fullBuffer;

			while (more==1){
				int result = zmq_recv(socket, buffer, bufferSize, flags);

				if (result < 0){
					stack->push<bool>(false);
					lua_pushZMQ_error(state);
					return 2;
				}else{
					fullBuffer.append(buffer, result);
				}
				zmq_getsockopt(socket, ZMQ_RCVMORE, &more, &moreSize);
			}

			stack->pushLString(std::string(fullBuffer.c_str(), fullBuffer.size()));
			return 1;
		}
		return 0;
	}

	int lua_zmqRecvMultipart(lutok2::State & state){
		Stack * stack = state.stack;
		if (stack->is<LUA_TUSERDATA>(1)){
			int flags = 0;
			if (stack->is<LUA_TNUMBER>(2)){
				flags = stack->to<int>(2);
			}
			//input buffer size
			size_t bufferSize = BUFFER_SIZE;
			if (stack->is<LUA_TNUMBER>(3)){
				bufferSize = stack->to<int>(3);
			}

			char * buffer = static_cast<char*>(_alloca(bufferSize));
			void * socket = getZMQobject(1);
			std::string fullBuffer;
			int more=1;
			size_t moreSize = sizeof(more);

			stack->newTable();
			size_t partNum = 1;
			size_t filledPartNum = 0;
			size_t bytesRead = 0;

			while (more == 1){
				int result = zmq_recv(socket, buffer, bufferSize, flags);
				if (result < 0){
					stack->pop(1); //pop table
					stack->push<bool>(false);
					lua_pushZMQ_error(state);
					return 2;
				}else{
					//is this part delimiter
					if ((filledPartNum > 0) && (result == 0)){
						//flush buffer
						stack->push<int>(partNum++);
						stack->pushLString(std::string(fullBuffer.c_str(), fullBuffer.length()));
						stack->setTable();
						fullBuffer.clear();
						filledPartNum = 0;
						bytesRead = 0;
					//it's a message part
					}else{
						if (result > 0){
							fullBuffer.append(buffer, result);
							bytesRead += result;
							filledPartNum++;
							//is buffer full?
							if (bytesRead > MAX_BUFFER_SIZE){
								//flush buffer
								stack->push<int>(partNum++);
								stack->pushLString(std::string(fullBuffer.c_str(), fullBuffer.length()));
								stack->setTable();
								fullBuffer.clear();
								filledPartNum = 0;
								bytesRead = 0;
							}
						}
					}
				}
				zmq_getsockopt(socket, ZMQ_RCVMORE, &more, &moreSize);
			}
			if (partNum==1 && filledPartNum>0){
				stack->push<int>(partNum);
				stack->pushLString(std::string(fullBuffer.c_str(), fullBuffer.length()));
				stack->setTable();
			}
			return 1;
		}
		return 0;
	} 

	int lua_zmqSend(lutok2::State & state){
		Stack * stack = state.stack;
		if (stack->is<LUA_TUSERDATA>(1) && stack->is<LUA_TSTRING>(2)){
			std::string & buffer = stack->toLString(2);
			size_t len = buffer.length();
			int flags = 0;
			if (stack->is<LUA_TNUMBER>(3)){
				flags = stack->to<int>(3);
			}

			if (len>0){
				int result = zmq_send(getZMQobject(1), buffer.c_str(), len, flags);
				if (result < 0){
					stack->push<bool>(false);
					lua_pushZMQ_error(state);
					return 2;
				}else{
					stack->push<int>(result);
					return 1;
				}
			}else{
				int result = zmq_send(getZMQobject(1), nullptr, 0, flags);
				if (result < 0){
					stack->push<bool>(false);
					lua_pushZMQ_error(state);
					return 2;
				}else{
					stack->push<int>(result);
					return 1;
				}
			}
		}
		return 0;
	}

	int lua_zmqSendMultipart(lutok2::State & state){
		Stack * stack = state.stack;
		if (stack->is<LUA_TUSERDATA>(1) && stack->is<LUA_TTABLE>(2)){
			int flags = 0;
			if (stack->is<LUA_TNUMBER>(3)){
				flags = stack->to<int>(3);
			}
			//input buffer size
			size_t bufferSize = BUFFER_SIZE;
			if (stack->is<LUA_TNUMBER>(4)){
				bufferSize = stack->to<int>(4);
			}

			size_t parts = stack->objLen(2);
			size_t partsSent = 0;
			/*
				Each part is represented by element in Lua table.
				All parts are sent with ZMQ_SNDMORE flag on and divided with empty ZMQ frame.
			*/
			for (size_t partIndex=1; partIndex <= parts; partIndex++){
				stack->push<int>(partIndex);
				stack->getTable(2);

				if (stack->is<LUA_TSTRING>()){
					std::string & buffer = stack->toLString();
					size_t len = buffer.length();
					size_t offset = 0;
					const char * inputBuffer = buffer.c_str();
					int finalFlags = (partIndex < parts) ? (flags | ZMQ_SNDMORE) : flags; 

					if (len>0){
						//send a part
						do {
							size_t outputSize = ((len-offset) > bufferSize) ? bufferSize : len-offset;

							int result = zmq_send(getZMQobject(1), inputBuffer+offset, outputSize, finalFlags);
							if (result < 0){
								stack->pop(1);
								stack->push<bool>(false);
								lua_pushZMQ_error(state);
								return 2;
							}else{
								offset += result;
							}
						}
						while (offset < len);
						partsSent++;
					}
					if (partIndex < parts){
						// send a delimiter
						int result = zmq_send(getZMQobject(1), nullptr, 0, finalFlags);
						if (result < 0){
							stack->pop(1);
							stack->push<bool>(false);
							lua_pushZMQ_error(state);
							return 2;
						}
					}
				}
				stack->pop(1);
			}
			stack->push<int>(partsSent);
			return 1;
		}
		return 0;
	}
	
	int lua_zmqMsgInit(lutok2::State & state){
		Stack * stack = state.stack;
		zmq_msg_t * msg = new zmq_msg_t;
		if (msg){
			size_t size = 0;
			int result = 0;
			if (stack->is<LUA_TNUMBER>(1)){
				result = zmq_msg_init_size(msg, stack->to<int>(1));
			}else{
				result = zmq_msg_init(msg);
			}

			if (result != 0){
				delete msg;
				stack->push<bool>(false);
				lua_pushZMQ_error(state);
				return 2;
			}else{
				pushUData(msg);
				return 1;
			}
		}else{
			return 0; 
		}
	}

	int lua_zmqMsgClose(lutok2::State & state){
		Stack * stack = state.stack;
		if (stack->is<LUA_TUSERDATA>(1)){
			zmq_msg_t * msg = static_cast<zmq_msg_t*>(getZMQobject(1));
			if (msg){
				if (zmq_msg_close(msg) != 0){
					stack->push<bool>(false);
					lua_pushZMQ_error(state);
				}else{
					delete msg;
					return 0;
				}
			}
		}
		stack->push<bool>(false);
		return 1;
	}

	int lua_zmqMsgCopy(lutok2::State & state){
		Stack * stack = state.stack;
		if (stack->is<LUA_TUSERDATA>(1) && stack->is<LUA_TUSERDATA>(2)){
			zmq_msg_t * msg_src = static_cast<zmq_msg_t*>(getZMQobject(1));
			zmq_msg_t * msg_dest = static_cast<zmq_msg_t*>(getZMQobject(2));
			if (msg_src && msg_dest){
				if (zmq_msg_copy(msg_dest, msg_src) != 0){
					stack->push<bool>(false);
					lua_pushZMQ_error(state);
				}else{
					stack->push<bool>(true);
					return 1;
				}
			}
		}
		stack->push<bool>(false);
		return 1;
	}

	int lua_zmqMsgMove(lutok2::State & state){
		Stack * stack = state.stack;
		if (stack->is<LUA_TUSERDATA>(1) && stack->is<LUA_TUSERDATA>(2)){
			zmq_msg_t * msg_src = static_cast<zmq_msg_t*>(getZMQobject(1));
			zmq_msg_t * msg_dest = static_cast<zmq_msg_t*>(getZMQobject(2));
			if (msg_src && msg_dest){
				if (zmq_msg_move(msg_dest, msg_src) != 0){
					stack->push<bool>(false);
					lua_pushZMQ_error(state);
				}else{
					stack->push<bool>(true);
					return 1;
				}
			}
		}
		stack->push<bool>(false);
		return 1;
	}

	int lua_zmqMsgGetData(lutok2::State & state){
		Stack * stack = state.stack;
		if (stack->is<LUA_TUSERDATA>(1)){
			zmq_msg_t * msg = static_cast<zmq_msg_t*>(getZMQobject(1));
			if (msg){
				void * result = zmq_msg_data(msg);
				if (!result){
					stack->push<bool>(false);
					lua_pushZMQ_error(state);
				}else{
					size_t size = zmq_msg_size(msg);
					stack->pushLString(std::string(static_cast<char *>(result), size));
					return 1;
				}
			}
		}
		stack->push<bool>(false);
		return 1;
	}

	int lua_zmqMsgSetData(lutok2::State & state){
		Stack * stack = state.stack;
		if (stack->is<LUA_TUSERDATA>(1) && stack->is<LUA_TSTRING>(2)){
			zmq_msg_t * msg = static_cast<zmq_msg_t*>(getZMQobject(1));
			if (msg){
				void * result = zmq_msg_data(msg);
				if (!result){
					stack->push<bool>(false);
					lua_pushZMQ_error(state);
				}else{
					size_t dest_size = zmq_msg_size(msg);
					std::string & src = stack->toLString(2);
					size_t src_size = src.length();

					if (src_size <= dest_size){
						memcpy(result, src.c_str(), src_size);
					}else{
						zmq_msg_close(msg);
						if (zmq_msg_init_size(msg, src_size) != 0){
							delete msg;
							stack->push<bool>(false);
							lua_pushZMQ_error(state);
							return 2;
						}else{
							memcpy(result, src.c_str(), src_size);
						}
					}
					return 0;
				}
			}
		}
		stack->push<bool>(false);
		return 1;
	}

	int lua_zmqMsgSize(lutok2::State & state){
		Stack * stack = state.stack;
		if (stack->is<LUA_TUSERDATA>(1)){
			zmq_msg_t * msg = static_cast<zmq_msg_t*>(getZMQobject(1));
			if (msg){
				size_t size = zmq_msg_size(msg);
				stack->push<int>(size);
				return 1;
			}
		}
		stack->push<bool>(false);
		return 1;
	}

	int lua_zmqMsgMore(lutok2::State & state){
		Stack * stack = state.stack;
		if (stack->is<LUA_TUSERDATA>(1)){
			zmq_msg_t * msg = static_cast<zmq_msg_t*>(getZMQobject(1));
			if (msg){
				int  result = zmq_msg_more(msg);
				stack->push<int>(result);
				return 1;
			}
		}
		stack->push<bool>(false);
		return 1;
	}

	int lua_zmqMsgGet(lutok2::State & state){
		Stack * stack = state.stack;
		if (stack->is<LUA_TUSERDATA>(1) && stack->is<LUA_TNUMBER>(2)){
			zmq_msg_t * msg = static_cast<zmq_msg_t*>(getZMQobject(1));
			if (msg){
				int result = zmq_msg_get(msg, stack->to<int>(2));
				if (result == -1){
					stack->push<bool>(false);
					lua_pushZMQ_error(state);
					return 2;
				}else{
					stack->push<int>(result);
					return 1;
				}
			}
		}
		return 0;
	}

	int lua_zmqMsgSet(lutok2::State & state){
		Stack * stack = state.stack;
		if (stack->is<LUA_TUSERDATA>(1) && stack->is<LUA_TNUMBER>(2) && stack->is<LUA_TNUMBER>(3)){
			zmq_msg_t * msg = static_cast<zmq_msg_t*>(getZMQobject(1));
			if (msg){
				if (zmq_msg_set(msg, stack->to<int>(2), stack->to<int>(3)) == -1){
					stack->push<bool>(false);
					lua_pushZMQ_error(state);
					return 2;
				}
			}
		}
		return 0;
	}

	int lua_zmqMsgRecv(lutok2::State & state){
		Stack * stack = state.stack;
		if (stack->is<LUA_TUSERDATA>(1) && stack->is<LUA_TUSERDATA>(2)){
			zmq_msg_t * msg = static_cast<zmq_msg_t*>(getZMQobject(1));
			void * socket = getZMQobject(2);

			if (msg && socket){
				int flags = 0;
				if (stack->is<LUA_TNUMBER>(3)){
					flags = stack->to<int>(3);
				}
				int result = zmq_msg_recv(msg, socket, flags);

				if (result == -1){
					stack->push<bool>(false);
					lua_pushZMQ_error(state);
					return 2;
				}else{
					stack->push<int>(result);
					return 1;
				}
			}
		}
		return 0;
	}

	int lua_zmqMsgSend(lutok2::State & state){
		Stack * stack = state.stack;
		if (stack->is<LUA_TUSERDATA>(1) && stack->is<LUA_TUSERDATA>(2)){
			zmq_msg_t * msg = static_cast<zmq_msg_t*>(getZMQobject(1));
			void * socket = getZMQobject(2);

			if (msg && socket){
				int flags = 0;
				if (stack->is<LUA_TNUMBER>(3)){
					flags = stack->to<int>(3);
				}
				int result = zmq_msg_send(msg, socket, flags);

				if (result == -1){
					stack->push<bool>(false);
					lua_pushZMQ_error(state);
					return 2;
				}else{
					stack->push<int>(result);
					return 1;
				}
			}
		}
		return 0;
	}

	int lua_zmqSleep(lutok2::State & state){
		Stack * stack = state.stack;
		if (stack->is<LUA_TNUMBER>(1)){
			zmq_sleep(stack->to<int>(1));
		}
		return 0;
	}

	int lua_zmqStopwatchStart(lutok2::State & state){
		Stack * stack = state.stack;
		void * stopwatch = zmq_stopwatch_start();
		pushUData(stopwatch);
		return 1;
	}
	int lua_zmqStopwatchStop(lutok2::State & state){
		Stack * stack = state.stack;
		if (stack->is<LUA_TUSERDATA>(1)){
			void * stopwatch = getZMQobject(1);
			if (stopwatch){
				stack->push<int>(zmq_stopwatch_stop(stopwatch));
				return 1;
			}
		}
		return 0;
	}
	int lua_zmqZ85Encode(lutok2::State & state){
		Stack * stack = state.stack;
		if (stack->is<LUA_TSTRING>(1)){
			std::string data = stack->toLString(1);
			size_t length = data.length();
			size_t newLength = static_cast<unsigned int>(ceil(length*1.25)+1);
			char * buffer = new char[newLength];
			if (zmq_z85_encode(buffer, reinterpret_cast<unsigned char*>(const_cast<char*>(data.c_str())), length) != NULL){
				stack->push<const std::string &>(buffer);
			}else{
				stack->push<bool>(false);
			}
			delete buffer;
			return 1;
		}
		return 0;
	}
	int lua_zmqZ85Decode(lutok2::State & state){
		Stack * stack = state.stack;
		if (stack->is<LUA_TSTRING>(1)){
			std::string data = stack->to<const std::string>(1);
			size_t length = data.length();
			if (length%5 == 0){
				size_t newLength = static_cast<unsigned int>(ceil(length*0.8));
				char * buffer = new char[newLength];
				if (zmq_z85_decode(reinterpret_cast<unsigned char*>(buffer), const_cast<char*>(data.c_str())) != NULL){
					stack->pushLString(std::string(buffer, newLength));
				}else{
					stack->push<bool>(false);
				}
				delete buffer;
			}else{
				stack->push<bool>(false);
			}
			return 1;
		}
		return 0;
	}

};

extern "C" LIBLUAZMQ_DLL_EXPORTED int luaopen_luazmq(lua_State * L){
	State * state = new State(L);
	Stack * stack = state->stack;
	Module luazmq_module;

	stack->newTable();
	
	luazmq_module["version"] = LuaZMQ::lua_zmqVersion;
	luazmq_module["init"] = LuaZMQ::lua_zmqInit;
	luazmq_module["term"] = LuaZMQ::lua_zmqTerm;

	luazmq_module["socket"] = LuaZMQ::lua_zmqSocket;
	luazmq_module["close"] = LuaZMQ::lua_zmqClose;
	luazmq_module["socketSetOption"] = LuaZMQ::lua_zmqSetSockOpt;
	luazmq_module["socketGetOptionI"] = LuaZMQ::lua_zmqGetSockOptI;
	luazmq_module["socketGetOptionS"] = LuaZMQ::lua_zmqGetSockOptS;

	luazmq_module["bind"] = LuaZMQ::lua_zmqBind;
	luazmq_module["unbind"] = LuaZMQ::lua_zmqUnbind;
	luazmq_module["connect"] = LuaZMQ::lua_zmqConnect;
	luazmq_module["disconnect"] = LuaZMQ::lua_zmqDisconnect;
	luazmq_module["shutdown"] = LuaZMQ::lua_zmqShutdown;
	luazmq_module["recv"] = LuaZMQ::lua_zmqRecv;
	luazmq_module["send"] = LuaZMQ::lua_zmqSend;
	luazmq_module["get"] = LuaZMQ::lua_zmqGet;
	luazmq_module["set"] = LuaZMQ::lua_zmqSet;

	luazmq_module["recvAll"] = LuaZMQ::lua_zmqRecvAll;
	luazmq_module["recvMultipart"] = LuaZMQ::lua_zmqRecvMultipart;
	luazmq_module["sendMultipart"] = LuaZMQ::lua_zmqSendMultipart;

	luazmq_module["msgInit"] = LuaZMQ::lua_zmqMsgInit;
	luazmq_module["msgClose"] = LuaZMQ::lua_zmqMsgClose;
	luazmq_module["msgCopy"] = LuaZMQ::lua_zmqMsgCopy;
	luazmq_module["msgMove"] = LuaZMQ::lua_zmqMsgMove;
	luazmq_module["msgGetData"] = LuaZMQ::lua_zmqMsgGetData;
	luazmq_module["msgSetData"] = LuaZMQ::lua_zmqMsgSetData;
	luazmq_module["msgGet"] = LuaZMQ::lua_zmqMsgGet;
	luazmq_module["msgSet"] = LuaZMQ::lua_zmqMsgSet;
	luazmq_module["msgMore"] = LuaZMQ::lua_zmqMsgMore;
	luazmq_module["msgSize"] = LuaZMQ::lua_zmqMsgSize;
	luazmq_module["msgSend"] = LuaZMQ::lua_zmqMsgSend;
	luazmq_module["msgRecv"] = LuaZMQ::lua_zmqMsgRecv;

	luazmq_module["pollNew"] = LuaZMQ::lua_zmqPollNew;
	luazmq_module["pollFree"] = LuaZMQ::lua_zmqPollFree;
	luazmq_module["pollSize"] = LuaZMQ::lua_zmqPollSize;
	luazmq_module["pollGet"] = LuaZMQ::lua_zmqPollGet;
	luazmq_module["pollSet"] = LuaZMQ::lua_zmqPollSet;
	luazmq_module["poll"] = LuaZMQ::lua_zmqPoll;

	luazmq_module["proxy"] = LuaZMQ::lua_zmqProxy;
#if (ZMQ_VERSION_MAJOR>=4) && (ZMQ_VERSION_MINOR>=0) && (ZMQ_VERSION_PATCH>=5)
	luazmq_module["proxySteerable"] = LuaZMQ::lua_zmqProxySteerable;
#endif

	luazmq_module["sleep"] = LuaZMQ::lua_zmqSleep;
	luazmq_module["stopwatchStart"] = LuaZMQ::lua_zmqStopwatchStart;
	luazmq_module["stopwatchStop"] = LuaZMQ::lua_zmqStopwatchStop;

	luazmq_module["thread"] = LuaZMQ::lua_zmqThread;
	luazmq_module["joinThread"] = LuaZMQ::lua_zmqJoinThread;
	luazmq_module["freeThread"] = LuaZMQ::lua_zmqFreeThread;
	luazmq_module["getThreadResult"] = LuaZMQ::lua_zmqGetThreadResult;

	luazmq_module["Z85Encode"] = LuaZMQ::lua_zmqZ85Encode;
	luazmq_module["Z85Decode"] = LuaZMQ::lua_zmqZ85Decode;

	state->registerLib(luazmq_module);
	return 1;
}