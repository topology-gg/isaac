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
CIV_SIZE = 1
UNIVERSE_COUNT = 1
GYOZA = '0x077d04506374b4920d6c35ecaded1ed7d26dd283ee64f284481e2574e77852c6'
tx_hashes = []

#
# Deploy N Universes
#
deployed_universes = []
for i in range(UNIVERSE_COUNT):
	deployed_universe = _deploy_contract (name = 'universe', subfolder = 'isaac')
	print(f"> Deployed universe #{i+1}/{UNIVERSE_COUNT}.")
	deployed_universes.append (deployed_universe)
tx_hashes += [ du['tx_hash'] for du in deployed_universes ]

#
# Deploy Lobby
#
deployed_lobby = _deploy_contract (name = 'lobby', subfolder = 'isaac')
print(f"> Deployed Lobby")
tx_hashes.append ( deployed_lobby['tx_hash'] )

#
# Deploy Charter
#
deployed_charter = _deploy_contract (name = 'charter', subfolder = 'isaac')
print(f"> Deployed Charter.")
tx_hashes.append ( deployed_charter['tx_hash'] )

#
# Deploy 3 FSMs
#
deployed_fsm_subject = _deploy_contract (name = 'fsm', subfolder = 'isaac')
deployed_fsm_charter = _deploy_contract (name = 'fsm', subfolder = 'isaac')
deployed_fsm_angel   = _deploy_contract (name = 'fsm', subfolder = 'isaac')
print(f"> Deployed 3 FSMs.")
tx_hashes += [
	deployed_fsm_subject ['tx_hash'],
	deployed_fsm_charter ['tx_hash'],
	deployed_fsm_angel   ['tx_hash']
]

#
# Deploy DAO
#
deployed_dao = _deploy_contract (name = 'dao', subfolder = 'isaac')
print(f"> Deployed DAO.")
tx_hashes.append ( deployed_dao['tx_hash'] )

#
# Waiting for all transactions to complete
#
print (f"> Waiting for all deployment transactions to complete")
_poll_list_tx_hashes_until_all_accepted (tx_hashes, interval_in_sec=30)
print (f"  => All deployment transactions completed.")

#
# Export deployment info to JSON
#
data = {
	'universes' : deployed_universes,
	'lobby' : deployed_lobby,
	'charter' : deployed_charter,
	'fsm_subject' : deployed_fsm_subject,
	'fsm_charter' : deployed_fsm_charter,
	'fsm_angel'   : deployed_fsm_angel,
	'dao'	      : deployed_dao
}
json_string = json.dumps(data)
with open('deployed_isaac.json', 'w') as f:
    json.dump (json_string, f)
print(f"> Exported to `deployed_isaac.json`: {json_string}")
