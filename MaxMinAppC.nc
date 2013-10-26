configuration MaxMinAppC{
}
implementation{
	components MainC,MaxMinC as App,LedsC;

	components new TimerMilliC() as QueryTimer;
	components new TimerMilliC() as TimeoutTimer;
	components CC2420ActiveMessageC as AM;

	components QueryManagerC;
	components PrintfC;
	components SerialStartC;

	App.Boot -> MainC.Boot;
	//App.Leds -> LedsC;
	App.QueryTimer -> QueryTimer;
	App.TimeoutTimer-> TimeoutTimer;

	App.QueryInterface -> QueryManagerC;

	App.AMControl -> AM.SplitControl;

	QueryManagerC.Leds -> LedsC;
	App.Leds -> LedsC;

	App.QMInit -> QueryManagerC.Init;
}
