interface QueryInterface{
	//for simplicity,manally set child node
	command error_t setChild(uint16_t node_id);

	//just like interface read
	command error_t query();
	//TODO about the err
	event void queryDone(error_t err,uint16_t t);

	command uint16_t getValue();
	command error_t init_value(uint16_t init_value);
	
	command uint16_t getQuerier();
	command void setQuerier(uint16_t querier);

	command void cacheResult(uint16_t res);
	command error_t resultToParent();
}
