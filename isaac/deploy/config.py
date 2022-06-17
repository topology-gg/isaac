import sys
import numpy as np
import subprocess
import time
import json
from joblib import delayed, Parallel
from timeit import default_timer as timer

def subprocess_run (cmd):
	result = subprocess.run(cmd, stdout=subprocess.PIPE)
	result = result.stdout.decode('utf-8')[:-1] # remove trailing newline
	return result

## Reference on try-except-else variable scoping: https://stackoverflow.com/questions/25666853/how-to-make-a-variable-inside-a-try-except-block-public
def _deploy_contract (name, subfolder):
	return _deploy_contract_bounded (name, subfolder, 0)

def _deploy_contract_bounded (name, subfolder, iteration):
	if iteration == 20:
		print (f"> something's wrong! terminating.")
		raise

	cmd = f'starknet deploy --contract artifacts/{subfolder}/{name}_compiled.json --network alpha-goerli'
	cmd = cmd.split(' ')

	try:
		deploy_ret = subprocess_run(cmd)
		print(f"... deploy_ret = {deploy_ret}")
		deploy_ret = deploy_ret.split(': ')
		addr = deploy_ret[1].split('\n')[0]
		tx_hash = deploy_ret[-1]
		return {'cmd' : cmd, 'addr' : addr, 'tx_hash' : tx_hash}
	except:
		print(f"  ... iteration {iteration} failed. Trying again")
		return _deploy_contract_bounded (name, subfolder, iteration+1) ## recursive call


## polling list of hashes over given time interval until all accepted on StarkNet
## cached accepted tx_hash to avoid unnecessary polling of accepted tx
def _poll_list_tx_hashes_until_all_accepted(list_of_tx_hashes, interval_in_sec):
	accepted_list = [False for _ in list_of_tx_hashes]

	while True:
		all_accepted = True
		print(f'  ... begin polling tx status.')
		for i, tx_hash in enumerate(list_of_tx_hashes):
			if accepted_list[i]:
				continue
			cmd = f"starknet tx_status --network alpha-goerli --hash={tx_hash}".split(' ')
			ret = subprocess_run(cmd)
			ret = json.loads(ret)
			if ret['tx_status'] not in ['ACCEPTED_ON_L2', 'ACCEPTED_ON_L1']:
				print(f"> {tx_hash} ({ret['tx_status']}) not accepted on L2 yet.")
				all_accepted = False
				break
			else:
				print(f"> {i}th hash {tx_hash} is accepted on L2.")
				accepted_list[i] = True
		if all_accepted:
			break
		else:
			print(f'  ... retry polling in {interval_in_sec} seconds.')
			time.sleep(interval_in_sec)
	print(f'> all tx hashes are accepted onchain.')
	return


## invoking admin_store_addresses of contract
def invoke (addr, abi, func, inputs):
	cmd = f"starknet invoke --network alpha-goerli --address {addr} --abi {abi} --function {func} --inputs {inputs} --max_fee 1"
	cmd_arr = cmd.split(' ')
	ret = subprocess_run(cmd_arr)
	ret = ret.split(': ')
	#addr = ret[1].split('\n')[0]
	tx_hash = ret[-1]
	return tx_hash

## Cairo constant
PRIME = 3618502788666131213697322783095070105623107215331596699973092056135872020481
PRIME_HALF = PRIME//2

# ###################################################

#
# Prep
#
CIV_SIZE = 3
UNIVERSE_COUNT = 3

tx_hashes = []

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
# At each Universe, invoke set_lobby_address_once(), providing Lobby address
#
print (f"> At each universe contract, set lobby address")
for i in range(UNIVERSE_COUNT):
	tx_hash = invoke (
		addr = data['universes'][0]['addr'],
		abi = "artifacts/isaac/universe_abi.json",
		func = "set_lobby_address_once",
		inputs = data['lobby']['addr']
	)
	tx_hashes.append (tx_hash)

#
# At Lobby, invoke set_dao_address_once(), providing DAO address
#
print (f"> At lobby contract, set dao address")
tx_hash = invoke (
	addr = data['lobby']['addr'],
	abi = "artifacts/isaac/lobby_abi.json",
	func = "set_dao_address_once",
	inputs = data['dao']['addr']
)
tx_hashes.append (tx_hash)

