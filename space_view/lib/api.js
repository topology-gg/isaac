import useSWR from "swr"

const fetcher = (...args) => fetch(...args).then(res => res.json())

export function useMacroStates() {
    return useSWR('/api/macro_state', fetcher)
}

export function useImpulses() {
    return useSWR('/api/impulses', fetcher)
}