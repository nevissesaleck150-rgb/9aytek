import React from 'react';

const StatCard = ({ title, value, unit, iconPath, color }) => {
    // Visual identity: vivid blue and clean white.
    const primaryBlue = '#2A5AF1';
    const activeColor = color || primaryBlue;

    return (
        <div style={styles.card}>
            <div style={styles.header}>
                <div style={styles.titleContainer}>
                    <span style={styles.title}>{title}</span>
                    <div style={styles.valueContainer}>
                        <h2 style={styles.value}>{value}</h2>
                        {unit && <span style={styles.unit}>{unit}</span>}
                    </div>
                </div>
                
                {/* Linear icon container with a subtle blue background. */}
                <div style={{ 
                    ...styles.iconWrapper, 
                    backgroundColor: `${activeColor}08`,
                    border: `1px solid ${activeColor}15` 
                }}>
                    <svg 
                        width="22" 
                        height="22" 
                        viewBox="0 0 24 24" 
                        fill="none" 
                        stroke={activeColor} 
                        strokeWidth="1.8" 
                        strokeLinecap="round" 
                        strokeLinejoin="round"
                    >
                        {iconPath}
                    </svg>
                </div>
            </div>
            
            <div style={styles.footer}>
                <div style={styles.statusPulseContainer}>
                    <div style={styles.statusDot}></div>
                </div>
                <span style={styles.trend}>Mise à jour en temps réel</span>
            </div>
        </div>
    );
};

const styles = {
    card: {
        backgroundColor: '#FFFFFF',
        padding: '24px',
        borderRadius: '20px', 
        border: '1px solid #F0F4FF', 
        display: 'flex',
        flexDirection: 'column',
        justifyContent: 'space-between',
        flex: 1,
        minWidth: '260px',
        boxShadow: '0 10px 25px -5px rgba(42, 90, 241, 0.04)',
        transition: 'all 0.3s ease',
    },
    header: {
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'flex-start',
    },
    titleContainer: {
        display: 'flex',
        flexDirection: 'column',
        gap: '6px'
    },
    title: {
        fontSize: '14px',
        color: '#64748B', 
        fontWeight: '600',
        letterSpacing: '0.2px'
    },
    iconWrapper: {
        padding: '12px',
        borderRadius: '14px',
        display: 'flex',
        justifyContent: 'center',
        alignItems: 'center',
    },
    valueContainer: {
        display: 'flex',
        alignItems: 'baseline',
        gap: '6px',
        marginTop: '8px'
    },
    value: {
        fontSize: '32px',
        fontWeight: '800',
        color: '#0F172A',
        margin: 0,
        letterSpacing: '-0.8px'
    },
    unit: {
        fontSize: '14px',
        color: '#94A3B8',
        fontWeight: '700'
    },
    footer: {
        marginTop: '24px',
        display: 'flex',
        alignItems: 'center',
        gap: '10px',
        paddingTop: '16px',
        borderTop: '1px solid #F8FAFF'
    },
    statusPulseContainer: {
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        width: '12px',
        height: '12px'
    },
    statusDot: {
        width: '7px',
        height: '7px',
        backgroundColor: '#2A5AF1', // Blue status dot matching the theme.
        borderRadius: '50%',
    },
    trend: {
        fontSize: '11px',
        color: '#94A3B8',
        fontWeight: '600',
        textTransform: 'uppercase',
        letterSpacing: '0.5px'
    }
};

export default StatCard;
