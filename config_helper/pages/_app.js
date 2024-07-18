import '../styles/globals.css'
import NextHead from 'next/head'

function MyApp({ Component, pageProps }) {
  return (
    <>
        <NextHead>
            <title>Isaac: Config</title>
        </NextHead>
        <Component {...pageProps} />
    </>
  )
}

export default MyApp
