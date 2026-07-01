import React, { useState, useEffect } from 'react';
import axios from 'axios';
import Sidebar from '../components/Sidebar';

const primaryBlue = '#2A5AF1';
const bgLight = '#F8FAFF';
const API_BASE = 'http://127.0.0.1:8000/api';

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

const Delivery = () => {
    const [deliveries, setDeliveries] = useState([]);
    const [user, setUser] = useState(null);
    const [loading, setLoading] = useState(true);
    const [filter, setFilter] = useState('all');
    const [selectedOrder, setSelectedOrder] = useState(null);
    const [newStatus, setNewStatus] = useState('');

    const fetchData = async () => {
        try {
            const token = localStorage.getItem('access_token');
            const headers = { Authorization: `Bearer ${token}` };

            const userRes = await axios.get(`${API_BASE}/users/me/`, { headers });
            setUser(userRes.data);

            const deliveriesRes = await axios.get(`${API_BASE}/orders/?driver=${userRes.data.id}`, { headers });
            setDeliveries(deliveriesRes.data);
            setLoading(false);
        } catch (err) {
            console.error('Erreur:', err);
            setLoading(false);
        }
    };

    useEffect(() => { fetchData(); }, []);

    const handleUpdateStatus = async (e) => {
        e.preventDefault();
        try {
            const token = localStorage.getItem('access_token');
            await axios.post(`${API_BASE}/orders/${selectedOrder.id}/update_status/`,
                { status: newStatus },
                { headers: { Authorization: `Bearer ${token}` } }
            );
            setSelectedOrder(null);
            setNewStatus('');
            fetchData();
            alert('Statut mis a jour avec succes.');
        } catch (err) {
            console.error('Erreur:', err);
            alert('Impossible de mettre a jour le statut.');
        }
    };

    const filteredDeliveries = filter === 'all' ? deliveries : deliveries.filter(d => d.status === filter);
    const completedDeliveries = deliveries.filter(d => d.status === 'delivered').length;
    const inProgressDeliveries = deliveries.filter(d => d.status === 'on_way' || d.status === 'ready').length;
    const pendingDeliveries = deliveries.filter(d => d.status === 'pending' || d.status === 'paid').length;

    const statusConfig = {
        pending:   { bg: '#FFF7ED', color: '#F97316', label: 'En attente' },
        paid:      { bg: '#ECFDF5', color: '#10B981', label: 'Paye' },
        ready:     { bg: '#EFF6FF', color: primaryBlue, label: 'Pret a recuperer' },
        on_way:    { bg: '#F5F3FF', color: '#8B5CF6', label: 'En livraison' },
        arrived:   { bg: '#FEF3C7', color: '#D97706', label: 'Arrive chez client' },
        delivered: { bg: '#ECFDF5', color: '#10B981', label: 'Livre' },
    };

    return (
        <div style={{ display: 'flex', backgroundColor: bgLight, minHeight: '100vh' }}>
            <Sidebar />
            <main style={{ marginLeft: '260px', flex: 1, padding: '40px' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '40px' }}>
                    <div>
                        <h2 style={{ fontSize: '28px', fontWeight: '800', color: '#0F172A', letterSpacing: '-0.5px', margin: 0 }}>
                            Tableau du livreur
                        </h2>
                        <p style={{ color: '#64748B', marginTop: '4px', fontSize: '14px', margin: '4px 0 0' }}>
                            Bienvenue {user?.first_name || user?.username || ''}. Gestion des livraisons et des commandes
                        </p>
                    </div>
                    <button
                        onClick={fetchData}
                        style={{
                            padding: '10px 20px', borderRadius: '8px', border: '1px solid #E8EFFF',
                            backgroundColor: '#fff', color: primaryBlue, fontWeight: '600', cursor: 'pointer'
                        }}
                    >
                        Actualiser
                    </button>
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))', gap: '24px', marginBottom: '40px' }}>
                    <StatCard
                        label="Total des commandes"
                        value={deliveries.length}
                        unit="commande"
                        color={primaryBlue}
                        icon={<><rect x="1" y="3" width="15" height="13" rx="2" /><path d="M16 8h4l3 5v4h-7V8z" /></>}
                    />
                    <StatCard
                        label="En livraison"
                        value={inProgressDeliveries}
                        unit="en cours"
                        color="#8B5CF6"
                        icon={<><polyline points="22 12 18 12 15 21 9 3 6 12 2 12" /></>}
                    />
                    <StatCard
                        label="Livrees"
                        value={completedDeliveries}
                        unit="terminees"
                        color="#10B981"
                        icon={<><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14" /><polyline points="22 4 12 14.01 9 11.01" /></>}
                    />
                    <StatCard
                        label="En attente"
                        value={pendingDeliveries}
                        unit="a traiter"
                        color="#F97316"
                        icon={<><circle cx="12" cy="12" r="10" /><polyline points="12 6 12 12 16 14" /></>}
                    />
                </div>

                {selectedOrder && (
                    <div style={{
                        backgroundColor: '#fff', padding: '30px', borderRadius: '20px',
                        border: '1px solid #E8EFFF', marginBottom: '30px', boxShadow: '0 4px 20px rgba(42,90,241,0.03)'
                    }}>
                        <h3 style={{ fontSize: '18px', fontWeight: '700', color: '#0F172A', margin: '0 0 20px 0' }}>
                            Mettre a jour la commande #{selectedOrder.id}
                        </h3>
                        <form onSubmit={handleUpdateStatus} style={{ display: 'flex', gap: '12px', alignItems: 'flex-end' }}>
                            <div style={{ flex: 1 }}>
                                <p style={{ fontSize: '12px', color: '#64748B', margin: '0 0 8px 0', fontWeight: '600' }}>
                                    Statut actuel : {statusConfig[selectedOrder.status]?.label}
                                </p>
                                <select
                                    value={newStatus}
                                    onChange={(e) => setNewStatus(e.target.value)}
                                    required
                                    style={{ width: '100%', padding: '12px 16px', borderRadius: '8px', border: '1px solid #E8EFFF', fontSize: '14px' }}
                                >
                                    <option value="">Choisir le nouveau statut</option>
                                    <option value="ready">Pret a recuperer</option>
                                    <option value="on_way">En livraison</option>
                                    <option value="arrived">Arrive chez client</option>
                                    <option value="delivered">Livre</option>
                                </select>
                            </div>
                            <button
                                type="submit"
                                style={{
                                    padding: '12px 24px', borderRadius: '8px', border: 'none',
                                    backgroundColor: primaryBlue, color: '#fff',
                                    fontWeight: '600', cursor: 'pointer', fontSize: '14px'
                                }}
                            >
                                Enregistrer
                            </button>
                            <button
                                type="button"
                                onClick={() => { setSelectedOrder(null); setNewStatus(''); }}
                                style={{
                                    padding: '12px 24px', borderRadius: '8px', border: '1px solid #E8EFFF',
                                    backgroundColor: '#fff', color: '#64748B',
                                    fontWeight: '600', cursor: 'pointer', fontSize: '14px'
                                }}
                            >
                                Annuler
                            </button>
                        </form>
                    </div>
                )}

                <div style={{ display: 'flex', gap: '8px', marginBottom: '30px', flexWrap: 'wrap' }}>
                    {['all', 'pending', 'paid', 'ready', 'on_way', 'arrived', 'delivered'].map(f => (
                        <button
                            key={f}
                            onClick={() => setFilter(f)}
                            style={{
                                padding: '10px 16px', borderRadius: '8px', border: 'none',
                                backgroundColor: filter === f ? primaryBlue : '#F1F5F9',
                                color: filter === f ? '#fff' : '#64748B',
                                fontWeight: '600', cursor: 'pointer', fontSize: '13px'
                            }}
                        >
                            {f === 'all' ? 'Tous' : statusConfig[f]?.label || f}
                        </button>
                    ))}
                </div>

                <div style={{
                    backgroundColor: '#fff', padding: '30px', borderRadius: '20px',
                    border: '1px solid #E8EFFF', boxShadow: '0 4px 20px rgba(42,90,241,0.03)'
                }}>
                    <h3 style={{ fontSize: '18px', fontWeight: '700', color: '#0F172A', margin: '0 0 25px 0' }}>
                        Commandes ({filteredDeliveries.length})
                    </h3>

                    {loading ? (
                        <div style={{ textAlign: 'center', padding: '40px', color: '#94A3B8' }}>
                            Chargement...
                        </div>
                    ) : filteredDeliveries.length === 0 ? (
                        <div style={{ textAlign: 'center', padding: '40px', color: '#94A3B8' }}>
                            Aucune commande
                        </div>
                    ) : (
                        <table style={{ width: '100%', borderCollapse: 'separate', borderSpacing: '0 8px' }}>
                            <thead>
                                <tr style={{ textAlign: 'left' }}>
                                    <th style={{ fontSize: '12px', fontWeight: '700', color: '#64748B', padding: '12px', textAlign: 'left', borderBottom: '2px solid #E8EFFF' }}>Commande</th>
                                    <th style={{ fontSize: '12px', fontWeight: '700', color: '#64748B', padding: '12px', textAlign: 'left', borderBottom: '2px solid #E8EFFF' }}>Montant</th>
                                    <th style={{ fontSize: '12px', fontWeight: '700', color: '#64748B', padding: '12px', textAlign: 'left', borderBottom: '2px solid #E8EFFF' }}>Client</th>
                                    <th style={{ fontSize: '12px', fontWeight: '700', color: '#64748B', padding: '12px', textAlign: 'left', borderBottom: '2px solid #E8EFFF' }}>Statut</th>
                                    <th style={{ fontSize: '12px', fontWeight: '700', color: '#64748B', padding: '12px', textAlign: 'left', borderBottom: '2px solid #E8EFFF' }}>Date</th>
                                    <th style={{ fontSize: '12px', fontWeight: '700', color: '#64748B', padding: '12px', textAlign: 'left', borderBottom: '2px solid #E8EFFF' }}>Action</th>
                                </tr>
                            </thead>
                            <tbody>
                                {filteredDeliveries.map(order => {
                                    const sc = statusConfig[order.status] || { bg: '#F1F5F9', color: '#64748B', label: order.status };
                                    return (
                                        <tr key={order.id} style={{
                                            backgroundColor: '#f8faff', borderRadius: '12px', border: '1px solid #E8EFFF'
                                        }}>
                                            <td style={{ padding: '16px 12px', textAlign: 'left', fontWeight: '700', color: primaryBlue }}>
                                                #{order.id}
                                            </td>
                                            <td style={{ padding: '16px 12px', textAlign: 'left', fontWeight: '600', color: '#0F172A' }}>
                                                {parseFloat(order.total_amount).toFixed(2)} MRU
                                            </td>
                                            <td style={{ padding: '16px 12px', textAlign: 'left', color: '#0F172A' }}>
                                                <strong style={{ color: '#0F172A', fontSize: '14px' }}>
                                                    {order.customer_name || 'Client'}
                                                </strong>
                                            </td>
                                            <td style={{ padding: '16px 12px', textAlign: 'left' }}>
                                                <span style={{
                                                    padding: '4px 12px', borderRadius: '20px',
                                                    fontSize: '11px', fontWeight: '700',
                                                    backgroundColor: sc.bg, color: sc.color
                                                }}>
                                                    {sc.label}
                                                </span>
                                            </td>
                                            <td style={{ padding: '16px 12px', textAlign: 'left', color: '#64748B', fontSize: '13px' }}>
                                                {new Date(order.created_at).toLocaleDateString('fr-FR')}
                                            </td>
                                            <td style={{ padding: '16px 12px', textAlign: 'left' }}>
                                                <button
                                                    onClick={() => {
                                                        setSelectedOrder(order);
                                                        setNewStatus('');
                                                    }}
                                                    style={{
                                                        padding: '6px 14px', borderRadius: '6px', border: 'none',
                                                        backgroundColor: `${primaryBlue}15`, color: primaryBlue,
                                                        fontWeight: '600', fontSize: '12px', cursor: 'pointer'
                                                    }}
                                                >
                                                    Modifier
                                                </button>
                                            </td>
                                        </tr>
                                    );
                                })}
                            </tbody>
                        </table>
                    )}
                </div>

                <div style={{ marginTop: '30px', display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '24px' }}>
                    <div style={{
                        backgroundColor: '#fff', padding: '30px', borderRadius: '20px',
                        border: '1px solid #E8EFFF', boxShadow: '0 4px 20px rgba(42,90,241,0.03)'
                    }}>
                        <h3 style={{ fontSize: '16px', fontWeight: '700', color: '#0F172A', margin: '0 0 20px 0' }}>
                            Statistiques de performance
                        </h3>
                        <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', paddingBottom: '12px', borderBottom: '1px solid #E8EFFF' }}>
                                <span style={{ color: '#64748B', fontWeight: '600' }}>Taux de finalisation</span>
                                <span style={{ color: primaryBlue, fontWeight: '700', fontSize: '16px' }}>
                                    {deliveries.length > 0 ? Math.round((completedDeliveries / deliveries.length) * 100) : 0}%
                                </span>
                            </div>
                            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', paddingBottom: '12px', borderBottom: '1px solid #E8EFFF' }}>
                                <span style={{ color: '#64748B', fontWeight: '600' }}>Commandes livrees</span>
                                <span style={{ color: '#10B981', fontWeight: '700', fontSize: '16px' }}>
                                    {completedDeliveries}
                                </span>
                            </div>
                            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                                <span style={{ color: '#64748B', fontWeight: '600' }}>En attente</span>
                                <span style={{ color: '#F97316', fontWeight: '700', fontSize: '16px' }}>
                                    {pendingDeliveries}
                                </span>
                            </div>
                        </div>
                    </div>

                    <div style={{
                        backgroundColor: primaryBlue, color: '#fff', padding: '30px', borderRadius: '20px',
                        boxShadow: '0 8px 30px rgba(42,90,241,0.2)'
                    }}>
                        <h3 style={{ fontSize: '16px', fontWeight: '700', margin: '0 0 20px 0' }}>
                            Informations du profil
                        </h3>
                        <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                            <div>
                                <p style={{ fontSize: '12px', opacity: 0.9, margin: '0 0 4px 0' }}>Nom</p>
                                <p style={{ fontSize: '14px', fontWeight: '600', margin: 0 }}>
                                    {user?.first_name} {user?.last_name}
                                </p>
                            </div>
                            <div>
                                <p style={{ fontSize: '12px', opacity: 0.9, margin: '0 0 4px 0' }}>Telephone</p>
                                <p style={{ fontSize: '14px', fontWeight: '600', margin: 0 }}>
                                    {user?.phone || 'Non renseigne'}
                                </p>
                            </div>
                            <div>
                                <p style={{ fontSize: '12px', opacity: 0.9, margin: '0 0 4px 0' }}>Statut</p>
                                <p style={{ fontSize: '14px', fontWeight: '600', margin: 0 }}>
                                    {user?.is_approved ? 'Actif' : 'En verification'}
                                </p>
                            </div>
                        </div>
                    </div>
                </div>
            </main>
        </div>
    );
};

export default Delivery;
