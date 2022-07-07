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