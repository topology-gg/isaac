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


## Reference on try-except-else variable scoping:
## https://stackoverflow.com/questions/25666853/how-to-make-a-variable-inside-a-try-except-block-public
def _compile_contract (path, name, subfolder):
	cmd = f'starknet-compile {path} --output ../deploy/artifacts/{subfolder}/{name}_compiled.json --abi ../deploy/artifacts/{subfolder}/{name}_abi.json'
	cmd = cmd.split(' ')
	deploy_ret = subprocess_run(cmd)
	assert len(deploy_ret) == 0


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


# ###################################################

name = 'universe'
path = 'contracts/universe/universe.cairo'
subfolder = 'isaac'
_compile_contract (path, name, subfolder)

name = 'lobby'
path = 'contracts/lobby/lobby.cairo'
subfolder = 'isaac'
_compile_contract (path, name, subfolder)

###

name = 'yagi_router_dao'
path = 'contracts/yagi/yagi_router_dao.cairo'
subfolder = 'yagi'
_compile_contract (path, name, subfolder)

name = 'yagi_router_lobby'
path = 'contracts/yagi/yagi_router_lobby.cairo'
subfolder = 'yagi'
_compile_contract (path, name, subfolder)

name = 'yagi_router_universe'
path = 'contracts/yagi/yagi_router_universe.cairo'
subfolder = 'yagi'
_compile_contract (path, name, subfolder)

