import React from 'react';

const StatCard = ({ title, value, unit, icon, color }) => {
    return (
        <div style={{ ...styles.card, borderTop: `4px solid ${color || '#3B82F6'}` }}>
            <div style={styles.header}>
                <span style={styles.title}>{title}</span>
                <span style={{ ...styles.icon, color: color || '#3B82F6' }}>{icon}</span>
            </div>
            <div style={styles.valueContainer}>
                <h2 style={styles.value}>{value}</h2>
                {unit && <span style={styles.unit}>{unit}</span>}
            </div>
            <div style={styles.footer}>
                <span style={styles.trend}>Mise à jour en temps réel</span>
            </div>
        </div>
    );
};

const styles = {
    card: {
        backgroundColor: '#FFFFFF',
        padding: '20px',
        borderRadius: '12px',
        boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.05), 0 2px 4px -1px rgba(0, 0, 0, 0.03)',
        display: 'flex',
        flexDirection: 'column',
        gap: '10px',
        flex: 1,
        minWidth: '200px'
    },
    header: {
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
    },
    title: {
        fontSize: '14px',
        color: '#64748B',
        fontWeight: '600',
        textTransform: 'uppercase',
        letterSpacing: '0.5px'
    },
    icon: {
        fontSize: '20px',
        backgroundColor: '#F8FAFC',
        padding: '8px',
        borderRadius: '8px'
    },
    valueContainer: {
        display: 'flex',
        alignItems: 'baseline',
        gap: '5px',
        marginTop: '5px'
    },
    value: {
        fontSize: '28px',
        fontWeight: '700',
        color: '#1E293B',
        margin: 0
    },
    unit: {
        fontSize: '14px',
        color: '#94A3B8',
        fontWeight: '500'
    },
    footer: {
        marginTop: '10px',
        paddingTop: '10px',
        borderTop: '1px solid #F1F5F9'
    },
    trend: {
        fontSize: '11px',
        color: '#10B981', // Academic green for success.
        fontWeight: '600'
    }
};

export default StatCard;
