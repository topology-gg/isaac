import { useCallback } from "react";
import { useEffect, useRef } from "react";

/**
 * useEffect, but debounced
 * when dependencies change rapidly, this effect is only called
 * after {wait} miliseconds have passed without updates
 */
export default function useDebouncedEffect(callback, dependencies, wait) {
    // track timeout handle between calls
    const timeout = useRef();

    const debouncedCallback = useCallback(() => {
        // Reset and restart the timer, so the work is done once after the last timer fires
        cleanup();

        timeout.current = setTimeout(() => {
            callback();
        }, wait);
    }, [...dependencies, wait])

    function cleanup() {
        if (timeout.current) {
            clearTimeout(timeout.current);
        }
    }

    useEffect(() => {
        debouncedCallback();

        // make sure our timeout gets cleared if
        // our consuming component gets unmounted
        return cleanup;
    }, [...dependencies, debouncedCallback]);

    return debouncedCallback;
}
