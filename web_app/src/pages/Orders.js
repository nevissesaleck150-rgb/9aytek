import React, { useState, useEffect } from 'react';
import axios from 'axios';
import Sidebar from '../components/Sidebar';
import AppHeader from '../components/AppHeader';

const primaryBlue = '#2A5AF1';
const bgLight = '#F8FAFF';

const Orders = () => {
    const [orders, setOrders] = useState([]);
    const [loading, setLoading] = useState(true);

    const fetchOrders = async () => {
        try {
            const token = localStorage.getItem('access_token');
            const res = await axios.get('http://127.0.0.1:8000/api/orders/', {
                headers: { Authorization: `Bearer ${token}` }
            });
            setOrders(res.data);
            setLoading(false);
        } catch (err) {
            console.error('Erreur', err);
            setLoading(false);
        }
    };

    useEffect(() => { fetchOrders(); }, []);

    const updateOrderStatus = async (orderId, newStatus) => {
        try {
            const token = localStorage.getItem('access_token');
            await axios.post(`http://127.0.0.1:8000/api/orders/${orderId}/update_status/`,
                { status: newStatus },
                { headers: { Authorization: `Bearer ${token}` } }
            );
            fetchOrders();
            alert('Statut mis à jour avec succès !');
        } catch (err) {
            const errorMsg = err.response?.data?.error || 'Erreur lors de la mise à jour';
            alert(errorMsg);
        }
    };

    const handleBankilyConfirm = async (orderId) => {
        try {
            const token = localStorage.getItem('access_token');
            await axios.post(`http://127.0.0.1:8000/api/orders/${orderId}/confirm_bankily/`,
                {},
                { headers: { Authorization: `Bearer ${token}` } }
            );
            fetchOrders();
            alert('Paiement Bankily Confirmé');
        } catch {
            alert('Erreur Bankily');
        }
    };

    const totalOrders = orders.length;
    const completedOrders = orders.filter(o => o.status === 'delivered').length;

    const statusConfig = {
        pending:   { bg: '#FFF7ED', color: '#F97316', label: 'EN ATTENTE' },
        paid:      { bg: '#ECFDF5', color: '#10B981', label: 'PAYÉ' },
        ready:     { bg: '#EFF6FF', color: primaryBlue, label: 'PRÊT' },
        on_way:    { bg: '#F5F3FF', color: '#8B5CF6', label: 'EN LIVRAISON' },
        arrived:   { bg: '#FEF3C7', color: '#D97706', label: 'ARRIVÉ' },
        delivered: { bg: '#ECFDF5', color: '#10B981', label: 'LIVRÉ' },
    };

    return (
        <div style={{ display: 'flex', backgroundColor: bgLight, minHeight: '100vh' }}>
            <Sidebar />
            <main style={{ marginLeft: '260px', flex: 1, padding: '40px' }}>
                <AppHeader
                    title="Commandes"
                    subtitle="Suivi complet des statuts du paiement jusqu'à la livraison"
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

                {/* ── StatCards ── */}
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, minmax(0, 1fr))', gap: '24px', marginBottom: '40px' }}>
                    <StatCard
                        label="TOTAL COMMANDES"
                        value={totalOrders}
                        unit="Cmd."
                        color={primaryBlue}
                        icon={
                            <>
                                <path d="M6 2 3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4Z" />
                                <path d="M3 6h18" />
                                <path d="M16 10a4 4 0 0 1-8 0" />
                            </>
                        }
                    />
                    <StatCard
                        label="COMMANDES TERMINÉES"
                        value={completedOrders}
                        unit="Livr."
                        color="#10B981"
                        icon={
                            <>
                                <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14" />
                                <polyline points="22 4 12 14.01 9 11.01" />
                            </>
                        }
                    />
                </div>

                {/* ── Table Card ── */}
                <div style={styles.tableCard}>
                    <div style={{ marginBottom: '25px' }}>
                        <h3 style={{ fontSize: '18px', fontWeight: '700', color: '#0F172A', margin: 0 }}>
                            Détail des Commandes
                        </h3>
                    </div>

                    <table style={{ width: '100%', borderCollapse: 'separate', borderSpacing: '0 8px' }}>
                        <thead>
                            <tr style={{ textAlign: 'left' }}>
                                <th style={styles.th}>RÉFÉRENCE</th>
                                <th style={styles.th}>CLIENT</th>
                                <th style={styles.th}>MONTANT</th>
                                <th style={styles.th}>STATUT</th>
                                <th style={styles.th}>ACTIONS DE SÉCURITÉ</th>
                            </tr>
                        </thead>
                        <tbody>
                            {loading ? (
                                <tr>
                                    <td colSpan="5" style={{ textAlign: 'center', padding: '30px', color: '#94A3B8', fontSize: '14px' }}>
                                        Chargement...
                                    </td>
                                </tr>
                            ) : orders.map(order => {
                                const sc = statusConfig[order.status] || { bg: '#F1F5F9', color: '#64748B', label: order.status.toUpperCase() };
                                return (
                                    <tr key={order.id} style={styles.tableRow}>
                                        {/* ID */}
                                        <td style={styles.td}>
                                            <span style={{ fontWeight: '700', color: primaryBlue }}>#{order.id}</span>
                                        </td>

                                        {/* Client */}
                                        <td style={styles.td}>
                                            <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                                                <div style={{
                                                    width: '32px', height: '32px', borderRadius: '50%',
                                                    backgroundColor: `${primaryBlue}12`,
                                                    display: 'flex', alignItems: 'center', justifyContent: 'center'
                                                }}>
                                                    <svg width="15" height="15" viewBox="0 0 24 24" fill="none"
                                                        stroke={primaryBlue} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                                                        <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" />
                                                        <circle cx="12" cy="7" r="4" />
                                                    </svg>
                                                </div>
                                                <strong style={{ color: '#0F172A', fontSize: '14px' }}>
                                                    {order.customer_name || 'Client'}
                                                </strong>
                                            </div>
                                        </td>

                                        {/* Montant */}
                                        <td style={styles.td}>
                                            <span style={{ fontWeight: '700', color: '#0F172A' }}>
                                                {parseFloat(order.total_amount).toFixed(2)} MRU
                                            </span>
                                        </td>

                                        {/* Statut */}
                                        <td style={styles.td}>
                                            <span style={{
                                                padding: '4px 12px', borderRadius: '20px',
                                                fontSize: '11px', fontWeight: '700',
                                                backgroundColor: sc.bg, color: sc.color
                                            }}>
                                                {sc.label}
                                            </span>
                                        </td>

                                        {/* Actions */}
                                        <td style={styles.td}>
                                            <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
                                                {order.status === 'pending' && (
                                                    <button
                                                        onClick={() => handleBankilyConfirm(order.id)}
                                                        style={styles.bankilyBtn}
                                                        onMouseEnter={e => e.currentTarget.style.backgroundColor = '#15803D'}
                                                        onMouseLeave={e => e.currentTarget.style.backgroundColor = '#16A34A'}
                                                    >
                                                        <svg width="13" height="13" viewBox="0 0 24 24" fill="none"
                                                            stroke="#fff" strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round"
                                                            style={{ marginRight: '5px' }}>
                                                            <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14" />
                                                            <polyline points="22 4 12 14.01 9 11.01" />
                                                        </svg>
                                                        Bankily
                                                    </button>
                                                )}
                                                <select
                                                    onChange={e => updateOrderStatus(order.id, e.target.value)}
                                                    value={order.status}
                                                    style={styles.select}
                                                >
                                                    <option value="pending">En attente</option>
                                                    <option value="paid">Payé (Validé)</option>
                                                    <option value="ready">Prêt (Stock)</option>
                                                    <option value="on_way">En Livraison</option>
                                                    <option value="arrived">Arrivé chez le client</option>
                                                    <option value="delivered">Livré</option>
                                                </select>
                                            </div>
                                        </td>
                                    </tr>
                                );
                            })}
                        </tbody>
                    </table>
                </div>
            </main>
        </div>
    );
};

