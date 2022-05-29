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

def _deploy_contract (name, calldata = ''):
	if len(calldata) != 0:
		cmd = f'starknet deploy --contract artifacts/{name}_compiled.json --network alpha-goerli --inputs {calldata}'
	else:
		cmd = f'starknet deploy --contract artifacts/{name}_compiled.json --network alpha-goerli'
	print(f"> CMD = {cmd}")
	cmd = cmd.split(' ')
	deploy_ret = subprocess_run(cmd)
	deploy_ret = deploy_ret.split(': ')
	addr = deploy_ret[1].split('\n')[0]
	tx_hash = deploy_ret[-1]
	return {'addr':addr, 'tx_hash':tx_hash}

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
def _admin_store_addresses(name, contract_addr, idx, store_addr):
	cmd = f"starknet invoke --network=alpha --address {contract_addr} --abi ../{name}_abi.json --function admin_store_addresses --inputs {idx} {store_addr}"
	cmd = cmd.split(' ')
	ret = subprocess_run(cmd)
	ret = ret.split(': ')
	#addr = ret[1].split('\n')[0]
	tx_hash = ret[-1]
	return tx_hash

def _inference(contract_addr, img_input):
	img_input_string = [str(e) for e in img_input]
	img_input_joined = ' '.join(img_input_string)
	cmd = f"starknet call --network=alpha --address {contract_addr} --abi ../mnist_abi.json --function inference --inputs {img_input_joined}"
	cmd = cmd.split(' ')
	ret = subprocess_run(cmd)
	return ret

def _call(name, contract_addr, func_name, img_input):
	img_input_string = [str(e) for e in img_input]
	img_input_joined = ' '.join(img_input_string)
	cmd = f"starknet call --network=alpha --address {contract_addr} --abi ../{name}_abi.json --function {func_name} --inputs {img_input_joined}"
	cmd = cmd.split(' ')
	ret = subprocess_run(cmd)
	return ret

def _call_compute(name):
	img_input_string = [str(e) for e in IMG_INPUT]
	img_input_joined = ' '.join(img_input_string)
	cmd = f"starknet call --network=alpha --address {deployed_extracted[name]['addr']} --abi ../{name}_abi.json --function compute --inputs {img_input_joined}"
	cmd = cmd.split(' ')
	ret = subprocess_run(cmd)
	return ret

## Cairo constant
PRIME = 3618502788666131213697322783095070105623107215331596699973092056135872020481
PRIME_HALF = PRIME//2

# ###################################################

# ### Deployment steps (DAO + Lobby + Universes)
# 1. Deploy N Universes
# 2. Deploy Lobby, with N Universe addresses as constructor calldata
# 3. Invoke set_lobby_address_once() at each Universe, providing Lobby address
# 4. Deploy Charter
# 5. Deploy 3 FSMs, with its name (string literal) as constructor calldata
# 6. Deploy DAO, with Lobby + Charter + Angel + 3 FSM addresses as constructor calldata
# 7. Invoke set_dao_address_once() at Lobby, providing DAO address
# 8. Invoke init_owner_dao_address_once() at each FSMs, providing DAO address
# 9. Deploy all yagi routers
# 10. Hook up all yagi routers with respective addresses


#
# Prep
#
CIV_SIZE = 3
UNIVERSE_COUNT = 3
GYOZA = '0x077d04506374b4920d6c35ecaded1ed7d26dd283ee64f284481e2574e77852c6'
tx_hashes = []

#
# Deploy all universes
#
# print (f"> Deploying {UNIVERSE_COUNT} universe(s)")
# deployed_universes = []
# for i in range(UNIVERSE_COUNT):
# 	deployed_universe = _deploy_contract (name='universe')
# 	deployed_universes.append (deployed_universe)
# 	print (f"  ... universe {i}: address = {deployed_universe['addr']}; hash = {deployed_universe['tx_hash']}")

### Notice: universe contract bytecode is so big (30MB+) that deployment fails 50% of the time due to http error
### deploy manually now and copy addr + tx_hash here
# deployed_universes = [
# 	{
# 		'addr' : '0x075c7d53a13a30a1ce325c0b6537df20d658db8ce96a1ba3bb3d9358dae37bfd',
# 	 	'tx_hash' : '0x6bcd38d752cd7f10ff31ff420395fbf1fc94af5e5b55cc05818276421b8c48d'
# 	},
# 	{
# 		'addr' : '0x074d521b750a411430f574c9f99f1d371a74888c1316ced2f582d0d8f4f6bfc1',
# 		'tx_hash' : '0x46f1abe58befb46f142b7ab05fd79c1fa213d2d3bbad291d09c834f7cb609f4'
# 	},
# 	{
# 		'addr' : '0x01f38ab483020fdf5c0d8500d3839ebc9b6d4c6324f2f5fc0258094a173c87ff',
# 		'tx_hash' : '0x6330df996a754fda1a4c72540e382c146336362aa14448686b47dbedb7261be'
# 	}
# ]
# tx_hashes += [du['tx_hash'] for du in deployed_universes]


#
# Deploy lobby
#
print (f"> Deploying lobby")
calldata_array = [str(UNIVERSE_COUNT)] + [du['addr'] for du in deployed_universes]
calldat_string = ' '.join (calldata_array)
deployed_lobby = _deploy_contract (name='lobby', calldata=calldat_string)
print (f"  ... address = {deployed_lobby['addr']}; hash = {deployed_lobby['tx_hash']}")

tx_hashes.append (deployed_lobby['tx_hash'])

