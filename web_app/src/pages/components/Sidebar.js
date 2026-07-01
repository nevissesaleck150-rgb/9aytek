import React from 'react';
import { useNavigate, useLocation } from 'react-router-dom';

const Sidebar = () => {
    const navigate = useNavigate();
    const location = useLocation();

    // Navigation links for the digital services dashboard.
    const menuItems = [
        { id: 'dash', name: 'Tableau de bord', path: '/dashboard', icon: '📊' },
        { id: 'topup', name: 'Recharge Apps', path: '/topup', icon: '📱' },
        { id: 'lms', name: 'Gestion des Cours', path: '/lms', icon: '🎓' },
        { id: 'users', name: 'Utilisateurs', path: '/users', icon: '👥' },
        { id: 'finance', name: 'Finance & Splitter', path: '/finance', icon: '💸' },
    ];

    const handleLogout = () => {
        localStorage.clear();
        navigate('/');
    };

    return (
        <aside style={styles.sidebar}>
            <div style={styles.brandSection}>
                <div style={styles.logoIcon}>DS</div>
                <h2 style={styles.brandName}>Admin Panel</h2>
            </div>

            <nav style={styles.nav}>
                {menuItems.map((item) => (
                    <div 
                        key={item.id}
                        onClick={() => navigate(item.path)}
                        style={{
                            ...styles.navLink,
                            ...(location.pathname === item.path ? styles.activeNavLink : {})
                        }}
                    >
                        <span style={styles.icon}>{item.icon}</span>
                        {item.name}
                    </div>
                ))}
            </nav>

            <div style={styles.footer}>
                <button onClick={handleLogout} style={styles.logoutBtn}>
                    🚪 Déconnexion
                </button>
            </div>
        </aside>
    );
};

const styles = {
    sidebar: {
        width: '260px',
        height: '100vh',
        backgroundColor: '#FFFFFF',
        borderRight: '1px solid #E5E7EB',
        display: 'flex',
        flexDirection: 'column',
        position: 'fixed',
        left: 0,
        top: 0,
    },
    brandSection: {
        padding: '30px 20px',
        display: 'flex',
        alignItems: 'center',
        gap: '12px',
        borderBottom: '1px solid #F3F4F6',
        marginBottom: '20px'
    },
    logoIcon: {
        width: '35px',
        height: '35px',
        backgroundColor: '#3B82F6',
        borderRadius: '8px',
        color: '#fff',
        display: 'flex',
        justifyContent: 'center',
        alignItems: 'center',
        fontWeight: 'bold'
    },
    brandName: {
        fontSize: '18px',
        color: '#111827',
        margin: 0,
        fontWeight: '700'
    },
    nav: {
        flex: 1,
        padding: '0 15px',
        display: 'flex',
        flexDirection: 'column',
        gap: '8px'
    },
    navLink: {
        padding: '12px 15px',
        borderRadius: '10px',
        color: '#6B7280',
        cursor: 'pointer',
        fontSize: '14px',
        fontWeight: '500',
        display: 'flex',
        alignItems: 'center',
        gap: '12px',
        transition: 'all 0.2s ease'
    },
    activeNavLink: {
        backgroundColor: '#EFF6FF',
        color: '#3B82F6',
        fontWeight: '600'
    },
    icon: {
        fontSize: '18px'
    },
    footer: {
        padding: '20px',
        borderTop: '1px solid #F3F4F6'
    },
    logoutBtn: {
        width: '100%',
        padding: '10px',
        backgroundColor: '#EF4444',
        border: '1px solid #EF4444',
        color: '#000000',
        borderRadius: '8px',
        cursor: 'pointer',
        fontSize: '13px',
        fontWeight: '700'
    }
};

export default Sidebar;
