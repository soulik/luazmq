namespace LuaZMQ {
	extern "C" LIBLUAZMQ_DLL_EXPORTED int luaopen_luazmq(lua_State *);
	
	int lua_zmqVersion(State &);
	int lua_zmqInit(State &);
	int lua_zmqTerm(State &);
	int lua_zmqHas(State &);

	int lua_zmqSocket(State &);
	int lua_zmqClose(State &);
	int lua_zmqSetSockOptI32(State &);
	int lua_zmqSetSockOptI64(State &);
	int lua_zmqSetSockOptIptr(State &);
	int lua_zmqSetSockOptS(State &);
	int lua_zmqGetSockOptI32(State &);
	int lua_zmqGetSockOptI64(State &);
	int lua_zmqGetSockOptIptr(State &);
	int lua_zmqGetSockOptS(State &);

	int lua_zmqBind(State &);
	int lua_zmqUnbind(State &);
	int lua_zmqConnect(State &);
	int lua_zmqDisconnect(State &);
	int lua_zmqShutdown(State &);
	int lua_zmqRecv(State &);
	int lua_zmqSend(State &);
	int lua_zmqGet(State &);
	int lua_zmqSet(State &);

	int lua_zmqRecvAll(State &);
	int lua_zmqRecvMultipart(State &);
	int lua_zmqSendMultipart(State &);

	int lua_zmqMsgInit(State &);
	int lua_zmqMsgClose(State &);
	int lua_zmqMsgCopy(State &);
	int lua_zmqMsgMove(State &);
	int lua_zmqMsgGetData(State &);
	int lua_zmqMsgSetData(State &);
	int lua_zmqMsgGet(State &);
	int lua_zmqMsgSet(State &);
	int lua_zmqMsgMore(State &);
	int lua_zmqMsgSize(State &);
	int lua_zmqMsgSend(State &);
	int lua_zmqMsgRecv(State &);
	int lua_zmqMsgGets(State & state);
	int lua_zmqMsgGetRoutingID(State & state);
	int lua_zmqMsgSetRoutingID(State & state);

	int lua_zmqPollNew(State &);
	int lua_zmqPollFree(State &);
	int lua_zmqPollSize(State &);
	int lua_zmqPollGet(State &);
	int lua_zmqPollSet(State &);
	int lua_zmqPoll(State &);

	int lua_zmqAtomicCounterNew(State &);
	int lua_zmqAtomicCounterDestroy(State &);
	int lua_zmqAtomicCounterSet(State &);
	int lua_zmqAtomicCounterValue(State &);
	int lua_zmqAtomicCounterInc(State &);
	int lua_zmqAtomicCounterDec(State &);

	int lua_zmqProxy(State &);
	int lua_zmqProxySteerable(State &);

	int lua_zmqSleep(State &);
	int lua_zmqStopwatchStart(State &);
	int lua_zmqStopwatchStop(State &);

	int lua_zmqThread(State &);
	int lua_zmqJoinThread(State &);
	int lua_zmqFreeThread(State &);
	int lua_zmqGetThreadResult(State &);

	int lua_zmqZ85Encode(State &);
	int lua_zmqZ85Decode(State &);
};
