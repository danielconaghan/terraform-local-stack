import { useState, useEffect } from 'react'

export default function App() {
  const [message, setMessage] = useState(null)
  const [error, setError] = useState(null)

  useEffect(() => {
    const apiUrl = window.ENV?.apiUrl
    if (!apiUrl) {
      setError('API URL not configured (window.ENV.apiUrl is missing)')
      return
    }

    fetch(apiUrl)
      .then(res => {
        if (!res.ok) throw new Error(`HTTP ${res.status}`)
        return res.json()
      })
      .then(data => setMessage(data.message))
      .catch(err => setError(err.message))
  }, [])

  return (
    <div style={{ fontFamily: 'sans-serif', maxWidth: 600, margin: '80px auto', textAlign: 'center' }}>
      <h1>LocalStack Hello World</h1>
      {message && <p style={{ fontSize: '1.5rem', color: 'green' }}>{message}</p>}
      {error && <p style={{ color: 'red' }}>Error: {error}</p>}
      {!message && !error && <p style={{ color: '#888' }}>Fetching from PHP service...</p>}
    </div>
  )
}
