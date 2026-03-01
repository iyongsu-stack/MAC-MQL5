import urllib.request
import json
import base64

url = 'http://127.0.0.1:7474/db/neo4j/tx/commit'
auth = b'neo4j:KIM10507'
headers = {
    'Authorization': 'Basic ' + base64.b64encode(auth).decode('utf-8'),
    'Content-Type': 'application/json'
}
data = {
    'statements': [{'statement': 'RETURN "Hello Graph" AS message'}]
}

try:
    print('Testing HTTP connection...')
    req = urllib.request.Request(url, data=json.dumps(data).encode('utf-8'), headers=headers)
    with urllib.request.urlopen(req, timeout=3) as response:
        print('HTTP Response:', response.read().decode('utf-8'))
except Exception as e:
    print('HTTP Error:', str(e))
