#include "query.h"
#include "printf.h"
module QueryManagerP{
	provides interface QueryInterface; //3 func
	provides interface Init;

	uses interface AMSend as Send;
	uses interface Receive;
	uses interface Packet;

	uses interface Leds;
	//uses interface SplitControl as AMControl;
}
implementation {
	message_t packet;
	bool locked;

	//the node has n children,the array children store their node_id,
	//array results store the value of query corrensponding to these n children(e.g. children[0] 's result is in results[children[0]])
	//in this way ,waste time,but save the time of searching after rx a query response packet from a certain node
	uint16_t children[MAX_CHILDREN_SIZE]={0};
	uint16_t results[MAX_CHILDREN_SIZE] = {0};
	uint8_t n=0;
	uint16_t querier;

	uint8_t rx_cnt = 0;
	uint8_t tx_cnt = 0;

	uint16_t max = 0;
	uint16_t min = 0xffff;

	uint16_t myvalue = 0;
	uint16_t temp_result = 0;
	
	//NOTE:should be called after setChild()!!!
	command error_t Init.init(){
		uint16_t i;
		for (i = 0;i <= MAX_CHILDREN_SIZE; i++){
			children[i] = INVALID;
			results[i] = INVALID;	
		}
		return SUCCESS;
	}

	//TODO
	command error_t QueryInterface.setChild(uint16_t nodeid){
		children[n++] = nodeid;
		return SUCCESS;
	}

	command uint16_t QueryInterface.getValue(){
		return myvalue;
	}

	command uint16_t QueryInterface.getQuerier(){
		return querier;
	}

	command void QueryInterface.setQuerier(uint16_t id){
		querier = id;
	}

	command void QueryInterface.cacheResult(uint16_t res){
		temp_result = res;
		printf("cached result = %u\n",temp_result);
		printfflush();
	}

	//immediate node,pass the result value to parent node
	command error_t QueryInterface.resultToParent(){
		uint16_t dest = querier;
		query_msg_t* qm = (query_msg_t*) call Packet.getPayload(&packet,sizeof(query_msg_t));
		qm -> type = RESPONSE_TYPE;
		qm -> value = temp_result;
		qm -> sender_id = TOS_NODE_ID;
		
		//printf("qm->value = %u\n",qm -> value);
		printf("in resultToParent() ,dest %lu,qm type %u, qm value %u,qm sender_id%lu\n",dest,qm -> type,qm -> value ,qm->sender_id);
		
		//why node 2 send to 0 ,not 1?
		printfflush();	

		//TODO:xx!!dest原来写成0了，这个bug改了一个晚上加一个下午了！上次调试的时候改成0，忘记修改回来了。
		if (call Send.send(dest,&packet,sizeof(query_msg_t)) != SUCCESS){
			printfflush();
		}else{
			return SUCCESS;
		}
	}

	void send(){
		printf("[S]send to :%u \n",children[tx_cnt]);
		printfflush();
		if (call Send.send(children[tx_cnt],&packet,sizeof(query_msg_t)) != SUCCESS){
		 send();
		}else{
			tx_cnt++;
		}
	}


	command error_t QueryInterface.query(){
		uint8_t i = 0;
		query_msg_t * qm;

		//clear
		//TODO
		while(i++ < n){
			results[children[i-1]] = INVALID;
		}
		i = 0;
		max = 0;
		min = 0xffff;
		rx_cnt = 0;
		tx_cnt = 0;
		temp_result = 0;

		qm = (query_msg_t*)call Packet.getPayload(&packet,sizeof(query_msg_t));
		qm->sender_id = TOS_NODE_ID;
		qm->type = QUERY_TYPE;
		qm->value = 0;

		call Leds.led1Toggle();
		//TODO why for cannot be used?
		
		send();
		
		return SUCCESS;
	}



	//TODO
	command error_t QueryInterface.init_value(uint16_t init_value){
		myvalue = init_value;
		return SUCCESS;
	}

  	event message_t* Receive.receive(message_t* msg,void* payload, uint8_t len){
		
		query_msg_t* a_res; 
	
		if (len != sizeof(query_msg_t )) {
			return msg;
		}
		else{
			a_res = (query_msg_t*)payload;

			if (a_res->type == QUERY_TYPE ){

				//TODO
				call Leds.led0Toggle();
				
				//n == 0 --> leaf node?
				if ( n == 0 ){
					uint16_t dest = a_res->sender_id;
					query_msg_t* qm = (query_msg_t*)call Packet.getPayload(&packet,sizeof(query_msg_t));
					qm->sender_id = TOS_NODE_ID;
					qm->type = RESPONSE_TYPE;
					qm->value = myvalue;

					printf("[R]leaf node,prepare to send response,TOS_NODE_ID %u,RESPONSE_TYPE %u,myvalue %u\n",TOS_NODE_ID,RESPONSE_TYPE,myvalue);
					printf("[R]qm sender_id %u,type %u,value %u\n",qm->sender_id,qm->type,qm->value);
					printfflush();
					call Send.send(dest,&packet,sizeof(query_msg_t));
				}else{
					call QueryInterface.setQuerier(a_res -> sender_id);
					printf("[R]intermediate node,got a query from msg %lu,sending to child node\n",a_res -> sender_id);
					printfflush();
					call QueryInterface.query();
				}
				return msg;
			}

			
			//not a query,so it's a response type
			printf("[R]response msg,receive from :%u value:%u\n" ,a_res->sender_id,a_res->value);
			printf("[R]results[a_res->sender_id] %u\n",results[a_res->sender_id]);
			printfflush();
			//if there i've never receive the result from this sender
			if ( results[a_res->sender_id] == INVALID){
				printf("got a result from one child %u\n",a_res->sender_id);
				printfflush();
				max = max < a_res->value?a_res->value:max;
				min = min > a_res->value?a_res->value:min;

				results[a_res->sender_id] = a_res->value;
				rx_cnt++;
			}
			printf("rx_cnt %u,n=%u\n",rx_cnt,n);
			printfflush();

			//should change max/min here
			if (rx_cnt == n){
				printf("signaling  queryDone(),from children max %u\n",max);
				signal QueryInterface.queryDone(SUCCESS,max);
			}
			return msg;
		}
	}

	event void Send.sendDone(message_t * msg,error_t err){
		if (tx_cnt != n){
			send();
		}
	}

}
