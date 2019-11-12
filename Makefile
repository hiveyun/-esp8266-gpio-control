FSM=fsm

FSM_SRC=fsm/fsm.smudge \
		fsm/button.smudge \
		fsm/switch.smudge \
		fsm/blinker.smudge \
		fsm/network.smudge \
		fsm/mqtt.smudge \

SWITCH_COUNT=1

# mqtt server config
PRODUCT_KEY=8a7b722f5d671136231b
MQTT_HOST=gw.huabot.com
MQTT_PORT=11883

# switch state config
# lose power will keep the state
KEEP_SWITCH_STATE=1
SWITCH_STATE_ON=1
SWITCH_STATE_OFF=0
# set default switch state when started if no keep switch state
DEFAULT_SWITCH_STATE=SWITCH_STATE_OFF

all: $(FSM).c $(FSM).pdf multism.c switch1.cpp button1.cpp blinker.cpp mqtt.cpp config.h

$(FSM).c: $(FSM).smudge
	smudge $<

$(FSM).smudge: $(FSM_SRC)
	> $@
	cat fsm/fsm.smudge >> $@
	sed 's/button/button1/g' fsm/button.smudge >> $@
	sed 's/switch/switch1/g' fsm/switch.smudge >> $@
	cat fsm/blinker.smudge >> $@
	cat fsm/network.smudge >> $@
	cat fsm/mqtt.smudge >> $@

switch1.cpp: in/switch.cpp.in
	sed -e 's/SWITCH_NAME/1/g' -e 's/SWITCH_PIN/12/g' $< > $@

button1.cpp: in/button.cpp.in
	sed -e 's/BUTTON_NAME/1/g' -e 's/BUTTON_PIN/16/g' $< > $@

blinker.cpp: in/blinker.cpp.in
	sed 's/BLINKER_PIN/2/g' $< > $@

$(FSM).pdf: $(FSM).gv
	dot -Tpdf $(FSM).gv > $@

$(FSM).gv: $(FSM).c

multism.c: $(FSM).smudge scripts/smudge.py
	python3 scripts/smudge.py $< > $@

mqtt.cpp: in/mqtt.cpp.in scripts/switch_action.py
	python3 scripts/switch_action.py $< $(SWITCH_COUNT) > $@

config.h: config.sample.h Makefile
	sed -e 's/MQTT_USERNAME.*/MQTT_USERNAME "${PRODUCT_KEY}"/' \
		-e 's/MQTT_HOST.*/MQTT_HOST "${MQTT_HOST}"/' \
		-e 's/MQTT_PORT.*/MQTT_PORT ${MQTT_PORT}/' \
		-e 's/KEEP_SWITCH_STATE.*/KEEP_SWITCH_STATE ${KEEP_SWITCH_STATE}/' \
		-e 's/SWITCH_STATE_ON.*/SWITCH_STATE_ON ${SWITCH_STATE_ON}/' \
		-e 's/SWITCH_STATE_OFF.*/SWITCH_STATE_OFF ${SWITCH_STATE_OFF}/' \
		-e 's/DEFAULT_SWITCH_STATE.*/DEFAULT_SWITCH_STATE ${DEFAULT_SWITCH_STATE}/' \
		$< > $@

clean:
	rm -f $(FSM).c
	rm -f $(FSM).h
	rm -f $(FSM).pdf
	rm -f $(FSM)_ext.h
	rm -f $(FSM).gv
	rm -f multism.c
	rm -f switch1.cpp
	rm -f button1.cpp
	rm -f $(FSM).smudge
	rm -f blinker.cpp
	rm -f mqtt.cpp
	rm -r config.h
