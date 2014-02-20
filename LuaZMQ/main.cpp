#include "common.h"

namespace LuaZMQ {
	typedef std::map< std::string, lutok::cxx_function > moduleDef;

	struct pollArray_t {
		std::vector<zmq_pollitem_t> items;
	};

	inline void lua_pushZMQ_error(lutok::state & state){
		state.push_string(zmq_strerror(zmq_errno()));
	}

#define INPUT_BUFFER_SIZE	4096

#define getZMQobject(n) *state.to_userdata<void*>((n))

	int lua_zmqInit(lutok::state & state){
		void * context = zmq_ctx_new();
		if (!context){
			state.push_boolean(false);
			lua_pushZMQ_error(state);
			return 2;
		}else{
			state.push_userdata(context);
			state.new_table();
			state.set_metatable();
			return 1;
		}
	}

	int lua_zmqTerm(lutok::state & state){
		if (state.is_userdata(1)){
			if (zmq_ctx_term(getZMQobject(1)) != 0){
				state.push_boolean(false);
				lua_pushZMQ_error(state);
				return 2;
			}
		}
		return 0;
	}

	int lua_zmqShutdown(lutok::state & state){
		if (state.is_userdata(1)){
			if (zmq_ctx_shutdown(getZMQobject(1)) != 0){
				state.push_boolean(false);
				lua_pushZMQ_error(state);
				return 2;
			}
		}
		return 0;
	}

	int lua_zmqThread(lutok::state & state){
		int parameters_count = state.get_top();
		if ((parameters_count>=2) && state.is_userdata(1) && state.is_string(2)){
			void * lua_thread_state = state.new_thread();
			lutok::state lua_thread = lutok::state(lua_thread_state);
			lua_thread.load_string(state.to_string(2));
			lua_thread.push_userdata(getZMQobject(1));
			lua_thread.pcall(1,0,0);
			return 1;
		}
		return 0;
	}

	int lua_zmqGet(lutok::state & state){
		if (state.is_userdata(1) && state.is_number(2)){
			int result = zmq_ctx_get(getZMQobject(1), state.to_integer(2));
			if (result == -1){
				state.push_boolean(false);
				lua_pushZMQ_error(state);
				return 2;
			}else{
				state.push_integer(result);
				return 1;
			}
		}
		return 0;
	}

	int lua_zmqSet(lutok::state & state){
		if (state.is_userdata(1) && state.is_number(2) && state.is_number(3)){
			if (zmq_ctx_set(getZMQobject(1), state.to_integer(2), state.to_integer(3)) == -1){
				state.push_boolean(false);
				lua_pushZMQ_error(state);
				return 2;
			}
		}
		return 0;
	}

	int lua_zmqSocket(lutok::state & state){
		if (state.is_userdata(1) && state.is_number(2)){
			int type = state.to_integer(2);
			void * context = getZMQobject(1);
			void * socket = zmq_socket(context, type);
			if (socket){
				state.push_userdata(socket);
				state.new_table();
				state.set_metatable();
				return 1;
			}else{
				state.push_boolean(false);
				lua_pushZMQ_error(state);
				return 2;
			}
		}
		state.push_boolean(false);
		return 1;
	}

	int lua_zmqClose(lutok::state & state){
		if (state.is_userdata(1)){
			if (zmq_close(getZMQobject(1)) != 0){
				state.push_boolean(false);
				lua_pushZMQ_error(state);
				return 2;
			}
		}
		return 0;
	}

	int lua_zmqSetSockOpt(lutok::state & state){
		if (state.is_userdata(1) && state.is_number(2)){
			const void * value = nullptr;
			std::string str;
			size_t size = 0;
			int option = state.to_integer(2);
			if (state.is_number(3)){
				int v = state.to_integer(3);
				value = static_cast<const void *>(&v);
				size = sizeof(v);
			}else if (state.is_string(3)){
				str = state.to_string();
				value = const_cast<const char *>(str.c_str());
				size = str.length();
			}
			int result = zmq_setsockopt(getZMQobject(1), option, value, size);
			if (result == -1){
				state.push_boolean(false);
				lua_pushZMQ_error(state);
				return 2;
			}else{
				state.push_boolean(true);
				return 1;
			}
		}
		return 0;
	}