// ── StatCard ─────────────────────────────────────────────────
const StatCard = ({ label, value, unit, icon, color }) => (
    <div style={{
        backgroundColor: '#fff', padding: '24px', borderRadius: '20px',
        border: '1px solid #E8EFFF', boxShadow: '0 4px 20px rgba(42,90,241,0.03)'
    }}>
        <div style={{ display: 'flex', justifyContent: 'space-between' }}>
            <div>
                <p style={{ fontSize: '12px', color: '#64748B', fontWeight: '700', marginBottom: '8px', letterSpacing: '0.5px' }}>
                    {label}
                </p>
                <h2 style={{ fontSize: '26px', color: '#0F172A', margin: 0, fontWeight: '800' }}>
                    {value} <span style={{ fontSize: '14px', color: '#94A3B8' }}>{unit}</span>
                </h2>
            </div>
            <div style={{
                padding: '10px', borderRadius: '12px', backgroundColor: `${color}15`,
                display: 'flex', alignItems: 'center', justifyContent: 'center'
            }}>
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none"
                    stroke={color} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                    {icon}
                </svg>
            </div>
        </div>
    </div>
);

// ── Styles ────────────────────────────────────────────────────
const styles = {
    dateBadge: {
        backgroundColor: '#FFF', padding: '10px 16px', borderRadius: '12px',
        border: '1px solid #E2E8F0', fontSize: '13px', color: '#475569', fontWeight: '600'
    },
    refreshBtn: {},
    smallRefreshBtn: {},
    tableCard: {
        backgroundColor: '#fff', padding: '30px', borderRadius: '24px',
        border: '1px solid #E8EFFF', boxShadow: '0 4px 20px rgba(42,90,241,0.03)'
    },
    printBtn: {
        display: 'flex', alignItems: 'center', backgroundColor: '#2A5AF1',
        border: 'none', padding: '10px 20px', borderRadius: '12px',
        color: '#fff', cursor: 'pointer', fontWeight: '700', fontSize: '13px', transition: 'background-color 0.2s'
    },
    th: { padding: '12px 20px', color: '#94A3B8', fontSize: '11px', fontWeight: '800', letterSpacing: '1px' },
    td: { padding: '14px 20px', color: '#334155', fontSize: '14px' },
    tableRow: { backgroundColor: '#FBFDFF' },
    bankilyBtn: {
        display: 'inline-flex', alignItems: 'center',
        backgroundColor: '#16A34A', color: '#fff', border: 'none',
        padding: '7px 14px', borderRadius: '10px', cursor: 'pointer',
        fontSize: '12px', fontWeight: '700', transition: 'background-color 0.2s'
    },
    select: {
        padding: '7px 10px', borderRadius: '10px',
        border: '1px solid #DBEAFE', fontSize: '12px',
        backgroundColor: '#F8FAFF', cursor: 'pointer',
        color: '#334155', fontWeight: '600', outline: 'none'
    }
};

export default Orders;
