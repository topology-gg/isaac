import sys
import numpy as np
import subprocess
import time
import json
from joblib import delayed, Parallel
from timeit import default_timer as timer

#
# Prep
#
CIV_SIZE = 3
UNIVERSE_COUNT = 1

#
# Load deployed address from json
#
f = open('declared_isaac.json')
json_str = json.load (f)
class_data = json.loads (json_str)

f = open('deployed_isaac.json')
json_str = json.load (f)
data = json.loads (json_str)

f = open('deployed_yagi_routers.json')
json_str = json.load (f)
data_yagi = json.loads (json_str)

#
# Print all addresses in pretty format
#
print()
print(f"#")
print(f"# Isaac's Class Hashes")
print(f"#")
print (f"> Universe class hash: {class_data['universe']['class_hash']}")
print (f"> Lobby class hash:    {class_data['lobby']['class_hash']}")
print (f"> Charter class hash:  {class_data['charter']['class_hash']}")
print (f"> FSM class hash:      {class_data['fsm']['class_hash']}")
print (f"> DAO class hash:      {class_data['dao']['class_hash']}")
print('\n')

print(f"#")
print(f"# Isaac's Proxy Contracts")
print(f"#")
for i in range(UNIVERSE_COUNT):
	print (f"> Universe #{i} Proxy deployed at: {data['deployed_proxies']['universes'][i]['addr']}")
print (f"> Lobby Proxy deployed at:       {data['deployed_proxies']['lobby']['addr']}")
print (f"> Charter Proxy deployed at:     {data['deployed_proxies']['charter']['addr']}")
print (f"> FSM-Subject Proxy deployed at: {data['deployed_proxies']['fsm_subject']['addr']}")
print (f"> FSM-Charter Proxy deployed at: {data['deployed_proxies']['fsm_charter']['addr']}")
print (f"> FSM-Angel   Proxy deployed at: {data['deployed_proxies']['fsm_angel']['addr']}")
print (f"> DAO Proxy deployed at:         {data['deployed_proxies']['dao']['addr']}")
print('\n')

print(f"#")
print(f"# Yagi router contracts")
print(f"#")
print (f"> Yagi-router-dao        deployed at {data_yagi['router-dao']['addr']}")
print (f"> Yagi-router-lobby      deployed at {data_yagi['router-lobby']['addr']}")

for i in range(UNIVERSE_COUNT):
	print (f"> Yagi-router-universe#{i} deployed at {data_yagi['routers-universe'][i]['addr']}")
print()