#
# At Lobby, invoke set_universe_addresses_once(), providing universe addresses
#
print (f"> At lobby contract, set universe addresses")
calldata = f"{UNIVERSE_COUNT}" + " " + " ".join([ d['addr'] for d in data['universes'] ])
tx_hash = invoke (
	addr = data['lobby']['addr'],
	abi = "artifacts/isaac/lobby_abi.json",
	func = "set_universe_addresses_once",
	inputs = calldata
)
tx_hashes.append (tx_hash)


#
# At each FSM, invoke init_owner_dao_address_once(), providing DAO address
#
print (f"> At each fsm contract, set dao address")
for target in ['subject', 'charter', 'angel']:
	tx_hash = invoke (
		addr = data[f'fsm_{target}']['addr'],
		abi = "artifacts/isaac/fsm_abi.json",
		func = "init_owner_dao_address_once",
		inputs = data['dao']['addr']
	)
	tx_hashes.append (tx_hash)

#
# At DAO, invoke set_votable_and_fsm_addresses_once(), providing all addresses required
#
print (f"> At DAO contract, set all required addresses (Subject, Charter, Angel, and their associated FSMs")
calldata = " ".join([
	data['lobby']['addr'],
	data['charter']['addr'],
	"0x03a400ab224a8b60c99bae61821a0b83a02690742d2cb4cd0755510ebb21f897", # gyoza's argent account
	data['fsm_subject']['addr'],
	data['fsm_charter']['addr'],
	data['fsm_angel']['addr']
])
tx_hash = invoke (
	addr = data['dao']['addr'],
	abi = "artifacts/isaac/dao_abi.json",
	func = "set_votable_and_fsm_addresses_once",
	inputs = calldata
)
tx_hashes.append (tx_hash)

#
# Hook up all yagi routers with respective addresses, using the correct password
#
print (f"> Hook up all yagi routers - 1 for dao, 1 for lobby, and 1 for each universe")
PASSWORD = sys.argv[1]

tx_hash = invoke (
	addr = data_yagi['router-dao']['addr'],
	abi = "artifacts/yagi/yagi_router_dao_abi.json",
	func = "change_isaac_dao_address",
	inputs = f"{PASSWORD} {data['dao']['addr']}"
)
tx_hashes.append (tx_hash)

tx_hash = invoke (
	addr = data_yagi['router-lobby']['addr'],
	abi = "artifacts/yagi/yagi_router_lobby_abi.json",
	func = "change_isaac_lobby_address",
	inputs = f"{PASSWORD} {data['lobby']['addr']}"
)
tx_hashes.append (tx_hash)

for i in range(UNIVERSE_COUNT):
	tx_hash = invoke (
		addr = data_yagi['routers-universe'][i]['addr'],
		abi = "artifacts/yagi/yagi_router_universe_abi.json",
		func = "change_isaac_universe_address",
		inputs = f"{PASSWORD} {data['universes'][i]['addr']}"
	)
	tx_hashes.append (tx_hash)

#
# Waiting for all transactions to complete
#
print (f"> Waiting for all deployment transactions to complete")
_poll_list_tx_hashes_until_all_accepted (tx_hashes, interval_in_sec=30)
print (f"  => All deployment transactions completed.")

############################################################################

## Yagi router for DAO addr      : 0x04cea4776844c6b2a332e8c291c4846a32949d396649508d9a2e639ebc83bfab
## Yagi router for Lobby addr    : 0x062a92e4635ab1a4107be8669b790608a65b8626f66a749e53795a7d6b54d1f1
## Yagi router for Universe0 addr: 0x05822493e78d840e11bda49af5934bde2af93f47a3dea8e9e74588b0c313b733
## Yagi router for Universe1 addr: 0x07723221aa0d8e1836792c8bac5d900e6f33979973ddc56983a7b173d280ac5e
## Yagi router for Universe2 addr: 0x03ad196a02644d68cc063222f65da085da3f612ab82163ddd00f61a11073a385

########

## NEXT:

## - At each Universe, invoke set_lobby_address_once(), providing Lobby address
## - At Lobby, invoke set_dao_address_once(), providing DAO address

## - At each FSM, invoke init_owner_dao_address_once(), providing DAO address

## - Hook up all yagi routers with respective addresses
##   (do on Voyager, because access restricted to GYOZA on argent X)