	int lua_zmqGetSockOptI(lutok::state & state){
		if (state.is_userdata(1) && state.is_number(2)){
			int v = 0;
			void * value = &v;
			size_t size = sizeof(v);
			int option = state.to_integer(2);

			if (zmq_getsockopt(getZMQobject(1), option, value, &size) == -1){
				state.push_boolean(false);
				lua_pushZMQ_error(state);
				return 2;
			}else{
				state.push_integer(v);
				return 1;
			}
		}
		return 0;
	}
	int lua_zmqGetSockOptS(lutok::state & state){
		if (state.is_userdata(1) && state.is_number(2)){
			char v[1024];
			void * value = v;
			size_t size = sizeof(v);
			int option = state.to_integer(2);

			if (zmq_getsockopt(getZMQobject(1), option, value, &size) == -1){
				state.push_boolean(false);
				lua_pushZMQ_error(state);
				return 2;
			}else{
				state.push_lstring(v, size);
				return 1;
			}
		}
		return 0;
	}

	int lua_zmqPollNew(lutok::state & state){
		pollArray_t * poll = new pollArray_t;
		if (poll){
			if (state.is_number(1)){
				poll->items.reserve(state.to_integer(1));
			}

			state.push_userdata(poll);
			state.new_table();
			state.set_metatable();
			return 1;
		}
		return 0;
	}
	int lua_zmqPollFree(lutok::state & state){
		if (state.is_userdata(1)){
			pollArray_t * poll = static_cast<pollArray_t *>(getZMQobject(1));
			if (poll){
				poll->items.clear();
				delete poll;
			}
		}
		return 0;
	}

	int lua_zmqPollGet(lutok::state & state){
		if (state.is_userdata(1) && state.is_number(2)){
			pollArray_t * poll = static_cast<pollArray_t *>(getZMQobject(1));
			if (poll){
				size_t index = state.to_integer(2);
				if ((index>=0) && (index<poll->items.size())){
					zmq_pollitem_t & item = poll->items[index];
					state.new_table();
						state.push_literal("socket");
						state.push_userdata(item.socket);
						state.set_table();

						state.set_field("fd", static_cast<int>(item.fd));
						state.set_field("events", static_cast<int>(item.events));
						state.set_field("revents", static_cast<int>(item.revents));
					return 1;
				}
			}
		}
		return 0;
	}

	int lua_zmqPollSet(lutok::state & state){
		if (state.is_userdata(1)){
			pollArray_t * poll = static_cast<pollArray_t *>(getZMQobject(1));
			if (poll){
				if (state.is_number(2) && state.is_table(3)){
					size_t index = state.to_integer(2);
					if ((index>=0) && (index<poll->items.size())){
						zmq_pollitem_t & item = poll->items[index];

						state.get_field(3, "socket");
						if (state.is_userdata(-1)){
							item.socket = getZMQobject(-1);
						}
						state.pop(1);

						state.get_field(3, "fd");
						if (state.is_number(-1)){
							item.fd = state.to_integer(-1);
						}
						state.pop(1);

						state.get_field(3, "events");
						if (state.is_number(-1)){
							item.events = state.to_integer(-1);
						}
						state.pop(1);

						state.get_field(3, "revents");
						if (state.is_number(-1)){
							item.revents = state.to_integer(-1);
						}
						state.pop(1);

						state.push_boolean(true);
						return 1;
					}
				}else if (state.is_table(2)){
					zmq_pollitem_t item;

					state.get_field(2, "socket");
					if (state.is_userdata(-1)){
						item.socket = getZMQobject(-1);
					}
					state.pop(1);

					state.get_field(2, "fd");
					if (state.is_number(-1)){
						item.fd = state.to_integer(-1);
					}
					state.pop(1);

					state.get_field(2, "events");
					if (state.is_number(-1)){
						item.events = state.to_integer(-1);
					}
					state.pop(1);

					state.get_field(2, "revents");
					if (state.is_number(-1)){
						item.revents = state.to_integer(-1);
					}
					state.pop(1);

					poll->items.push_back(item);
					state.push_boolean(true);
					return 1;
				}
			}
		}
		return 0;
	}

