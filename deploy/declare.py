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
def _declare_contract (name, subfolder):
	return _declare_contract_bounded (name, subfolder, 0)

def _declare_contract_bounded (name, subfolder, iteration):
	if iteration == 20:
		print (f"> something's wrong! terminating.")
		raise

	cmd = f'starknet declare --contract artifacts/{subfolder}/{name}_compiled.json --network alpha-goerli'
	cmd = cmd.split(' ')

	try:
		declare_ret = subprocess_run(cmd)
		print(f"... declare_ret = {declare_ret}")
		declare_ret = declare_ret.split(': ')
		class_hash = declare_ret[1].split('\n')[0]
		tx_hash = declare_ret[-1]
		return {'cmd' : cmd, 'class_hash' : class_hash, 'tx_hash' : tx_hash}
	except:
		print(f"  ... iteration {iteration} failed. Trying again")
		return _declare_contract_bounded (name, subfolder, iteration+1) ## recursive call



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
def invoke (cmd):
	# cmd = f"starknet invoke --network=alpha --address {contract_addr} --abi ../{name}_abi.json --function admin_store_addresses --inputs {idx} {store_addr}"
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
UNIVERSE_COUNT = 1
GYOZA = '0x077d04506374b4920d6c35ecaded1ed7d26dd283ee64f284481e2574e77852c6'
tx_hashes = []

#
# Declare Universe
#
declared_universe = _declare_contract (name = 'universe', subfolder = 'isaac')
print(f"> Declared Universe")
tx_hashes.append ( declared_universe['tx_hash'] )

#
# Deploy Lobby
#
declared_lobby = _declare_contract (name = 'lobby', subfolder = 'isaac')
print(f"> Declared Lobby")
tx_hashes.append ( declared_lobby['tx_hash'] )

#
# Deploy Charter
#
declared_charter = _declare_contract (name = 'charter', subfolder = 'isaac')
print(f"> Declared Charter.")
tx_hashes.append ( declared_charter['tx_hash'] )

#
# Deploy FSM
#
declared_fsm = _declare_contract (name = 'fsm', subfolder = 'isaac')
print(f"> Declared FSM.")
tx_hashes.append ( declared_fsm ['tx_hash'] )

#
# Deploy DAO
#
declared_dao = _declare_contract (name = 'dao', subfolder = 'isaac')
print(f"> Declared DAO.")
tx_hashes.append ( declared_dao['tx_hash'] )

#
# Waiting for all transactions to complete
#
print (f"> Waiting for all declare transactions to complete")
_poll_list_tx_hashes_until_all_accepted (tx_hashes, interval_in_sec=30)
print (f"  => All declare transactions completed.")

#
# Export declare info to JSON
#
data = {
	'universe'    : declared_universe,
	'lobby'       : declared_lobby,
	'charter'     : declared_charter,
	'fsm'         : declared_fsm,
	'dao'	      : declared_dao
}
json_string = json.dumps(data)
with open('declared_isaac.json', 'w') as f:
    json.dump (json_string, f)
print(f"> Exported to `declared_isaac.json`: {json_string}")
