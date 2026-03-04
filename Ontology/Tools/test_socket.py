import socket
import sys

def log(msg):
    with open('socket_debug.log', 'a') as f:
        f.write(msg + '\n')
    print(msg, flush=True)

try:
    with open('socket_debug.log', 'w') as f:
        f.write('--- Start ---\n')
        
    log('1. create socket')
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(5)
    
    log('2. connect to 127.0.0.1:7687')
    s.connect(('127.0.0.1', 7687))
    
    log('3. sending bolt magic bytes')
    s.sendall(b'\x60\x60\xb0\x17\x00\x00\x00\x04\x00\x00\x00\x03\x00\x00\x00\x02\x00\x00\x00\x01')
    
    log('4. waiting for response...')
    resp = s.recv(4)
    log(f'5. received: {resp}')
    s.close()
    
    log('6. done')
    
except Exception as e:
    log(f'ERROR: {type(e).__name__} - {e}')
