import '../styles/globals.css'
import NextHead from 'next/head'

function MyApp({ Component, pageProps }) {
  return (
    <>
        <NextHead>
            <title>S2M2</title>
        </NextHead>
        <Component {...pageProps} />
    </>
  )
}

export default MyApp
