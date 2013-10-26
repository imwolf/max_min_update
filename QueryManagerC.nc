#include "query.h"
configuration QueryManagerC{
	provides interface QueryInterface;
	provides interface Init;

	uses interface Leds;
}
implementation{
	components QueryManagerP as QM;

	components CC2420ActiveMessageC as AM;

	
	QueryInterface = QM;
	
	QM.Send -> AM.AMSend[AM_QUERY_MSG];
	QM.Receive -> AM.Receive[AM_QUERY_MSG];
	QM.Packet -> AM.Packet;

	Init = QM;
	Leds = QM;
}