	int lua_zmqPollSize(lutok::state & state){
		if (state.is_userdata(1)){
			pollArray_t * poll = static_cast<pollArray_t *>(getZMQobject(1));
			if (poll){
				state.push_integer(poll->items.size());
				return 1;
			}
		}
		return 0;
	}

	int lua_zmqPoll(lutok::state & state){
		if (state.is_userdata(1)){
			pollArray_t * poll = static_cast<pollArray_t *>(getZMQobject(1));
			if (poll){
				zmq_pollitem_t *items = poll->items.data();
				if (items && poll->items.size()>0){
					int timeout = -1;
					if (state.is_number(2)){
						timeout = state.to_integer(2);
					}
					int result = zmq_poll(items, poll->items.size(), timeout);
					if (result < 0){
						state.push_boolean(false);
						lua_pushZMQ_error(state);
						return 2;
					}else{
						state.push_integer(result);
						return 1;
					}
				}
			}
		}
		return 0;
	}

	int lua_zmqBind(lutok::state & state){
		if (state.is_userdata(1) && state.is_string(2)){
			if (zmq_bind(getZMQobject(1), state.to_string(2).c_str()) != 0){
				state.push_boolean(false);
				lua_pushZMQ_error(state);
				return 2;
			}else{
				state.push_boolean(true);
				return 1;
			}
		}
		return 0;
	}

	int lua_zmqUnbind(lutok::state & state){
		if (state.is_userdata(1) && state.is_string(2)){
			if (zmq_unbind(getZMQobject(1), state.to_string(2).c_str()) != 0){
				state.push_boolean(false);
				lua_pushZMQ_error(state);
				return 2;
			}else{
				state.push_boolean(true);
				return 1;
			}
		}
		return 0;
	}

	int lua_zmqConnect(lutok::state & state){
		if (state.is_userdata(1) && state.is_string(2)){
			if (zmq_connect(getZMQobject(1), state.to_string(2).c_str()) != 0){
				state.push_boolean(false);
				lua_pushZMQ_error(state);
				return 2;
			}else{
				state.push_boolean(true);
				return 1;
			}
		}
		return 0;
	}

	int lua_zmqDisconnect(lutok::state & state){
		if (state.is_userdata(1) && state.is_string(2)){
			if (zmq_disconnect(getZMQobject(1), state.to_string(2).c_str()) != 0){
				state.push_boolean(false);
				lua_pushZMQ_error(state);
				return 2;
			}else{
				state.push_boolean(true);
				return 1;
			}
		}
		return 0;
	}

	int lua_zmqProxy(lutok::state & state){
		if (state.is_userdata(1) && state.is_userdata(2)){
			void * frontend = getZMQobject(1);
			void * backend = getZMQobject(2);
			void * capture = nullptr;
			if (state.is_userdata(3)){
				capture = getZMQobject(3);
			}
			zmq_proxy(frontend, backend, capture);
		}
		return 0;
	}

	int lua_zmqVersion(lutok::state & state){
		int major = 0, minor= 0, patch = 0;
		zmq_version(&major, &minor, &patch);
		state.push_integer(major);
		state.push_integer(minor);
		state.push_integer(patch);
		return 3;
	}

	int lua_zmqRecv(lutok::state & state){
		if (state.is_userdata(1) && state.is_number(2)){
			size_t len = state.to_integer(2);
			if (len>0){
				int flags = 0;
				if (state.is_number(3)){
					flags = state.to_integer(3);
				}
				char * buffer = static_cast<char*>(_alloca(len));
				int result = zmq_recv(getZMQobject(1), buffer, len, flags);
				if (result < 0){
					state.push_boolean(false);
					lua_pushZMQ_error(state);
					return 2;
				}else{
					state.push_lstring(buffer, (result <= len) ? result : len);
					return 1;
				}
			}
		}
		return 0;
	}

