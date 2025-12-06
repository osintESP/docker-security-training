import React, { useState, useEffect, useCallback } from 'react';

const API_URL = process.env.REACT_APP_API_URL || 'http://localhost:3001';

function App() {
  const [btcPrice, setBtcPrice] = useState(null);
  const [priceHistory, setPriceHistory] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [apiVersion, setApiVersion] = useState('');
  const [apiHealth, setApiHealth] = useState(null);
  const [lastUpdate, setLastUpdate] = useState(null);
  const [autoRefresh, setAutoRefresh] = useState(true);

  const fetchBtcPrice = useCallback(async () => {
    try {
      const response = await fetch(`${API_URL}/api/bitcoin/price`);
      if (!response.ok) throw new Error('Error al obtener precio BTC');
      const data = await response.json();
      setBtcPrice(data);
      setLastUpdate(new Date());
      setError(null);
    } catch (err) {
      setError('Error al obtener precio BTC: ' + err.message);
    }
  }, []);

  const fetchPriceHistory = async () => {
    try {
      const response = await fetch(`${API_URL}/api/bitcoin/history?limit=10`);
      if (!response.ok) throw new Error('Error al obtener historial');
      const data = await response.json();
      setPriceHistory(data);
    } catch (err) {
      console.error('Error al obtener historial:', err);
    }
  };

  const recordPrice = async () => {
    try {
      const response = await fetch(`${API_URL}/api/bitcoin/record`, {
        method: 'POST',
      });
      if (!response.ok) throw new Error('Error al registrar precio');
      fetchPriceHistory();
    } catch (err) {
      setError('Error al registrar precio: ' + err.message);
    }
  };

  const fetchVersion = async () => {
    try {
      const response = await fetch(`${API_URL}/version`);
      const data = await response.json();
      setApiVersion(data.version);
    } catch (err) {
      console.error('Error al obtener version:', err);
    }
  };

  const fetchHealth = async () => {
    try {
      const response = await fetch(`${API_URL}/health`);
      const data = await response.json();
      setApiHealth(data.status);
    } catch (err) {
      setApiHealth('unhealthy');
    }
  };

  useEffect(() => {
    const initFetch = async () => {
      setLoading(true);
      await Promise.all([fetchBtcPrice(), fetchPriceHistory(), fetchVersion(), fetchHealth()]);
      setLoading(false);
    };
    initFetch();
  }, [fetchBtcPrice]);

  useEffect(() => {
    if (!autoRefresh) return;
    const interval = setInterval(() => {
      fetchBtcPrice();
      fetchHealth();
    }, 15000);
    return () => clearInterval(interval);
  }, [autoRefresh, fetchBtcPrice]);

  const formatPrice = (price) => {
    return new Intl.NumberFormat('es-AR', {
      style: 'currency',
      currency: 'USD',
      minimumFractionDigits: 2
    }).format(price);
  };

  const formatChange = (change) => {
    const formatted = change?.toFixed(2);
    const isPositive = change >= 0;
    return { value: `${isPositive ? '+' : ''}${formatted}%`, isPositive };
  };

  const styles = {
    container: {
      maxWidth: '1000px',
      margin: '0 auto',
      padding: '30px 20px',
    },
    header: {
      textAlign: 'center',
      marginBottom: '20px',
    },
    title: {
      fontSize: '2.2rem',
      marginBottom: '8px',
      background: 'linear-gradient(90deg, #f7931a, #ffcd00)',
      WebkitBackgroundClip: 'text',
      WebkitTextFillColor: 'transparent',
    },
    subtitle: {
      color: '#888',
      fontSize: '1rem',
    },
    entregaFinal: {
      background: 'linear-gradient(135deg, rgba(0, 212, 255, 0.1) 0%, rgba(123, 44, 191, 0.1) 100%)',
      borderRadius: '12px',
      padding: '15px 20px',
      marginBottom: '25px',
      border: '1px solid rgba(0, 212, 255, 0.3)',
      textAlign: 'center',
    },
    entregaTitle: {
      fontSize: '1.1rem',
      fontWeight: 'bold',
      color: '#00d4ff',
      marginBottom: '8px',
    },
    entregaInfo: {
      display: 'flex',
      justifyContent: 'center',
      gap: '20px',
      flexWrap: 'wrap',
      fontSize: '0.85rem',
      color: '#aaa',
    },
    statusBar: {
      display: 'flex',
      justifyContent: 'center',
      gap: '15px',
      marginBottom: '25px',
      flexWrap: 'wrap',
    },
    statusBadge: {
      padding: '6px 14px',
      borderRadius: '20px',
      fontSize: '0.8rem',
      display: 'flex',
      alignItems: 'center',
      gap: '6px',
    },
    healthy: {
      background: 'rgba(0, 255, 136, 0.15)',
      border: '1px solid #00ff88',
      color: '#00ff88',
    },
    unhealthy: {
      background: 'rgba(255, 68, 68, 0.15)',
      border: '1px solid #ff4444',
      color: '#ff4444',
    },
    priceCard: {
      background: 'linear-gradient(135deg, rgba(247, 147, 26, 0.1) 0%, rgba(255, 205, 0, 0.05) 100%)',
      borderRadius: '20px',
      padding: '30px',
      marginBottom: '25px',
      border: '1px solid rgba(247, 147, 26, 0.3)',
      textAlign: 'center',
    },
    btcSymbol: {
      fontSize: '3rem',
      marginBottom: '10px',
    },
    mainPrice: {
      fontSize: '3.5rem',
      fontWeight: 'bold',
      color: '#f7931a',
      marginBottom: '10px',
    },
    priceChange: {
      fontSize: '1.3rem',
      marginBottom: '15px',
    },
    positive: { color: '#00ff88' },
    negative: { color: '#ff4444' },
    otherPrices: {
      display: 'flex',
      justifyContent: 'center',
      gap: '30px',
      marginTop: '15px',
      flexWrap: 'wrap',
    },
    otherPrice: {
      color: '#aaa',
      fontSize: '1rem',
    },
    card: {
      background: 'rgba(255, 255, 255, 0.05)',
      borderRadius: '16px',
      padding: '25px',
      marginBottom: '25px',
      border: '1px solid rgba(255, 255, 255, 0.1)',
    },
    cardHeader: {
      display: 'flex',
      justifyContent: 'space-between',
      alignItems: 'center',
      marginBottom: '20px',
      flexWrap: 'wrap',
      gap: '10px',
    },
    cardTitle: {
      fontSize: '1.2rem',
      margin: 0,
    },
    button: {
      padding: '10px 20px',
      borderRadius: '8px',
      border: 'none',
      background: 'linear-gradient(90deg, #f7931a, #ffcd00)',
      color: '#000',
      fontSize: '0.9rem',
      cursor: 'pointer',
      fontWeight: '600',
    },
    table: {
      width: '100%',
      borderCollapse: 'collapse',
    },
    th: {
      textAlign: 'left',
      padding: '12px',
      borderBottom: '1px solid rgba(255,255,255,0.1)',
      color: '#888',
      fontSize: '0.85rem',
    },
    td: {
      padding: '12px',
      borderBottom: '1px solid rgba(255,255,255,0.05)',
      fontSize: '0.9rem',
    },
    error: {
      background: 'rgba(255, 68, 68, 0.1)',
      border: '1px solid #ff4444',
      borderRadius: '8px',
      padding: '15px',
      marginBottom: '20px',
      color: '#ff4444',
    },
    loading: {
      textAlign: 'center',
      color: '#888',
      padding: '40px',
    },
    footer: {
      textAlign: 'center',
      marginTop: '30px',
      color: '#666',
      fontSize: '0.8rem',
    },
    toggle: {
      display: 'flex',
      alignItems: 'center',
      gap: '8px',
      fontSize: '0.85rem',
      color: '#888',
    },
    checkbox: {
      accentColor: '#f7931a',
    },
    securitySection: {
      background: 'rgba(255, 255, 255, 0.03)',
      borderRadius: '12px',
      padding: '20px',
      marginBottom: '20px',
      border: '1px solid rgba(255, 255, 255, 0.08)',
    },
    securityTitle: {
      fontSize: '1rem',
      marginBottom: '15px',
      color: '#00d4ff',
    },
    securityGrid: {
      display: 'grid',
      gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
      gap: '10px',
    },
    securityItem: {
      display: 'flex',
      alignItems: 'center',
      gap: '8px',
      fontSize: '0.85rem',
      color: '#888',
    },
    checkIcon: {
      color: '#00ff88',
    },
  };

  if (loading) {
    return (
      <div style={styles.container}>
        <div style={styles.loading}>Cargando datos de Bitcoin...</div>
      </div>
    );
  }

  const change = btcPrice ? formatChange(btcPrice.change_24h) : null;

  return (
    <div style={styles.container}>
      <header style={styles.header}>
        <h1 style={styles.title}>Bitcoin Price Tracker</h1>
        <p style={styles.subtitle}>Seguridad Docker + BTC/USD en Tiempo Real</p>
      </header>

      {/* Seccion Entrega Final */}
      <div style={styles.entregaFinal}>
        <div style={styles.entregaTitle}>Entrega Final - Docker Security Training</div>
        <div style={styles.entregaInfo}>
          <span>Arquitectura: Frontend + API + PostgreSQL</span>
          <span>|</span>
          <span>Contenedores Seguros</span>
          <span>|</span>
          <span>Multi-stage Builds</span>
        </div>
      </div>

      <div style={styles.statusBar}>
        <div style={{...styles.statusBadge, ...(apiHealth === 'healthy' ? styles.healthy : styles.unhealthy)}}>
          <span>{apiHealth === 'healthy' ? '●' : '○'}</span>
          API: {apiHealth === 'healthy' ? 'Saludable' : 'Sin conexion'}
        </div>
        {apiVersion && (
          <div style={{...styles.statusBadge, ...styles.healthy}}>
            v{apiVersion}
          </div>
        )}
        <div style={{...styles.statusBadge, background: 'rgba(247,147,26,0.15)', border: '1px solid #f7931a', color: '#f7931a'}}>
          BTC En Vivo
        </div>
      </div>

      {error && <div style={styles.error}>{error}</div>}

      {btcPrice && (
        <div style={styles.priceCard}>
          <div style={styles.btcSymbol}>₿</div>
          <div style={styles.mainPrice}>{formatPrice(btcPrice.prices.usd)}</div>
          {change && (
            <div style={{...styles.priceChange, ...(change.isPositive ? styles.positive : styles.negative)}}>
              {change.value} (24h)
            </div>
          )}
          <div style={styles.otherPrices}>
            <span style={styles.otherPrice}>EUR: €{btcPrice.prices.eur?.toLocaleString('es-AR')}</span>
            <span style={styles.otherPrice}>GBP: £{btcPrice.prices.gbp?.toLocaleString('es-AR')}</span>
          </div>
          <div style={{marginTop: '15px', color: '#666', fontSize: '0.8rem'}}>
            Ultima actualizacion: {lastUpdate?.toLocaleTimeString('es-AR')}
          </div>
        </div>
      )}

      <div style={styles.card}>
        <div style={styles.cardHeader}>
          <h2 style={styles.cardTitle}>Historial de Precios</h2>
          <div style={{display: 'flex', gap: '10px', alignItems: 'center'}}>
            <label style={styles.toggle}>
              <input
                type="checkbox"
                checked={autoRefresh}
                onChange={(e) => setAutoRefresh(e.target.checked)}
                style={styles.checkbox}
              />
              Auto-actualizar
            </label>
            <button onClick={recordPrice} style={styles.button}>
              Registrar Precio
            </button>
          </div>
        </div>

        {priceHistory.length === 0 ? (
          <p style={{color: '#666', textAlign: 'center'}}>
            Sin historial aun. Haz clic en "Registrar Precio" para comenzar el seguimiento.
          </p>
        ) : (
          <table style={styles.table}>
            <thead>
              <tr>
                <th style={styles.th}>Fecha/Hora</th>
                <th style={styles.th}>USD</th>
                <th style={styles.th}>EUR</th>
                <th style={styles.th}>Cambio 24h</th>
              </tr>
            </thead>
            <tbody>
              {priceHistory.map((record) => {
                const recordChange = formatChange(parseFloat(record.change_24h));
                return (
                  <tr key={record.id}>
                    <td style={styles.td}>{new Date(record.recorded_at).toLocaleString('es-AR')}</td>
                    <td style={styles.td}>{formatPrice(record.price_usd)}</td>
                    <td style={styles.td}>€{parseFloat(record.price_eur).toLocaleString('es-AR')}</td>
                    <td style={{...styles.td, ...(recordChange.isPositive ? styles.positive : styles.negative)}}>
                      {recordChange.value}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        )}
      </div>

      {/* Seccion de Seguridad */}
      <div style={styles.securitySection}>
        <h3 style={styles.securityTitle}>Caracteristicas de Seguridad Implementadas</h3>
        <div style={styles.securityGrid}>
          <div style={styles.securityItem}>
            <span style={styles.checkIcon}>✓</span>
            <span>Imagenes Alpine (minimas)</span>
          </div>
          <div style={styles.securityItem}>
            <span style={styles.checkIcon}>✓</span>
            <span>Multi-stage builds</span>
          </div>
          <div style={styles.securityItem}>
            <span style={styles.checkIcon}>✓</span>
            <span>Usuario non-root</span>
          </div>
          <div style={styles.securityItem}>
            <span style={styles.checkIcon}>✓</span>
            <span>Versiones pineadas</span>
          </div>
          <div style={styles.securityItem}>
            <span style={styles.checkIcon}>✓</span>
            <span>Health checks</span>
          </div>
          <div style={styles.securityItem}>
            <span style={styles.checkIcon}>✓</span>
            <span>Rate limiting</span>
          </div>
          <div style={styles.securityItem}>
            <span style={styles.checkIcon}>✓</span>
            <span>Headers de seguridad (Helmet)</span>
          </div>
          <div style={styles.securityItem}>
            <span style={styles.checkIcon}>✓</span>
            <span>Sin secretos hardcodeados</span>
          </div>
        </div>
      </div>

      <div style={styles.footer}>
        <p>Datos de CoinGecko API | Se actualiza cada 15 segundos</p>
        <p style={{marginTop: '10px', fontSize: '0.75rem', color: '#555'}}>
          Docker Security Training - Proyecto Final
        </p>
      </div>
    </div>
  );
}

export default App;
