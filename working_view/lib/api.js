import useSWR from "swr"

const fetcher = (...args) => fetch(...args).then(res => res.json())

export function useCivState () {
    return useSWR('/api/civ_state', fetcher)
}

export function usePlayerBalances () {
    return useSWR('/api/player_balances', fetcher)
}

export function useDeployedDevices () {
    return useSWR('/api/deployed_devices', fetcher)
}

export function useUtxSets () {
    return useSWR('/api/utx_sets', fetcher)
}

export function useDeployedPgs () {
    return useSWR('/api/deployed_pgs', fetcher)
}

export function useDeployedHarvesters () {
    return useSWR('/api/deployed_harvesters', fetcher)
}

export function useDeployedTransformers () {
    return useSWR('/api/deployed_transformers', fetcher)
}

export function useDeployedUpsfs () {
    return useSWR('/api/deployed_upsfs', fetcher)
}

export function useDeployedNdpes () {
    return useSWR('/api/deployed_ndpes', fetcher)
}

export function useMacroStates () {
    return useSWR('/api/macro_states', fetcher)
}