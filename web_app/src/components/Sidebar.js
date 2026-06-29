import React from 'react';
import { useNavigate, useLocation } from 'react-router-dom';

const Sidebar = () => {
    const navigate = useNavigate();
    const location = useLocation();

    // Menu with linear SVG icons.
    const menuItems = [
        { id: 'dash', name: 'Tableau de bord', path: '/dashboard', icon: <path d="M3 13h8V3H3v10zm0 8h8v-6H3v6zm10 0h8V11h-8v10zm0-18v6h8V3h-8z"/> },
        { id: 'users', name: 'Utilisateurs', path: '/users', icon: <path d="M16 11c1.66 0 2.99-1.34 2.99-3S17.66 5 16 5s-3 1.34-3 3 1.34 3 3 3zm-8 0c1.66 0 2.99-1.34 2.99-3S9.66 5 8 5 5 6.34 5 8s1.34 3 3 3zm0 2c-2.33 0-7 1.17-7 3.5V19h14v-2.5c0-2.33-4.67-3.5-7-3.5zm8 0c-.29 0-.62.02-.97.05 1.16.84 1.97 1.97 1.97 3.45V19h6v-2.5c0-2.33-4.67-3.5-7-3.5z"/> },
        { id: 'shops', name: 'Boutiques', path: '/shops', icon: <path d="M20 6H4a2 2 0 0 0-2 2v10a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2V8a2 2 0 0 0-2-2Zm0 12H4V8h16v10Zm-4-8H8V9h8Zm0 4H8v-1h8Z"/> },
        { id: 'lms', name: 'Cours', path: '/lms', icon: <path d="M12 3L1 9l11 6 9-4.91V17h2V9L12 3zM3.89 9.5l8.11-4.42 8.11 4.42-8.11 4.42L3.89 9.5zM12 18l-7-3.82v2.32l7 3.82 7-3.82v-2.32L12 18z"/> },
        { id: 'topup', name: 'Recharge Apps', path: '/topup', icon: <path d="M17 1.01L7 1c-1.1 0-2 .9-2 2v18c0 1.1.9 2 2 2h10c1.1 0 2-.9 2-2V3c0-1.1-.9-1.99-2-1.99zM17 19H7V5h10v14z"/> },
        { id: 'finance', name: 'Finance', path: '/finance', icon: <path d="M21 7.28V5c0-1.1-.9-2-2-2H5c-1.11 0-2 .9-2 2v14c0 1.1.89 2 2 2h14c1.1 0 2-.9 2-2v-2.28c.59-.35 1-.98 1-1.72V9c0-.74-.41-1.37-1-1.72zM20 9v6h-7V9h7zM5 19V5h14v2h-6c-1.1 0-2 .9-2 2v6c0 1.1.9 2 2 2h6v2H5z"/> },
        { id: 'orders', name: 'Commandes', path: '/orders', icon: <path d="M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm-5 14H7v-2h7v2zm3-4H7v-2h10v2zm0-4H7V7h10v2z"/> },
    ];

    const handleLogout = () => {
        localStorage.clear();
        navigate('/');
    };

    return (
        <aside style={styles.sidebar}>
            <div style={styles.brandSection}>
                <img src="/logo.png" alt="9aytek" style={styles.logoImage} />
            </div>

            <nav style={styles.nav}>
                {menuItems.map((item) => {
                    const isActive = location.pathname === item.path;
                    return (
                        <div 
                            key={item.id}
                            onClick={() => navigate(item.path)}
                            style={{
                                ...styles.navLink,
                                ...(isActive ? styles.activeNavLink : {})
                            }}
                        >
                            <svg 
                                width="20" 
                                height="20" 
                                viewBox="0 0 24 24" 
                                fill={isActive ? "#2A5AF1" : "#64748B"}
                                style={styles.icon}
                            >
                                {item.icon}
                            </svg>
                            {item.name}
                        </div>
                    );
                })}
            </nav>

            <div style={styles.footer}>
                <button onClick={handleLogout} style={styles.logoutBtn}>
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{marginRight: '8px'}}>
                        <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"></path>
                        <polyline points="16 17 21 12 16 7"></polyline>
                        <line x1="21" y1="12" x2="9" y2="12"></line>
                    </svg>
                    Déconnexion
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
        borderRight: '1px solid #E8EFFF',
        display: 'flex',
        flexDirection: 'column',
        position: 'fixed',
        left: 0,
        top: 0,
        zIndex: 1000,
    },
    brandSection: {
        padding: '24px 24px',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        marginBottom: '10px'
    },
    logoImage: {
        width: '100px',
        height: 'auto',
        objectFit: 'contain',
        display: 'block'
    },
    logoIcon: {
        width: '38px',
        height: '38px',
        backgroundColor: '#2A5AF1',
        borderRadius: '12px',
        color: '#fff',
        display: 'flex',
        justifyContent: 'center',
        alignItems: 'center',
        fontWeight: '900',
        fontSize: '20px',
    },
    brandName: {
        fontSize: '19px',
        color: '#2A5AF1',
        margin: 0,
        fontWeight: '800',
        letterSpacing: '-0.5px'
    },
    nav: {
        flex: 1,
        padding: '0 16px',
        display: 'flex',
        flexDirection: 'column',
        gap: '4px'
    },
    navLink: {
        padding: '14px 16px',
        borderRadius: '12px',
        color: '#64748B',
        cursor: 'pointer',
        fontSize: '14px',
        fontWeight: '500',
        display: 'flex',
        alignItems: 'center',
        gap: '12px',
        transition: 'all 0.2s ease',
    },
    activeNavLink: {
        backgroundColor: '#F0F4FF',
        color: '#2A5AF1',
        fontWeight: '600',
    },
    icon: {
        flexShrink: 0,
    },
    footer: {
        padding: '24px 16px',
        borderTop: '1px solid #F1F5F9'
    },
    logoutBtn: {
        width: '100%',
        padding: '12px',
        backgroundColor: '#EF4444',
        border: '1px solid #EF4444',
        color: '#000000',
        borderRadius: '10px',
        cursor: 'pointer',
        fontSize: '14px',
        fontWeight: '600',
        display: 'flex',
        justifyContent: 'center',
        alignItems: 'center',
    }
};

export default Sidebar;
