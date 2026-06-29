import React, { useState } from 'react';
import axios from 'axios';
import { useNavigate } from 'react-router-dom';

const api = axios.create({
    baseURL: 'http://127.0.0.1:8000',
});

const Login = () => {
    const [credentials, setCredentials] = useState({ username: '', password: '' });
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');
    const navigate = useNavigate();

    const handleChange = (e) => {
        setCredentials({ ...credentials, [e.target.name]: e.target.value });
    };

    const handleLogin = async (e) => {
        e.preventDefault();
        setLoading(true);
        setError('');
        
        try {
            const res = await api.post('/api/custom-login/', credentials);
            if (res.status === 200) {
                const accessToken = res.data.access;
                localStorage.setItem('access_token', accessToken);
                localStorage.setItem('is_logged_in', 'true');

                const userRes = await api.get('/api/auth/users/me/', {
                    headers: { 'Authorization': `Bearer ${accessToken}` }
                });

                localStorage.setItem('username', userRes.data.username);
                localStorage.setItem('user_role', userRes.data.role);
                navigate('/dashboard');
            }
        } catch (err) {
            if (err.response && err.response.status === 403) {
                setError('Votre compte est en attente d\'approbation par l\'administrateur.');
            } else if (err.response && err.response.status === 401) {
                setError('Nom d\'utilisateur ou mot de passe incorrect.');
            } else {
                setError('Erreur de connexion au serveur.');
            }
        } finally {
            setLoading(false);
        }
    };

    return (
        <div style={styles.container}>
            <div style={styles.loginBox}>
                <div style={styles.logoSection}>
                    <div style={styles.iconCircle}>
                        <img src="/logo.png" alt="9aytek" style={styles.logoImage} />
                    </div>
                    <h1 style={styles.brandName}>9aytek Admin</h1>
                    <p style={styles.subTitle}>Bienvenue sur la plateforme</p>
                </div>

                {error && <div style={styles.errorAlert}>{error}</div>}

                <form onSubmit={handleLogin} style={styles.form}>
                    <div style={styles.field}>
                        <label style={styles.label}>Nom d'utilisateur</label>
                        <div style={styles.inputWrapper}>
                            <input 
                                name="username"
                                type="text" 
                                style={styles.input} 
                                placeholder="Identifiant"
                                onChange={handleChange}
                                required 
                            />
                        </div>
                    </div>

                    <div style={styles.field}>
                        <label style={styles.label}>Mot de passe</label>
                        <div style={styles.inputWrapper}>
                            <input 
                                name="password"
                                type="password" 
                                style={styles.input} 
                                placeholder="••••••••"
                                onChange={handleChange}
                                required 
                            />
                        </div>
                    </div>

                    <button type="submit" style={styles.submitBtn} disabled={loading}>
                        {loading ? 'Chargement...' : 'Se connecter'}
                    </button>
                </form>

            </div>
        </div>
    );
};

const styles = {
    container: { 
        height: '100vh', 
        display: 'flex', 
        flexDirection: 'column', 
        justifyContent: 'center', 
        alignItems: 'center', 
        backgroundColor: '#F8FAFF' 
    },
    loginBox: { 
        backgroundColor: '#FFFFFF', 
        padding: '40px', 
        borderRadius: '24px', 
        width: '380px', 
        boxShadow: '0 10px 30px rgba(42, 90, 241, 0.05)', 
        border: '1px solid #E8EFFF' 
    },
    logoSection: { textAlign: 'center', marginBottom: '36px' },
    iconCircle: {
        width: '72px',
        height: '72px',
        backgroundColor: 'transparent',
        borderRadius: '20px',
        display: 'flex',
        justifyContent: 'center',
        alignItems: 'center',
        margin: '0 auto 18px',
    },
    brandName: { color: '#0F172A', fontSize: '26px', margin: 0, fontWeight: '800', letterSpacing: '-0.5px' },
    subTitle: { color: '#64748B', fontSize: '14px', marginTop: '6px' },
    form: { display: 'flex', flexDirection: 'column', gap: '24px' },
    field: { display: 'flex', flexDirection: 'column', gap: '8px' },
    label: { fontSize: '13px', color: '#475569', fontWeight: '600', marginLeft: '4px' },
    inputWrapper: { position: 'relative' },
    input: { 
        width: '100%',
        padding: '14px 16px', 
        borderRadius: '12px', 
        border: '1px solid #E2E8F0', 
        backgroundColor: '#FFFFFF', 
        outline: 'none',
        fontSize: '15px',
        transition: 'all 0.2s ease',
        boxSizing: 'border-box'
    },
    submitBtn: { 
        padding: '14px', 
        backgroundColor: '#2A5AF1', 
        color: '#fff', 
        border: 'none', 
        borderRadius: '12px', 
        cursor: 'pointer', 
        fontWeight: '700', 
        fontSize: '15px',
        boxShadow: '0 4px 12px rgba(42, 90, 241, 0.2)',
        transition: 'all 0.2s ease' 
    },
    errorAlert: { 
        backgroundColor: '#FFF1F1', 
        color: '#EF4444', 
        padding: '12px', 
        borderRadius: '12px', 
        fontSize: '13px', 
        marginBottom: '20px', 
        textAlign: 'center', 
        border: '1px solid #FFE4E4' 
    },
    logoImage: { width: '68px', height: '68px', objectFit: 'contain' }
};

export default Login;