// src/pages/Finance.js
import React, { useState, useEffect } from 'react';
import axios from 'axios';
import Sidebar from '../components/Sidebar';
import AppHeader from '../components/AppHeader';

const primaryBlue = '#2A5AF1';
const bgLight = '#F8FAFF';

// StatCard aligned with the Dashboard style.
const StatCard = ({ label, value, unit, icon, color }) => (
    <div style={cardStyles.card}>
        <div style={{ display: 'flex', justifyContent: 'space-between' }}>
            <div>
                <p style={cardStyles.cardLabel}>{label}</p>
                <h2 style={cardStyles.cardValue}>
                    {value} <span style={{ fontSize: '14px', color: '#94A3B8' }}>{unit}</span>
                </h2>
            </div>
            <div style={{
                padding: '10px',
                borderRadius: '12px',
                backgroundColor: `${color}15`,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center'
            }}>
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none"
                    stroke={color} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                    {icon}
                </svg>
            </div>
        </div>
    </div>
);

// ─────────────────────────────────────────────────────────────
const Finance = () => {
    const [transactions, setTransactions] = useState([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const fetchFinanceData = async () => {
            try {
                const token = localStorage.getItem('access_token');
                const res = await axios.get('http://127.0.0.1:8000/api/finance/', {
                    headers: { Authorization: `Bearer ${token}` }
                });
                setTransactions(res.data);
                setLoading(false);
            } catch (err) {
                console.error('Erreur lors du chargement des données financières', err);
                setLoading(false);
            }
        };
        fetchFinanceData();
    }, []);

    const totalAdminProfit = transactions.reduce(
        (acc, curr) => acc + parseFloat(curr.platform_share || 0), 0
    );
    const totalVolume = transactions.reduce(
        (acc, curr) => acc + parseFloat(curr.vendor_share || 0) + parseFloat(curr.influencer_share || 0) + parseFloat(curr.platform_share || 0), 0
    );

    return (
        <div style={{ display: 'flex', backgroundColor: bgLight, minHeight: '100vh' }}>
            <Sidebar />
            <main style={{ marginLeft: '260px', flex: 1, padding: '40px' }}>
                <AppHeader
                    title="Finance"
                    subtitle="Suivi des paiements et des fonds réservés aux administrateurs"
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
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '24px', marginBottom: '40px' }}>
                    <StatCard
                        label="ARGENT PAYÉ"
                        value={totalVolume.toFixed(2)}
                        unit="MRU"
                        color={primaryBlue}
                        icon={
                            <>
                                <rect x="1" y="4" width="22" height="16" rx="2" ry="2" />
                                <line x1="1" y1="10" x2="23" y2="10" />
                            </>
                        }
                    />
                    <StatCard
                        label="ARGENT ADMIN"
                        value={totalAdminProfit.toFixed(2)}
                        unit="MRU"
                        color="#10B981"
                        icon={
                            <>
                                <polyline points="23 6 13.5 15.5 8.5 10.5 1 18" />
                                <polyline points="17 6 23 6 23 12" />
                            </>
                        }
                    />
                    <StatCard
                        label="TRANSACTIONS"
                        value={transactions.length}
                        unit="Trans."
                        color="#2A5AF1"
                        icon={
                            <>
                                <path d="M6 2 3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4Z" />
                                <path d="M3 6h18" />
                                <path d="M16 10a4 4 0 0 1-8 0" />
                            </>
                        }
                    />
                </div>

                {/* ── Table Card ── */}
                <div style={styles.tableCard}>
                    <div style={{ marginBottom: '25px' }}>
                        <h3 style={{ fontSize: '18px', fontWeight: '700', color: '#0F172A', margin: 0 }}>
                            Détail des Transactions
                        </h3>
                    </div>

                    <table style={{ width: '100%', borderCollapse: 'separate', borderSpacing: '0 8px' }}>
                        <thead>
                            <tr style={{ textAlign: 'left' }}>
                                <th style={styles.th}>SERVICE / PRODUIT</th>
                                <th style={styles.th}>VENDEUR</th>
                                <th style={styles.th}>INFLUENCEUR</th>
                                <th style={styles.th}>ADMIN (PROFIT)</th>
                                <th style={styles.th}>DATE</th>
                            </tr>
                        </thead>
                        <tbody>
                            {loading ? (
                                <tr>
                                    <td colSpan="5" style={{ textAlign: 'center', padding: '30px', color: '#94A3B8', fontSize: '14px' }}>
                                        Chargement...
                                    </td>
                                </tr>
                            ) : transactions.map(item => (
                                <tr key={item.id} style={styles.tableRow}>
                                    <td style={styles.td}>
                                        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                                            <div style={{
                                                width: '32px', height: '32px', borderRadius: '8px',
                                                backgroundColor: `${primaryBlue}12`,
                                                display: 'flex', alignItems: 'center', justifyContent: 'center'
                                            }}>
                                                <svg width="14" height="14" viewBox="0 0 24 24" fill="none"
                                                    stroke={primaryBlue} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                                                    <path d="M6 2 3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4Z" />
                                                    <path d="M3 6h18" />
                                                    <path d="M16 10a4 4 0 0 1-8 0" />
                                                </svg>
                                            </div>
                                            <span style={{ fontWeight: '600', color: '#0F172A' }}>
                                                {item.product_name || item.service_name}
                                            </span>
                                        </div>
                                    </td>
                                    <td style={styles.td}>
                                        <span style={{ color: '#334155' }}>{parseFloat(item.vendor_share).toFixed(2)} MRU</span>
                                    </td>
                                    <td style={styles.td}>
                                        <span style={{ color: '#334155' }}>{parseFloat(item.influencer_share).toFixed(2)} MRU</span>
                                    </td>
                                    <td style={styles.td}>
                                        <span style={{
                                            padding: '4px 12px',
                                            borderRadius: '20px',
                                            fontSize: '12px',
                                            fontWeight: '700',
                                            backgroundColor: '#ECFDF5',
                                            color: '#10B981',
                                        }}>
                                            +{parseFloat(item.platform_share).toFixed(2)} MRU
                                        </span>
                                    </td>
                                    <td style={{ ...styles.td, color: '#94A3B8' }}>
                                        {new Date(item.created_at).toLocaleDateString('fr-FR')}
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>
            </main>
        </div>
    );
};

// ── Styles ────────────────────────────────────────────────────
const cardStyles = {
    card: {
        backgroundColor: '#fff',
        padding: '24px',
        borderRadius: '20px',
        border: '1px solid #E8EFFF',
        boxShadow: '0 4px 20px rgba(42, 90, 241, 0.03)'
    },
    cardLabel: { fontSize: '12px', color: '#64748B', fontWeight: '700', marginBottom: '8px', letterSpacing: '0.5px' },
    cardValue: { fontSize: '26px', color: '#0F172A', margin: '0', fontWeight: '800' },
    cardFooter: { fontSize: '11px', color: '#94A3B8', fontWeight: '500' },
};

const styles = {
    dateBadge: {
        backgroundColor: '#FFF',
        padding: '10px 16px',
        borderRadius: '12px',
        border: '1px solid #E2E8F0',
        fontSize: '13px',
        color: '#475569',
        fontWeight: '600'
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
    smallRefreshBtn: {},
    th: { padding: '12px 20px', color: '#94A3B8', fontSize: '11px', fontWeight: '800', letterSpacing: '1px' },
    td: { padding: '14px 20px', color: '#334155', fontSize: '14px' },
    tableRow: { backgroundColor: '#FBFDFF' },
};

export default Finance;