#
# Deploy charter
#
print (f"> Deploying charter")
deployed_charter = _deploy_contract (name='charter')
print (f"  ... address = {deployed_charter['addr']}; hash = {deployed_charter['tx_hash']}")

tx_hashes.append (deployed_charter['tx_hash'])

#
# Deploy fsm x 3
#
print (f"> Deploying 3 FSMs")
deployed_fsm_subject = _deploy_contract (name='fsm', calldata='111')
deployed_fsm_charter = _deploy_contract (name='fsm', calldata='222')
deployed_fsm_angel   = _deploy_contract (name='fsm', calldata='333')
print (f"  ... fsm for subject: address = {deployed_fsm_subject['addr']}; hash = {deployed_fsm_subject['tx_hash']}")
print (f"  ... fsm for charter: address = {deployed_fsm_charter['addr']}; hash = {deployed_fsm_charter['tx_hash']}")
print (f"  ... fsm for angel  : address = {deployed_fsm_angel['addr']}; hash = {deployed_fsm_angel['tx_hash']}")

tx_hashes += [
	deployed_fsm_subject['tx_hash'],
	deployed_fsm_charter['tx_hash'],
	deployed_fsm_angel  ['tx_hash']
]

#
# Deploy DAO
#
print (f"Deploying DAO")
calldata_array = [
	deployed_lobby   ['addr'],
	deployed_charter ['addr'],
	GYOZA,
	deployed_fsm_subject ['addr'],
	deployed_fsm_charter ['addr'],
	deployed_fsm_angel   ['addr']
]
calldat_string = ' '.join (calldata_array)
deployed_dao   = _deploy_contract (name='dao', calldata=calldat_string)
print (f"  ... address = {deployed_dao['addr']}; hash = {deployed_dao['tx_hash']}")

tx_hashes.append (deployed_dao['tx_hash'])

#
# Deploy yagi routers
#
print (f"> Deploying 3 yagi routers")
deployed_yagi_dao      = _deploy_contract (name='yagi_router_dao')
deployed_yagi_lobby    = _deploy_contract (name='yagi_router_lobby')
print (f"  ... yagi router for dao: address = {deployed_yagi_dao['addr']}; hash = {deployed_yagi_dao['tx_hash']}")
print (f"  ... yagi router for lobby: address = {deployed_yagi_lobby['addr']}; hash = {deployed_yagi_lobby['tx_hash']}")

deployed_yagi_router_universes = []
for i in range(UNIVERSE_COUNT):
	deployed_yagi_universe = _deploy_contract (name='yagi_router_universe')
	deployed_yagi_router_universes.append (deployed_yagi_universe)
	print (f"  ... yagi router for universe {i}: address = {deployed_yagi_universe['addr']}; hash = {deployed_yagi_universe['tx_hash']}")

tx_hashes += [
	deployed_yagi_dao      ['tx_hash'],
	deployed_yagi_lobby    ['tx_hash']
]
tx_hashes += [dyru['tx_hash'] for dyru in deployed_yagi_router_universes]

#
# Waiting for all transactions to complete
#
print (f"> Waiting for all deployment transactions to complete")
_poll_list_tx_hashes_until_all_accepted (tx_hashes, interval_in_sec=30)



############################################################################

## Universe 0 addr: 0x075c7d53a13a30a1ce325c0b6537df20d658db8ce96a1ba3bb3d9358dae37bfd
## Universe 1 addr: 0x074d521b750a411430f574c9f99f1d371a74888c1316ced2f582d0d8f4f6bfc1
## Universe 2 addr: 0x01f38ab483020fdf5c0d8500d3839ebc9b6d4c6324f2f5fc0258094a173c87ff

## Lobby addr: 0x01a30cb683558212aaa012b265c0d26a45644311014e885f6278eb72f9992291

## Charter addr: 0x0147ab4b254c965d36ba2924b259ede11a8963371d9f8c23c598e058765ffa64

## FSM-Subject addr: 0x074e066f5eea98afe4188cc0a489df9d8ab2c091d406d13c6e1e4f375b5f7a51
## FSM-Charter addr: 0x019e92195f5e9ee601e2c39e7c35997a58e8457182a552ce5b3573a29d4c4b52
## FSM-Angel addr  : 0x04e345c5977c9af1e0b195dc144998cc4335d4498b623b67e9fe06cface01e74

## DAO addr: 0x06b02619485cf7eb34ef79056493cbbc4d480544465531c15f794890a504dcc9

## Yagi router for DAO addr      : 0x04cea4776844c6b2a332e8c291c4846a32949d396649508d9a2e639ebc83bfab
## Yagi router for Lobby addr    : 0x062a92e4635ab1a4107be8669b790608a65b8626f66a749e53795a7d6b54d1f1
## Yagi router for Universe0 addr: 0x05822493e78d840e11bda49af5934bde2af93f47a3dea8e9e74588b0c313b733
## Yagi router for Universe1 addr: 0x07723221aa0d8e1836792c8bac5d900e6f33979973ddc56983a7b173d280ac5e
## Yagi router for Universe2 addr: 0x03ad196a02644d68cc063222f65da085da3f612ab82163ddd00f61a11073a385

## NEXT:

## - Invoke set_lobby_address_once() at each Universe, providing Lobby address
## - Invoke set_dao_address_once() at Lobby, providing DAO address

## - Invoke init_owner_dao_address_once() at each FSMs, providing DAO address

## - Hook up all yagi routers with respective addresses
##   (do on Voyager, because access restricted to GYOZA on argent X)
