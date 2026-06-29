import React from 'react';

const primaryBlue = '#2A5AF1';

const AppHeader = ({ title, subtitle, actions }) => {
    const username = localStorage.getItem('username') || 'Admin';

    return (
        <div style={styles.headerContainer}>
            <div>
                <div style={styles.welcomeRow}>
                    <div style={styles.brandAvatar}>
                        <span style={styles.brandInitial}>9</span>
                    </div>
                    <div>
                        <p style={styles.welcomeText}>Bienvenue, {username}</p>
                        <h1 style={styles.title}>{title}</h1>
                        <p style={styles.subtitle}>{subtitle}</p>
                    </div>
                </div>
            </div>
            <div style={styles.actionsRow}>
                {actions}
                <button
                    style={styles.notificationBtn}
                    aria-label="Notifications"
                    onClick={() => alert('Pas de nouvelles notifications pour le moment.')}
                >
                    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke={primaryBlue} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                        <path d="M18 8a6 6 0 0 0-12 0c0 7-3 9-3 9h18s-3-2-3-9" />
                        <path d="M13.73 21a2 2 0 0 1-3.46 0" />
                    </svg>
                </button>
            </div>
        </div>
    );
};

const styles = {
    headerContainer: {
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'flex-start',
        gap: '18px',
        marginBottom: '40px',
        flexWrap: 'wrap'
    },
    welcomeRow: {
        display: 'flex',
        alignItems: 'center',
        gap: '18px'
    },
    brandAvatar: {
        width: '54px',
        height: '54px',
        borderRadius: '18px',
        backgroundColor: '#EFF6FF',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center'
    },
    brandInitial: {
        color: primaryBlue,
        fontSize: '20px',
        fontWeight: '900'
    },
    welcomeText: {
        margin: 0,
        color: '#64748B',
        fontSize: '13px',
        fontWeight: '600'
    },
    title: {
        margin: '6px 0 6px',
        color: '#0F172A',
        fontSize: '30px',
        lineHeight: '1.05',
        fontWeight: '800'
    },
    subtitle: {
        margin: 0,
        color: '#64748B',
        fontSize: '14px'
    },
    actionsRow: {
        display: 'flex',
        alignItems: 'center',
        gap: '14px',
        flexWrap: 'wrap'
    },
    notificationBtn: {
        position: 'relative',
        width: '48px',
        height: '48px',
        borderRadius: '16px',
        border: '1px solid #E2E8F0',
        backgroundColor: '#FFFFFF',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        cursor: 'pointer'
    },

};

export default AppHeader;
