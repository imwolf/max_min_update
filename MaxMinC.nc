#include "printf.h"
module MaxMinC {
	uses {
		interface Leds;
		interface Boot;

		interface SplitControl as AMControl;

		interface Timer<TMilli> as QueryTimer; //to start a query periodicly
		interface Timer<TMilli> as TimeoutTimer;
		interface QueryInterface;

		interface Init as QMInit;
	}
}
implementation{
	message_t packet;
	bool locked;
	uint16_t result;
	uint16_t my_val ;

	event void Boot.booted(){
		my_val = TOS_NODE_ID;
		//is it easy to generate wrong answer?
		call QueryInterface.init_value(my_val);
		call QMInit.init();
		if (TOS_NODE_ID == 0){
			call QueryInterface.setChild(1);
			//TODO 为什么直接加这一句原先可行的结点1也不行了？
			call QueryInterface.setChild(2);
		}
		
		if (TOS_NODE_ID == 1){
			//call QueryInterface.setChild(2);
			call QueryInterface.setChild(3);
			call QueryInterface.setChild(4);
		}

		if (TOS_NODE_ID == 2){
			//call QueryInterface.setChild(3);
			call QueryInterface.setChild(4);
			call QueryInterface.setChild(5);
			call QueryInterface.setChild(6);
		}

		call AMControl.start();
	}

	void startQuery(){
		call QueryInterface.query();
		call TimeoutTimer.startOneShot(5120);
	}

	event void AMControl.startDone(error_t err){
		if (err == SUCCESS ){
			//TODO:root node
			if (TOS_NODE_ID == 0){
				//just make sure all node is burn,
				call TimeoutTimer.startOneShot(1024);
			}
		}else{
			call AMControl.start();
		}
	}

	event void AMControl.stopDone(error_t err){
	}

	event void QueryTimer.fired(){
		startQuery();
	}

	//for timeout
	event void TimeoutTimer.fired(){
		printf("Timeout!\n");
		printfflush();
		startQuery();
	}

	/*********************************************************************
	*get query result from the children,cache the result in query manager?
	*and then send the result back to the node?
	********************************************************************/
	event void QueryInterface.queryDone(error_t err,uint16_t res){
		uint16_t myvalue  = call QueryInterface.getValue();
		uint32_t dest = call QueryInterface.getQuerier();

		//cancle the timer
		call TimeoutTimer.stop();

		call Leds.led2Toggle();
		//TODO:should i make the logic of comparing myvalue with children's in the QueryManagerP?
		//TODO:result[] initial value = 0,it should be changed,-1 for example;
		result = res < myvalue ? myvalue:res;
		printf("result = %u ,res = %u , myvalue = %u\n",result,res,myvalue);
		printfflush();

		if (TOS_NODE_ID == 0){
			printf("result is %u,and begin next query\n",result);
			printfflush();
			call QueryTimer.startOneShot(512);
		}else{ //node not root and leaf,send the result back
			printf("in queryDone,sending back to parent %lu,result = %u\n",call QueryInterface.getQuerier(),result);

			printf("result = %u\n",result);
			printfflush();
			
			call QueryInterface.cacheResult(result);
			call QueryInterface.resultToParent();
		}
	}

	
}
