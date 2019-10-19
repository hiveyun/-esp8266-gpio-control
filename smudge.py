def gen_Send_Message(name):
    print('''
void {name}_Send_Message({name}_Event_Wrapper e) {
    DEBUG_println("{name}_Send_Message");
    msgs[currentQueueSize % MAX_QUEUE_LENGTH].sm = {NAME};
    msgs[currentQueueSize % MAX_QUEUE_LENGTH].wrapper.{name} = e;
    currentQueueSize += 1;
}'''.replace('{name}', name).replace('{NAME}', name.upper()))


def gen_sm_id_t(names):
    print('typedef enum {')
    for name in names:
        print('    {},'.format(name.upper()))
    print('} sm_id_t;')

def gen_system_message_t(names):
    print('''
typedef struct {
    sm_id_t sm;
    union {''')
    for name in names:
        print('        {}_Event_Wrapper {};'.format(name, name))
    print('''    } wrapper;
} system_message_t;''')

def gen_flushEventQueue(names):
    print('''
void flushEventQueue(void) {
    // This function could be running in a parallel thread
    // concurrently with the rest of the system. The important thing
    // is that it pops messages off the queue and sends them to
    // xxx_Handle_Message.
    system_message_t msg;

    while(currentIndex < currentQueueSize) {
        msg = msgs[currentIndex % MAX_QUEUE_LENGTH];
        currentIndex += 1;
        switch(msg.sm) {''')
    for name in names:
        print('''        case {NAME}:
            {name}_Handle_Message(msg.wrapper.{name});
            {name}_Free_Message(msg.wrapper.{name});
            break;'''.replace('{name}', name).replace('{NAME}', name.upper()))
    print('''        }
    }
}''')

def generate(ident, names):
    print('''/* This file is generated by smudge.py. Do not edit it. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include "multism.h"
#include "{}_ext.h"'''.format(ident))
    gen_sm_id_t(names)
    gen_system_message_t(names)

    print()
    print('system_message_t msgs[MAX_QUEUE_LENGTH];')
    print('unsigned long currentIndex;')
    print('unsigned long currentQueueSize;')

    gen_flushEventQueue(names)

    for name in names:
        gen_Send_Message(name)

    print('''
int initEventQueue() {
    DEBUG_println("initEventQueue");
    currentIndex = 0;
    currentQueueSize = 0;
    return 0;
}''')

def parse(filename):
    names = []
    with open(filename, 'r') as f:
        for line in f.readlines():
            line = line.strip()
            if line.endswith('{'):
                names.append(line[:-1].strip())

    return names

def main(script, filename):
    names = parse(filename)
    ident = filename.split('.')[0]

    generate(ident, names)

if __name__ == '__main__':
    import sys
    main(*sys.argv)
