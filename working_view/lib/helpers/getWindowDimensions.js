export default function getWindowDimensions() {
    if (typeof window !== 'undefined') {
        const { innerWidth: width, innerHeight: height } = window;
        // console.log("window is defined!")
        return { width, height };
    } else {
        // console.log('You are on the server')
        return { width : 700, height : 815 }
    }
}
