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
print(f"# Isaac contracts")
print(f"#")
for i in range(UNIVERSE_COUNT):
	print (f"> Universe #{i} deployed at {data['universes'][i]['addr']}")
print()

print (f"> Lobby deployed at {data['lobby']['addr']}\n")

print (f"> Charter deployed at {data['charter']['addr']}\n")

print (f"> FSM-Subject deployed at {data['fsm_subject']['addr']}")
print (f"> FSM-Charter deployed at {data['fsm_charter']['addr']}")
print (f"> FSM-Angel   deployed at {data['fsm_angel']['addr']}\n")

print (f"> DAO deployed at {data['dao']['addr']}\n\n")

print(f"#")
print(f"# Yagi router contracts")
print(f"#")
print (f"> Yagi-router-dao        deployed at {data_yagi['router-dao']['addr']}")
print (f"> Yagi-router-lobby      deployed at {data_yagi['router-lobby']['addr']}")

for i in range(UNIVERSE_COUNT):
	print (f"> Yagi-router-universe#{i} deployed at {data_yagi['routers-universe'][i]['addr']}")
print()