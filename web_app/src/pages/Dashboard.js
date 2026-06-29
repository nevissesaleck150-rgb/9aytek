import React, { useState, useEffect } from 'react';
import axios from 'axios';
import Sidebar from '../components/Sidebar';
import AppHeader from '../components/AppHeader';

const Dashboard = () => {
    const [transactions, setTransactions] = useState([]);
    const [stats, setStats] = useState({
        active_vendors: 0,
        active_influencers: 0,
        active_drivers: 0,
        total_orders: 0,
        daily_orders: 0,
        daily_topup_orders: 0,
        daily_course_orders: 0,
        pending_approvals: 0,
        revenue_by_shop: [],
        revenue_by_category: [],
    });

    // Palette de couleurs
    const primaryBlue = '#2A5AF1';
    const bgLight = '#F8FAFF';

    useEffect(() => {
        const fetchData = async () => {
            try {
                const token = localStorage.getItem('access_token');
                const [ordersRes, statsRes] = await Promise.all([
                    axios.get('http://127.0.0.1:8000/api/orders/', {
                        headers: { Authorization: `Bearer ${token}` }
                    }),
                    axios.get('http://127.0.0.1:8000/api/users/dashboard_stats/', {
                        headers: { Authorization: `Bearer ${token}` }
                    }),
                ]);
                setTransactions(ordersRes.data);
                setStats(statsRes.data);
            } catch (err) {
                console.error("Erreur", err);
            }
        };
        fetchData();
    }, []);

    const incompleteOrders = transactions.filter(
        (order) => order.status !== 'delivered'
    ).length;
    const activeCouriers = stats.active_drivers || 0;

    // ── Current week daily data (bar chart) ────────────────────────────
    const DAYS_FR = ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'];
    const MONTHS_FR = ['Jan','Fév','Mar','Avr','Mai','Juin','Juil','Aoû','Sep','Oct','Nov','Déc'];
    const today = new Date();

    // Get Monday of current week
    const dayOfWeek = today.getDay(); // 0=Sun, 1=Mon...
    const mondayOffset = dayOfWeek === 0 ? -6 : 1 - dayOfWeek;
    const monday = new Date(today);
    monday.setDate(today.getDate() + mondayOffset);
    monday.setHours(0, 0, 0, 0);

    // Build 7 daily buckets (Mon → Sun)
    const dayBuckets = Array.from({ length: 7 }, (_, i) => {
        const d = new Date(monday);
        d.setDate(monday.getDate() + i);
        return d;
    });

    const dayLabels = dayBuckets.map(d => DAYS_FR[d.getDay()]);

    const dailySales = dayBuckets.map((dayDate) => {
        const dayStart = new Date(dayDate);
        dayStart.setHours(0, 0, 0, 0);
        const dayEnd = new Date(dayDate);
        dayEnd.setHours(23, 59, 59, 999);
        return transactions
            .filter((order) => {
                const d = new Date(order.created_at);
                return d >= dayStart && d <= dayEnd;
            })
            .reduce((sum, order) => sum + (Number(order.total_amount) || 0), 0);
    });

    const weeklyTotal = dailySales.reduce((a, b) => a + b, 0);
    const weekLabel = `${monday.getDate()} ${MONTHS_FR[monday.getMonth()]} – ${dayBuckets[6].getDate()} ${MONTHS_FR[dayBuckets[6].getMonth()]}`;

    return (
        <div style={{ display: 'flex', backgroundColor: bgLight, minHeight: '100vh' }}>
            <Sidebar />
            <main style={{ marginLeft: '260px', flex: 1, padding: '40px' }}>
                
                <AppHeader
                    title="Tableau de bord"
                    subtitle="Vue d'ensemble en temps réel de votre marché"
                    actions={
                        <button onClick={() => window.print()} style={styles.printBtn}>
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{marginRight: '8px'}}>
                                <polyline points="6 9 6 2 18 2 18 9"></polyline>
                                <path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2"></path>
                                <rect x="6" y="14" width="12" height="8"></rect>
                            </svg>
                            Imprimer Rapport
                        </button>
                    }
                />

                {/* Cartes statistiques */}
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))', gap: '24px', marginBottom: '40px' }}>
                    <StatCard
                        label="Marchands actifs"
                        value={stats.active_vendors || 0}
                        unit="comptes"
                        color={primaryBlue}
                        icon={<><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z" /><polyline points="9 22 9 12 15 12 15 22" /></>}
                    />
                    <StatCard
                        label="Coursiers actifs"
                        value={activeCouriers}
                        unit="comptes"
                        color="#10B981"
                        icon={<><rect x="1" y="3" width="15" height="13" rx="2" /><path d="M16 8h4l3 5v4h-7V8z" /><circle cx="5.5" cy="18.5" r="2.5" /><circle cx="18.5" cy="18.5" r="2.5" /></>}
                    />
                    <StatCard
                        label="Commandes non terminées"
                        value={incompleteOrders}
                        unit="commandes"
                        color="#EC4899"
                        icon={<><circle cx="9" cy="21" r="1" /><circle cx="20" cy="21" r="1" /><path d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6" /></>}
                    />
                    <StatCard
                        label="Utilisateurs en attente"
                        value={stats.pending_approvals || 0}
                        unit="comptes"
                        color="#F59E0B"
                        icon={<><path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" /><circle cx="8.5" cy="7" r="4" /><line x1="20" y1="8" x2="20" y2="14" /><line x1="23" y1="11" x2="17" y2="11" /></>}
                    />
                </div>

                {/* Graphique de la semaine */}
                <div style={{...styles.tableCard, marginBottom: '40px', padding: '24px' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
                        <div>
                            <h3 style={{ margin: 0, color: '#0F172A', fontSize: '16px', fontWeight: '700' }}>Ventes — Semaine en cours</h3>
                            <p style={{ margin: '4px 0 0', color: '#64748B', fontSize: '12px' }}>
                                Analyse journalière — {weekLabel}
                            </p>
                        </div>
                        <span style={styles.statusPill}>Total : {weeklyTotal.toFixed(2)} MRU</span>
                    </div>
                    <WeeklyBarChart data={dailySales} labels={dayLabels} color={primaryBlue} todayIndex={today.getDay() === 0 ? 6 : today.getDay() - 1} />
                </div>

                {/* Dernières transactions */}
                <div style={styles.tableCard}>
                    <div style={{ marginBottom: '25px' }}>
                        <h3 style={{ fontSize: '18px', fontWeight: '700', color: '#0F172A' }}>Dernières Transactions</h3>
                    </div>
                    
                    <table style={{ width: '100%', borderCollapse: 'separate', borderSpacing: '0 8px' }}>
                        <thead>
                            <tr style={{ textAlign: 'left' }}>
                                <th style={styles.th}>REFERENCE</th>
                                <th style={styles.th}>UTILISATEUR</th>
                                <th style={styles.th}>MONTANT</th>
                                <th style={styles.th}>STATUT</th>
                                <th style={styles.th}>DATE</th>
                            </tr>
                        </thead>
                        <tbody>
                            {transactions.map(order => (
                                <tr key={order.id} style={styles.tableRow}>
                                    <td style={{...styles.td, fontWeight: '600', color: primaryBlue}}>#{order.id}</td>
                                    <td style={styles.td}>{order.customer_name || "Client Externe"}</td>
                                    <td style={{...styles.td, fontWeight: '700'}}>{(Number(order.total_amount) || 0).toFixed(2)} MRU</td>
                                    <td style={styles.td}>
                                        <span style={{ 
                                            padding: '4px 12px',
                                            borderRadius: '20px',
                                            fontSize: '12px',
                                            fontWeight: '600',
                                            backgroundColor: order.status === 'paid' ? '#ECFDF5' : '#FFF7ED',
                                            color: order.status === 'paid' ? '#10B981' : '#F97316',
                                        }}>
                                            {order.status.toUpperCase()}
                                        </span>
                                    </td>
                                    <td style={{...styles.td, color: '#94A3B8'}}>{new Date(order.created_at).toLocaleDateString()}</td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>
            </main>

            <style>
                {`
                    @media print {
                        .no-print, aside { display: none !important; }
                        main { margin-left: 0 !important; padding: 20px !important; }
                        body { background-color: white !important; }
                    }
                `}
            </style>
        </div>
    );
};

const StatCard = ({ label, value, unit, icon, color }) => (
    <div style={styles.card}>
        <div style={{ display: 'flex', justifyContent: 'space-between' }}>
            <div>
                <p style={styles.cardLabel}>{label}</p>
                <h2 style={styles.cardValue}>{value} <span style={{fontSize: '14px', color: '#94A3B8'}}>{unit}</span></h2>
            </div>
            <div style={{ 
                padding: '10px', 
                borderRadius: '12px', 
                backgroundColor: `${color}10`, 
                display: 'flex', 
                alignItems: 'center', 
                justifyContent: 'center' 
            }}>
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                    {icon}
                </svg>
            </div>
        </div>
    </div>
);

// ── Weekly Bar Chart (SVG) ─────────────────────────────────
const WeeklyBarChart = ({ data, labels, color, todayIndex }) => {
    const W = 700, H = 220, padTop = 24, padBottom = 32, padX = 36;
    const chartW = W - padX * 2;
    const chartH = H - padTop - padBottom;
    const maxVal = Math.max(...data, 1);
    const barGap = 14;
    const barWidth = (chartW - barGap * (data.length - 1)) / data.length;

    const gridLines = [0, 0.25, 0.5, 0.75, 1].map(frac => ({
        y: padTop + chartH - frac * chartH,
        label: Math.round(frac * maxVal).toLocaleString('fr-FR'),
    }));

    return (
        <svg viewBox={`0 0 ${W} ${H}`} style={{ width: '100%', height: 'auto' }}>
            <defs>
                <linearGradient id="barGrad" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stopColor={color} stopOpacity="1" />
                    <stop offset="100%" stopColor={color} stopOpacity="0.7" />
                </linearGradient>
            </defs>

            {/* Grid lines */}
            {gridLines.map((g, i) => (
                <g key={i}>
                    <line x1={padX} y1={g.y} x2={W - padX} y2={g.y} stroke="#E8EFFF" strokeWidth="1" />
                    <text x={padX - 6} y={g.y + 4} textAnchor="end" fill="#94A3B8" fontSize="10" fontWeight="600">{g.label}</text>
                </g>
            ))}

            {/* Bars */}
            {data.map((val, i) => {
                const barH = maxVal > 0 ? (val / maxVal) * chartH : 0;
                const x = padX + i * (barWidth + barGap);
                const y = padTop + chartH - barH;
                const isToday = i === todayIndex;
                return (
                    <g key={i}>
                        {/* Bar */}
                        <rect
                            x={x}
                            y={y}
                            width={barWidth}
                            height={Math.max(barH, 4)}
                            rx="8"
                            ry="8"
                            fill={val > 0 ? 'url(#barGrad)' : '#E2E8F0'}
                            opacity={isToday ? 1 : 0.8}
                        />
                        {/* Value label */}
                        <text
                            x={x + barWidth / 2}
                            y={y - 8}
                            textAnchor="middle"
                            fill="#0F172A"
                            fontSize="11"
                            fontWeight="700"
                        >
                            {val > 0 ? (val >= 1000 ? `${(val / 1000).toFixed(val % 1000 === 0 ? 0 : 1)}k` : val.toFixed(0)) : '—'}
                        </text>
                        {/* Day label */}
                        <text
                            x={x + barWidth / 2}
                            y={H - 10}
                            textAnchor="middle"
                            fill={isToday ? color : '#64748B'}
                            fontSize="12"
                            fontWeight={isToday ? '700' : '600'}
                        >
                            {labels[i]}
                        </text>
                    </g>
                );
            })}
        </svg>
    );
};


const styles = {
    card: { 
        backgroundColor: '#fff', 
        padding: '24px', 
        borderRadius: '20px', 
        border: '1px solid #E8EFFF',
        boxShadow: '0 4px 20px rgba(42, 90, 241, 0.03)'
    },
    cardLabel: { fontSize: '12px', color: '#64748B', fontWeight: '700', marginBottom: '8px', letterSpacing: '0.5px' },
    cardValue: { fontSize: '26px', color: '#0F172A', margin: '0', fontWeight: '800' },
    dateBadge: {
        backgroundColor: '#FFF',
        padding: '10px 16px',
        borderRadius: '12px',
        border: '1px solid #E2E8F0',
        fontSize: '13px',
        color: '#475569',
        fontWeight: '600'
    },
    smallRefreshBtn: {},
    statusPill: {
        backgroundColor: '#EFF6FF',
        color: '#2A5AF1',
        padding: '10px 14px',
        borderRadius: '999px',
        fontWeight: '700',
        fontSize: '13px'
    },
    chartGrid: {
        display: 'flex',
        alignItems: 'flex-end',
        gap: '18px',
        minHeight: '260px',
        paddingTop: '10px'
    },
    chartColumn: {
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        gap: '10px',
        flex: 1
    },
    chartBar: {
        width: '100%',
        borderRadius: '16px 16px 0 0',
        backgroundColor: '#2A5AF1',
        transition: 'height 0.3s ease'
    },
    chartLabel: {
        color: '#64748B',
        fontSize: '12px',
        fontWeight: '700'
    },
    tableCard: { 
        backgroundColor: '#fff', 
        padding: '30px', 
        borderRadius: '24px', 
        border: '1px solid #E8EFFF',
        boxShadow: '0 4px 20px rgba(42, 90, 241, 0.03)' 
    },
    printBtn: { 
        display: 'flex',
        alignItems: 'center',
        backgroundColor: '#2A5AF1', 
        border: 'none',
        padding: '10px 20px', 
        borderRadius: '12px', 
        color: '#fff', 
        cursor: 'pointer', 
        fontWeight: '700',
        fontSize: '13px',
        transition: 'background-color 0.2s'
    },
    th: { padding: '12px 20px', color: '#94A3B8', fontSize: '11px', fontWeight: '800', letterSpacing: '1px' },
    td: { padding: '16px 20px', color: '#334155', fontSize: '14px' },
    tableRow: {
        backgroundColor: '#FBFDFF',
    }
};

export default Dashboard;