	int lua_zmqRecvAll(lutok::state & state){
		if (state.is_userdata(1)){
			int flags = 0;
			if (state.is_number(2)){
				flags = state.to_integer(2);
			}

			char * buffer = static_cast<char*>(_alloca(INPUT_BUFFER_SIZE));
			void * socket = getZMQobject(1);
			size_t size = sizeof(int);
			int more=1;
			size_t steps = 0;
			//zmq_getsockopt(socket, ZMQ_RCVMORE, &more, &size);

			lutok::Buffer lbuffer(state);

			while (more){
				int result = zmq_recv(socket, buffer, INPUT_BUFFER_SIZE, flags);

				if (result < 0){
					state.push_boolean(false);
					lua_pushZMQ_error(state);
					return 2;
				}else{
					lbuffer.addlstring(buffer, result);
				}
				if (result >= INPUT_BUFFER_SIZE){
					zmq_getsockopt(socket, ZMQ_RCVMORE, &more, &size);
				}else{
					more = 0;
				}
			}

			lbuffer.push();
			return 1;
		}
		return 0;
	}

	int lua_zmqSend(lutok::state & state){
		if (state.is_userdata(1) && state.is_string(2)){
			size_t len = state.obj_len(2);
			if (len>=0){
				int flags = 0;
				if (state.is_number(3)){
					flags = state.to_integer(3);
				}
				std::string & buffer = state.to_string(2);
				int result = zmq_send(getZMQobject(1), buffer.c_str(), len, flags);
				if (result < 0){
					state.push_boolean(false);
					lua_pushZMQ_error(state);
					return 2;
				}else{
					state.push_integer(result);
					return 1;
				}
			}
		}
		return 0;
	}
	
	int lua_zmqMsgInit(lutok::state & state){
		zmq_msg_t * msg = new zmq_msg_t;
		if (msg){
			size_t size = 0;
			int result = 0;
			if (state.is_number(1)){
				result = zmq_msg_init_size(msg, state.to_integer(1));
			}else{
				result = zmq_msg_init(msg);
			}

			if (result != 0){
				delete msg;
				state.push_boolean(false);
				lua_pushZMQ_error(state);
				return 2;
			}else{
				state.push_userdata(msg);
				state.new_table();
				state.set_metatable();
				return 1;
			}
		}else{
			return 0; 
		}
	}

	int lua_zmqMsgClose(lutok::state & state){
		if (state.is_userdata(1)){
			zmq_msg_t * msg = static_cast<zmq_msg_t*>(getZMQobject(1));
			if (msg){
				if (zmq_msg_close(msg) != 0){
					state.push_boolean(false);
					lua_pushZMQ_error(state);
				}else{
					delete msg;
					return 0;
				}
			}
		}
		state.push_boolean(false);
		return 1;
	}

	int lua_zmqMsgCopy(lutok::state & state){
		if (state.is_userdata(1) && state.is_userdata(2)){
			zmq_msg_t * msg_src = static_cast<zmq_msg_t*>(getZMQobject(1));
			zmq_msg_t * msg_dest = static_cast<zmq_msg_t*>(getZMQobject(2));
			if (msg_src && msg_dest){
				if (zmq_msg_copy(msg_dest, msg_src) != 0){
					state.push_boolean(false);
					lua_pushZMQ_error(state);
				}else{
					state.push_boolean(true);
					return 1;
				}
			}
		}
		state.push_boolean(false);
		return 1;
	}

	int lua_zmqMsgMove(lutok::state & state){
		if (state.is_userdata(1) && state.is_userdata(2)){
			zmq_msg_t * msg_src = static_cast<zmq_msg_t*>(getZMQobject(1));
			zmq_msg_t * msg_dest = static_cast<zmq_msg_t*>(getZMQobject(2));
			if (msg_src && msg_dest){
				if (zmq_msg_move(msg_dest, msg_src) != 0){
					state.push_boolean(false);
					lua_pushZMQ_error(state);
				}else{
					state.push_boolean(true);
					return 1;
				}
			}
		}
		state.push_boolean(false);
		return 1;
	}

