import useSWR from "swr"

const fetcher = (...args) => fetch(...args).then(res => res.json())

export function useCivState () {
    return useSWR('/api/civ_state', fetcher)
}

export function useCivStates () {
    return useSWR('/api/civ_states', fetcher)
}

export function usePlayerBalances () {
    return useSWR('/api/player_balances', fetcher)
}

export function useLobbyQueue () {
    return useSWR('/api/lobby_queue', fetcher)
}

export function useMacroStates () {
    return useSWR('/api/macro_states', fetcher)
}

export function useMacroStatesAll () {
    return useSWR('/api/macro_states_all', fetcher)
}

export function useStardiscRegistryAll () {
    return useSWR('/api/stardisc_registry', fetcher)
}

export function useStardiscRegistryByAccount (account) {
    return useSWR(`/api/stardisc_registry/${account}`, fetcher)
}