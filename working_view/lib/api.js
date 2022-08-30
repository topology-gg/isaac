import useSWR from "swr"

const fetcher = (...args) => fetch(...args).then(res => res.json())

export function useCivState () {
    return useSWR('/api/civ_state', fetcher)
}

export function usePlayerFungibleBalances () {
    return useSWR('/api/player_fungible_balances', fetcher)
}

export function usePlayerFungibleBalancesByAccount (account) {
    return useSWR(`/api/player_fungible_balances/${account}`, fetcher)
}

export function usePlayerNonfungibleDevicesByAccount (account) {
    return useSWR(`/api/player_nonfungible_devices/${account}`, fetcher)
}

export function useDeployedDevices () {
    return useSWR('/api/deployed_devices', fetcher)
}

export function useUtxSets () {
    return useSWR('/api/utx_sets', fetcher)
}

export function usePgs () {
    return useSWR('/api/pgs', fetcher)
}

export function useHarvesters () {
    return useSWR('/api/harvesters', fetcher)
}

export function useTransformers () {
    return useSWR('/api/transformers', fetcher)
}

export function useUpsfs () {
    return useSWR('/api/upsfs', fetcher)
}

export function useNdpes () {
    return useSWR('/api/ndpes', fetcher)
}

export function useMacroStates () {
    return useSWR('/api/macro_states', fetcher)
}