	int lua_zmqMsgGetData(lutok::state & state){
		if (state.is_userdata(1)){
			zmq_msg_t * msg = static_cast<zmq_msg_t*>(getZMQobject(1));
			if (msg){
				void * result = zmq_msg_data(msg);
				if (!result){
					state.push_boolean(false);
					lua_pushZMQ_error(state);
				}else{
					size_t size = zmq_msg_size(msg);
					state.push_lstring(static_cast<char *>(result), size);
					return 1;
				}
			}
		}
		state.push_boolean(false);
		return 1;
	}

	int lua_zmqMsgSetData(lutok::state & state){
		if (state.is_userdata(1) && state.is_string(2)){
			zmq_msg_t * msg = static_cast<zmq_msg_t*>(getZMQobject(1));
			if (msg){
				void * result = zmq_msg_data(msg);
				if (!result){
					state.push_boolean(false);
					lua_pushZMQ_error(state);
				}else{
					size_t dest_size = zmq_msg_size(msg);
					size_t src_size = state.obj_len(2);
					std::string & src = state.to_string(2);
					if (src_size <= dest_size){
						memcpy(result, src.c_str(), src_size);
					}else{
						zmq_msg_close(msg);
						if (zmq_msg_init_size(msg, src_size) != 0){
							delete msg;
							state.push_boolean(false);
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
		state.push_boolean(false);
		return 1;
	}

	int lua_zmqMsgSize(lutok::state & state){
		if (state.is_userdata(1)){
			zmq_msg_t * msg = static_cast<zmq_msg_t*>(getZMQobject(1));
			if (msg){
				size_t size = zmq_msg_size(msg);
				state.push_integer(size);
				return 1;
			}
		}
		state.push_boolean(false);
		return 1;
	}

	int lua_zmqMsgMore(lutok::state & state){
		if (state.is_userdata(1)){
			zmq_msg_t * msg = static_cast<zmq_msg_t*>(getZMQobject(1));
			if (msg){
				int  result = zmq_msg_more(msg);
				state.push_integer(result);
				return 1;
			}
		}
		state.push_boolean(false);
		return 1;
	}

	int lua_zmqMsgGet(lutok::state & state){
		if (state.is_userdata(1) && state.is_number(2)){
			zmq_msg_t * msg = static_cast<zmq_msg_t*>(getZMQobject(1));
			if (msg){
				int result = zmq_msg_get(msg, state.to_integer(2));
				if (result == -1){
					state.push_boolean(false);
					lua_pushZMQ_error(state);
					return 2;
				}else{
					state.push_integer(result);
					return 1;
				}
			}
		}
		return 0;
	}

	int lua_zmqMsgSet(lutok::state & state){
		if (state.is_userdata(1) && state.is_number(2) && state.is_number(3)){
			zmq_msg_t * msg = static_cast<zmq_msg_t*>(getZMQobject(1));
			if (msg){
				if (zmq_msg_set(msg, state.to_integer(2), state.to_integer(3)) == -1){
					state.push_boolean(false);
					lua_pushZMQ_error(state);
					return 2;
				}
			}
		}
		return 0;
	}

	int lua_zmqMsgRecv(lutok::state & state){
		if (state.is_userdata(1) && state.is_userdata(2)){
			zmq_msg_t * msg = static_cast<zmq_msg_t*>(getZMQobject(1));
			void * socket = getZMQobject(2);

			if (msg && socket){
				int flags = 0;
				if (state.is_number(3)){
					flags = state.to_integer(3);
				}
				int result = zmq_msg_recv(msg, socket, flags);

				if (result == -1){
					state.push_boolean(false);
					lua_pushZMQ_error(state);
					return 2;
				}else{
					state.push_integer(result);
					return 1;
				}
			}
		}
		return 0;
	}

	int lua_zmqMsgSend(lutok::state & state){
		if (state.is_userdata(1) && state.is_userdata(2)){
			zmq_msg_t * msg = static_cast<zmq_msg_t*>(getZMQobject(1));
			void * socket = getZMQobject(2);

			if (msg && socket){
				int flags = 0;
				if (state.is_number(3)){
					flags = state.to_integer(3);
				}
				int result = zmq_msg_send(msg, socket, flags);

				if (result == -1){
					state.push_boolean(false);
					lua_pushZMQ_error(state);
					return 2;
				}else{
					state.push_integer(result);
					return 1;
				}
			}
		}
		return 0;
	}

	int lua_zmqSleep(lutok::state & state){
		if (state.is_number(1)){
			zmq_sleep(state.to_integer(1));
		}
		return 0;
	}

	int lua_zmqStopwatchStart(lutok::state & state){
		void * stopwatch = zmq_stopwatch_start();
		state.push_userdata(stopwatch);
		state.new_table();
		state.set_metatable();
		return 1;
	}
	int lua_zmqStopwatchStop(lutok::state & state){
		if (state.is_userdata(1)){
			void * stopwatch = getZMQobject(1);
			if (stopwatch){
				state.push_integer(zmq_stopwatch_stop(stopwatch));
				return 1;
			}
		}
		return 0;
	}

};


extern "C" LUA_API int luaopen_luazmq(lua_State * L){
	lutok::state state(L);
	LuaZMQ::moduleDef module;

	module["version"] = LuaZMQ::lua_zmqVersion;
	module["init"] = LuaZMQ::lua_zmqInit;
	module["term"] = LuaZMQ::lua_zmqTerm;

	module["socket"] = LuaZMQ::lua_zmqSocket;
	module["close"] = LuaZMQ::lua_zmqClose;
	module["socketSetOption"] = LuaZMQ::lua_zmqSetSockOpt;
	module["socketGetOptionI"] = LuaZMQ::lua_zmqGetSockOptI;
	module["socketGetOptionS"] = LuaZMQ::lua_zmqGetSockOptS;

	module["bind"] = LuaZMQ::lua_zmqBind;
	module["unbind"] = LuaZMQ::lua_zmqUnbind;
	module["connect"] = LuaZMQ::lua_zmqConnect;
	module["disconnect"] = LuaZMQ::lua_zmqDisconnect;
	module["shutdown"] = LuaZMQ::lua_zmqShutdown;
	module["recv"] = LuaZMQ::lua_zmqRecv;
	module["recvAll"] = LuaZMQ::lua_zmqRecvAll;
	module["send"] = LuaZMQ::lua_zmqSend;
	module["get"] = LuaZMQ::lua_zmqGet;
	module["set"] = LuaZMQ::lua_zmqSet;

	module["msgInit"] = LuaZMQ::lua_zmqMsgInit;
	module["msgClose"] = LuaZMQ::lua_zmqMsgClose;
	module["msgCopy"] = LuaZMQ::lua_zmqMsgCopy;
	module["msgMove"] = LuaZMQ::lua_zmqMsgMove;
	module["msgGetData"] = LuaZMQ::lua_zmqMsgGetData;
	module["msgSetData"] = LuaZMQ::lua_zmqMsgSetData;
	module["msgGet"] = LuaZMQ::lua_zmqMsgGet;
	module["msgSet"] = LuaZMQ::lua_zmqMsgSet;
	module["msgMore"] = LuaZMQ::lua_zmqMsgMore;
	module["msgSize"] = LuaZMQ::lua_zmqMsgSize;
	module["msgSend"] = LuaZMQ::lua_zmqMsgSend;
	module["msgRecv"] = LuaZMQ::lua_zmqMsgRecv;

	module["pollNew"] = LuaZMQ::lua_zmqPollNew;
	module["pollFree"] = LuaZMQ::lua_zmqPollFree;
	module["pollSize"] = LuaZMQ::lua_zmqPollSize;
	module["pollGet"] = LuaZMQ::lua_zmqPollGet;
	module["pollSet"] = LuaZMQ::lua_zmqPollSet;
	module["poll"] = LuaZMQ::lua_zmqPoll;

	module["proxy"] = LuaZMQ::lua_zmqProxy;

	module["sleep"] = LuaZMQ::lua_zmqSleep;
	module["stopwatchStart"] = LuaZMQ::lua_zmqStopwatchStart;
	module["stopwatchStop"] = LuaZMQ::lua_zmqStopwatchStop;

	module["thread"] = LuaZMQ::lua_zmqThread;

	state.new_table();
	lutok::registerLib(state, module);
	return 1;
}