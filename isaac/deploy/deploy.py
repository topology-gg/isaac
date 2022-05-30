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
deployed_universes = [
	{
		'addr' : '0x0685335b2e9dd0a86a62bc36967e1851879f3a54f58b2d46491796ffa52e9fc3',
	 	'tx_hash' : '0x6c670f03d6b48ada1ee0e8b3509647d4bc84abb39059eca93f32e266295d617'
	},
	{
		'addr' : '0x03bceee3ed7433f30d5f4ae875bd66bd3815f619201544fb878d0b23476c061d',
		'tx_hash' : '0x46e83ac7f900598d30b98910c95d2996cdc7d3287bdd3d2d8adb11c352ff35e'
	},
	{
		'addr' : '0x02cc448248a32ac01eada379f0a3c083073aab53c7a224db705eaa66602c1285',
		'tx_hash' : '0x75763dd931709cd0b556dad4cdcf1443690b0d3fb34fafcc9c5fb818a923a65'
	}
]
tx_hashes += [du['tx_hash'] for du in deployed_universes]


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

## Universe 0 addr: 0x0685335b2e9dd0a86a62bc36967e1851879f3a54f58b2d46491796ffa52e9fc3
## Universe 1 addr: 0x03bceee3ed7433f30d5f4ae875bd66bd3815f619201544fb878d0b23476c061d
## Universe 2 addr: 0x02cc448248a32ac01eada379f0a3c083073aab53c7a224db705eaa66602c1285

## Lobby addr: 0x07cd09ef24b9d466f2e76e3f842135c2941f624df59aefb485e20e1adc16d0fe

## Charter addr: 0x07f3a54b17ba9d625a3f7707388b51467e4964390308377b7aba0930a01e987f

## FSM-Subject addr: 0x062d7b33c4a349c9e8fe4bd2002baa50786f2e9a61f3a2f1934e165182d1b81c
## FSM-Charter addr: 0x0525b6c6d8e6247e28b7959d5ecf303517634c7eb41491011bf5a6d6ec485423
## FSM-Angel addr  : 0x002575c68810b4c7697d54bda398e9301f8a7540a32c210507fdcb848eb33468

## DAO addr: 0x04db73a3c6e3c8ff55cab9a4a19ea6b9a99b8df9a976cd313f75f55934afb944

## Yagi router for DAO addr      : 0x07e8f0fd6f89a0e654b723ad08de07b1efc6ccc4acd7ea6d88ec05e17027d743
## Yagi router for Lobby addr    : 0x077a86cf3115699e913eecd8f9aca8e166afefb9d870fe94a32b2e0c362b63da
## Yagi router for Universe0 addr: 0x020fc0703cbc218a9a81d4bae17750c87d3508caf8c329a476f987aa98ec2617
## Yagi router for Universe1 addr: 0x024b003cf9bb949308c067d41d1b2bb8f7c8597bee0b28c33a3aa8ed4eee579f
## Yagi router for Universe2 addr: 0x0538ac941e5a3495548acc6aa97d5614960bf9b9befb99f7e8bf40461a31c0b3

## NEXT:

## - At each Universe, invoke set_lobby_address_once(), providing Lobby address
## - At Lobby, invoke set_dao_address_once(), providing DAO address

## - At each FSM, invoke init_owner_dao_address_once(), providing DAO address

## - Hook up all yagi routers with respective addresses
##   (do on Voyager, because access restricted to GYOZA on argent X)
