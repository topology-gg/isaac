import useSWR from "swr"

const fetcher = (...args) => fetch(...args).then(res => res.json())

export function usePuzzles () {
    return useSWR('/api/puzzles', fetcher)
}

export function useS2mState () {
    return useSWR('/api/state', fetcher)
}
