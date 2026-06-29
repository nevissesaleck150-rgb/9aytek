import React, { useState, useEffect } from 'react';
import Sidebar from '../components/Sidebar';
import AppHeader from '../components/AppHeader';
import axios from 'axios';

const primaryBlue = '#2A5AF1';
const bgLight = '#F8FAFF';
const API_BASE = 'http://127.0.0.1:8000/api';
const SERVER_BASE = 'http://127.0.0.1:8000';

// Helper to get full image URL
const getImageUrl = (path) => {
    if (!path) return null;
    if (path.startsWith('http')) return path;
    return `${SERVER_BASE}${path.startsWith('/') ? '' : '/'}${path}`;
};

const TopUp = () => {
    const [requests, setRequests] = useState([]);
    const [topupApps, setTopupApps] = useState([]);
    const [showCreate, setShowCreate] = useState(false);
    const [selectedApp, setSelectedApp] = useState(null);
    const [editingApp, setEditingApp] = useState(null);
    const [newApp, setNewApp] = useState({ title: '', price: '', description: '', required_field_name: 'Recharge Standard', type: 'topup', recharge_type: 'standard' });
    const [imageFile, setImageFile] = useState(null);
    const [imagePreview, setImagePreview] = useState(null);

    useEffect(() => { fetchRequests(); fetchApps(); }, []);

    const fetchRequests = async () => {
        try {
            const token = localStorage.getItem('access_token');
            const res = await axios.get(`${API_BASE}/services/topup_requests/`, {
                headers: { Authorization: `Bearer ${token}` }
            });
            setRequests(res.data);
        } catch (err) {
            console.error('Erreur Top-up:', err);
        }
    };

    const fetchApps = async () => {
        try {
            const token = localStorage.getItem('access_token');
            const res = await axios.get(`${API_BASE}/services/`, {
                headers: { Authorization: `Bearer ${token}` }
            });
            setTopupApps(res.data.filter(item => item.type === 'topup'));
            setSelectedApp(null);
        } catch (err) {
            console.error('Erreur Topup Apps:', err);
        }
    };

    const handleConfirm = async (orderId) => {
        try {
            const token = localStorage.getItem('access_token');
            await axios.post(`${API_BASE}/orders/${orderId}/complete_topup/`,
                {},
                { headers: { Authorization: `Bearer ${token}` } }
            );
            setRequests(requests.map(req => req.order_id === orderId ? { ...req, order_status: 'delivered' } : req));
            if (selectedApp) {
                setSelectedApp({
                    ...selectedApp,
                    appRequests: selectedApp.appRequests.map(req => req.order_id === orderId ? { ...req, order_status: 'delivered' } : req)
                });
            }
            alert('Recharge confirmée avec succès !');
        } catch {
            alert('Erreur lors de la confirmation de la recharge');
        }
    };

    const handleCreateApp = async (e) => {
        e.preventDefault();
        try {
            const token = localStorage.getItem('access_token');
            if (imageFile) {
                const formData = new FormData();
                formData.append('title', newApp.title);
                formData.append('price', parseFloat(newApp.price) || 0);
                formData.append('description', newApp.description);
                formData.append('type', 'topup');
                formData.append('required_field_name', newApp.recharge_type === 'premium' ? 'Recharge Premium' : 'Recharge Standard');
                formData.append('image', imageFile);
                await axios.post(`${API_BASE}/services/`, formData, {
                    headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'multipart/form-data' }
                });
            } else {
                const payload = {
                    title: newApp.title,
                    price: parseFloat(newApp.price) || 0,
                    description: newApp.description,
                    type: 'topup',
                    required_field_name: newApp.recharge_type === 'premium' ? 'Recharge Premium' : 'Recharge Standard',
                };
                await axios.post(`${API_BASE}/services/`, payload, {
                    headers: { Authorization: `Bearer ${token}` }
                });
            }
            setShowCreate(false);
            setNewApp({ title: '', price: '', description: '', required_field_name: 'Recharge Standard', type: 'topup', recharge_type: 'standard' });
            setImageFile(null);
            setImagePreview(null);
            fetchApps();
            alert('Application de recharge ajoutée avec succès.');
        } catch (err) {
            console.error('Erreur création app topup', err);
            const errMsg = err.response?.data ? JSON.stringify(err.response.data) : '';
            alert(`Impossible d'ajouter l'application. ${errMsg || 'Vérifiez les champs.'}`);
        }
    };

    const handleUpdateApp = async (e) => {
        e.preventDefault();
        try {
            const token = localStorage.getItem('access_token');
            if (imageFile) {
                const formData = new FormData();
                formData.append('title', newApp.title);
                formData.append('price', parseFloat(newApp.price) || 0);
                formData.append('description', newApp.description);
                formData.append('type', 'topup');
                formData.append('required_field_name', newApp.recharge_type === 'premium' ? 'Recharge Premium' : 'Recharge Standard');
                formData.append('image', imageFile);
                await axios.patch(`${API_BASE}/services/${editingApp.id}/`, formData, {
                    headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'multipart/form-data' }
                });
            } else {
                const payload = {
                    title: newApp.title,
                    price: parseFloat(newApp.price) || 0,
                    description: newApp.description,
                    type: 'topup',
                    required_field_name: newApp.recharge_type === 'premium' ? 'Recharge Premium' : 'Recharge Standard',
                };
                await axios.patch(`${API_BASE}/services/${editingApp.id}/`, payload, {
                    headers: { Authorization: `Bearer ${token}` }
                });
            }
            setEditingApp(null);
            setNewApp({ title: '', price: '', description: '', required_field_name: 'Recharge Standard', type: 'topup', recharge_type: 'standard' });
            setImageFile(null);
            setImagePreview(null);
            fetchApps();
            alert('Application modifiée avec succès.');
        } catch (err) {
            console.error('Erreur modification app topup', err);
            alert('Impossible de modifier l\'application.');
        }
    };

    const handleDeleteApp = async (app) => {
        if (!window.confirm(`Supprimer l'application « ${app.title} » ?`)) return;
        try {
            const token = localStorage.getItem('access_token');
            await axios.delete(`${API_BASE}/services/${app.id}/`, {
                headers: { Authorization: `Bearer ${token}` }
            });
            fetchApps();
            alert('Application supprimée.');
        } catch (err) {
            console.error('Erreur suppression app topup', err);
            alert('Impossible de supprimer l\'application.');
        }
    };

    const openEditApp = (app) => {
        setEditingApp(app);
        setNewApp({
            title: app.title || '',
            price: String(app.price || ''),
            description: app.description || '',
            required_field_name: app.required_field_name || 'Recharge Standard',
            type: 'topup',
            recharge_type: (app.required_field_name || '').includes('Premium') ? 'premium' : 'standard',
        });
        setImageFile(null);
        setImagePreview(getImageUrl(app.image) || null);
    };

    const handleImageChange = (e) => {
        const file = e.target.files[0];
        if (file) {
            setImageFile(file);
            setImagePreview(URL.createObjectURL(file));
        }
    };

    const totalRecharged = new Set(requests.map(req => req.customer_name || req.email || req.id)).size;

    return (
        <div style={{ display: 'flex', backgroundColor: bgLight, minHeight: '100vh' }}>
            <Sidebar />
            <main style={{ marginLeft: '260px', flex: 1, padding: '40px' }}>

                <AppHeader
                    title="Recharge Apps"
                    subtitle="Gérez les applications de recharge et les demandes clients"
                    actions={
                        <button
                            onClick={() => setShowCreate(!showCreate)}
                            style={showCreate ? styles.cancelBtn : styles.addBtn}
                        >
                            {showCreate ? (
                                <>
                                    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#fff"
                                        strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"
                                        style={{ marginRight: '7px' }}>
                                        <line x1="18" y1="6" x2="6" y2="18" />
                                        <line x1="6" y1="6" x2="18" y2="18" />
                                    </svg>
                                    Annuler
                                </>
                            ) : (
                                <>
                                    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#fff"
                                        strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"
                                        style={{ marginRight: '7px' }}>
                                        <line x1="12" y1="5" x2="12" y2="19" />
                                        <line x1="5" y1="12" x2="19" y2="12" />
                                    </svg>
                                    Ajouter une application
                                </>
                            )}
                        </button>
                    }
                />

                {/* ── StatCards ── */}
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '24px', marginBottom: '40px' }}>
                    <StatCard
                        label="APPLICATIONS DISPONIBLES"
                        value={topupApps.length}
                        unit="Apps"
                        color={primaryBlue}
                        icon={
                            <>
                                <path d="M5 8h14v10H5z" />
                                <path d="M5 8l7-5 7 5" />
                            </>
                        }
                    />
                    <StatCard
                        label="CLIENTS RECHARGÉS"
                        value={totalRecharged}
                        unit="Pers."
                        color="#10B981"
                        icon={
                            <>
                                <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" />
                                <circle cx="12" cy="7" r="4" />
                            </>
                        }
                    />
                </div>

                {showCreate && (
                    <div style={{ marginBottom: '30px', backgroundColor: '#fff', padding: '28px', borderRadius: '22px', border: '1px solid #E8EFFF' }}>
                        <h3 style={{ margin: 0, fontSize: '18px', fontWeight: '700', color: '#0F172A' }}>Nouvelle application de recharge</h3>
                        <form onSubmit={handleCreateApp} style={{ display: 'grid', gap: '16px', marginTop: '20px' }}>
                            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
                                <input
                                    value={newApp.title}
                                    onChange={e => setNewApp({ ...newApp, title: e.target.value })}
                                    placeholder="Titre de l'application"
                                    style={styles.input}
                                    required
                                />
                                <input
                                    value={newApp.price}
                                    onChange={e => setNewApp({ ...newApp, price: e.target.value })}
                                    placeholder="Prix"
                                    style={styles.input}
                                    required
                                />
                            </div>
                            <textarea
                                value={newApp.description}
                                onChange={e => setNewApp({ ...newApp, description: e.target.value })}
                                placeholder="Description"
                                style={{ ...styles.input, minHeight: '90px' }}
                                required
                            />
                            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px', alignItems: 'flex-end' }}>
                                <select
                                    value={newApp.recharge_type}
                                    onChange={e => setNewApp({ ...newApp, recharge_type: e.target.value })}
                                    style={styles.input}
                                >
                                    <option value="standard">Recharge normale</option>
                                    <option value="premium">Recharge premium</option>
                                </select>
                                <button type="submit" style={styles.createBtn}>Créer</button>
                            </div>
                            {/* Image upload */}
                            <div>
                                <label style={{ display: 'block', fontSize: '13px', color: '#475569', fontWeight: '600', marginBottom: '8px' }}>
                                    Image de l'application
                                </label>
                                <div style={{
                                    border: '2px dashed #DBEAFE', borderRadius: '12px', padding: '16px',
                                    textAlign: 'center', cursor: 'pointer', backgroundColor: '#FAFCFF',
                                }}
                                    onClick={() => document.getElementById('topup-image-input').click()}
                                >
                                    {imagePreview ? (
                                        <img src={imagePreview} alt="Aperçu" style={{ maxWidth: '100%', maxHeight: '100px', borderRadius: '8px', objectFit: 'cover' }} />
                                    ) : (
                                        <p style={{ fontSize: '12px', color: '#94A3B8', margin: 0 }}>Cliquez pour ajouter une image</p>
                                    )}
                                    <input id="topup-image-input" type="file" accept="image/*" style={{ display: 'none' }} onChange={handleImageChange} />
                                </div>
                            </div>
                        </form>
                    </div>
                )}

                <div style={{ marginBottom: '30px', display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(260px, 1fr))', gap: '20px' }}>
                    {topupApps.map(app => (
                        <div key={app.id} style={{ backgroundColor: '#fff', padding: '20px', borderRadius: '20px', border: '1px solid #E8EFFF', overflow: 'hidden' }}>
                            {/* App image */}
                            <div style={{
                                height: '140px', borderRadius: '14px', overflow: 'hidden', marginBottom: '14px',
                                backgroundColor: '#F8FAFC', display: 'flex', justifyContent: 'center', alignItems: 'center',
                                padding: '12px',
                            }}>
                                {app.image ? (
                                    <img src={getImageUrl(app.image)} alt={app.title} style={{
                                        maxWidth: '100%', maxHeight: '100%', objectFit: 'contain',
                                        borderRadius: '8px',
                                    }} />
                                ) : (
                                    <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="#94A3B8" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
                                        <rect x="5" y="2" width="14" height="20" rx="2" ry="2" />
                                        <line x1="12" y1="18" x2="12.01" y2="18" />
                                    </svg>
                                )}
                            </div>
                            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '10px' }}>
                                <h4 style={{ margin: 0, color: '#0F172A', fontSize: '16px', fontWeight: '700' }}>{app.title}</h4>
                                <span style={{ color: '#64748B', fontSize: '13px' }}>{app.price} MRU</span>
                            </div>
                            <p style={{ margin: 0, color: '#475569', fontSize: '13px', minHeight: '40px' }}>{app.description}</p>
                            <div style={{ marginTop: '14px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                                <span style={{ fontSize: '12px', color: '#94A3B8' }}>{app.required_field_name || 'Recharge standard'}</span>
                                <button style={styles.detailPill} onClick={() => {
                                    const appRequests = requests.filter(req => req.item_name === app.title);
                                    setSelectedApp({ ...app, appRequests });
                                }}>
                                    Voir les demandes
                                </button>
                            </div>
                            {/* Edit / Delete */}
                            <div style={{ marginTop: '12px', display: 'flex', gap: '8px', justifyContent: 'flex-end' }}>
                                <button onClick={() => openEditApp(app)} style={styles.editBtn}>Modifier</button>
                                <button onClick={() => handleDeleteApp(app)} style={styles.deleteBtn}>Supprimer</button>
                            </div>
                        </div>
                    ))}
                </div>

                {/* ── App Requests Modal ── */}
                {selectedApp && (
                    <div style={styles.modalOverlay} onClick={() => setSelectedApp(null)}>
                        <div style={styles.modalContent} onClick={(e) => e.stopPropagation()}>
                            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px' }}>
                                <div>
                                    <h2 style={{ margin: 0, fontSize: '18px', fontWeight: '800', color: '#0F172A' }}>{selectedApp.title}</h2>
                                    <p style={{ margin: '8px 0 0', color: '#64748B', fontSize: '13px' }}>
                                        Demandes de recharge associées à cette application.
                                    </p>
                                </div>
                                <button onClick={() => setSelectedApp(null)} style={styles.closeBtn}>
                                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none"
                                        stroke="#64748B" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
                                        <line x1="18" y1="6" x2="6" y2="18" />
                                        <line x1="6" y1="6" x2="18" y2="18" />
                                    </svg>
                                </button>
                            </div>
                            {selectedApp.appRequests.length === 0 ? (
                                <p style={{ color: '#64748B', fontSize: '14px' }}>Aucune demande de recharge pour cette application.</p>
                            ) : (
                                <div style={{ display: 'grid', gap: '16px' }}>
                                    {selectedApp.appRequests.map(req => (
                                        <div key={req.id} style={{ padding: '18px', backgroundColor: req.order_status === 'delivered' ? '#F0FDF4' : '#F8FAFF', borderRadius: '18px', border: req.order_status === 'delivered' ? '1px solid #BBF7D0' : 'none' }}>
                                            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: '16px' }}>
                                                <div>
                                                    <strong style={{ color: '#0F172A' }}>{req.item_name}</strong>
                                                    {req.item_description && (
                                                        <p style={{ margin: '6px 0 0', color: '#475569', fontSize: '13px' }}>
                                                            {req.item_description}
                                                        </p>
                                                    )}
                                                    <p style={{ margin: '4px 0 0', color: '#64748B', fontSize: '13px' }}>
                                                        Client: {req.customer_name || 'Inconnu'} · Commande #{req.order_id}
                                                    </p>
                                                    <p style={{ margin: '2px 0 0', color: '#94A3B8', fontSize: '12px' }}>
                                                        {req.total_amount} MRU · {req.created_at ? new Date(req.created_at).toLocaleDateString('fr-FR') : ''}
                                                    </p>
                                                    <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap', marginTop: '10px' }}>
                                                        {req.topup_recharge_type && (
                                                            <span style={styles.metaPill}>Type: {req.topup_recharge_type}</span>
                                                        )}
                                                        {req.topup_account_id && (
                                                            <span style={styles.metaPill}>ID: {req.topup_account_id}</span>
                                                        )}
                                                        {req.topup_payer && (
                                                            <span style={styles.metaPill}>Payer: {req.topup_payer}</span>
                                                        )}
                                                    </div>
                                                </div>
                                                {req.order_status === 'delivered' ? (
                                                    <span style={{ display: 'inline-flex', alignItems: 'center', backgroundColor: '#16A34A', color: '#fff', padding: '8px 18px', borderRadius: '12px', fontSize: '14px', fontWeight: '800' }}>
                                                        ✓ Terminé
                                                    </span>
                                                ) : (
                                                    <button style={styles.confirmBtn} onClick={() => handleConfirm(req.order_id)}>
                                                        Terminé
                                                    </button>
                                                )}
                                            </div>
                                        </div>
                                    ))}
                                </div>
                            )}
                        </div>
                    </div>
                )}

                {/* ── Edit App Modal ── */}
                {editingApp && (
                    <div style={styles.modalOverlay} onClick={() => { setEditingApp(null); setImageFile(null); setImagePreview(null); }}>
                        <div style={{ ...styles.modalContent, maxWidth: '480px' }} onClick={(e) => e.stopPropagation()}>
                            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px' }}>
                                <h2 style={{ margin: 0, fontSize: '18px', fontWeight: '800', color: '#0F172A' }}>Modifier l'application</h2>
                                <button onClick={() => { setEditingApp(null); setImageFile(null); setImagePreview(null); }} style={styles.closeBtn}>
                                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#64748B" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
                                        <line x1="18" y1="6" x2="6" y2="18" /><line x1="6" y1="6" x2="18" y2="18" />
                                    </svg>
                                </button>
                            </div>
                            <form onSubmit={handleUpdateApp} style={{ display: 'grid', gap: '14px' }}>
                                <input value={newApp.title} onChange={e => setNewApp({ ...newApp, title: e.target.value })} placeholder="Titre" style={styles.input} required />
                                <input value={newApp.price} onChange={e => setNewApp({ ...newApp, price: e.target.value })} placeholder="Prix" type="number" style={styles.input} required />
                                <textarea value={newApp.description} onChange={e => setNewApp({ ...newApp, description: e.target.value })} placeholder="Description" style={{ ...styles.input, minHeight: '70px' }} required />
                                <select value={newApp.recharge_type} onChange={e => setNewApp({ ...newApp, recharge_type: e.target.value })} style={styles.input}>
                                    <option value="standard">Recharge normale</option>
                                    <option value="premium">Recharge premium</option>
                                </select>
                                {/* Image upload */}
                                <div style={{ border: '2px dashed #DBEAFE', borderRadius: '12px', padding: '16px', textAlign: 'center', cursor: 'pointer', backgroundColor: '#FAFCFF' }}
                                    onClick={() => document.getElementById('topup-edit-image').click()}>
                                    {imagePreview ? (
                                        <img src={imagePreview} alt="Aperçu" style={{ maxWidth: '100%', maxHeight: '100px', borderRadius: '8px', objectFit: 'cover' }} />
                                    ) : (
                                        <p style={{ fontSize: '12px', color: '#94A3B8', margin: 0 }}>Changer l'image</p>
                                    )}
                                    <input id="topup-edit-image" type="file" accept="image/*" style={{ display: 'none' }} onChange={handleImageChange} />
                                </div>
                                <div style={{ display: 'flex', gap: '10px' }}>
                                    <button type="submit" style={{ ...styles.createBtn, flex: 1 }}>Enregistrer</button>
                                    <button type="button" onClick={() => { setEditingApp(null); setImageFile(null); setImagePreview(null); }} style={{ ...styles.cancelBtn, flex: 1 }}>Annuler</button>
                                </div>
                            </form>
                        </div>
                    </div>
                )}

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
    addBtn: {
        display: 'flex', alignItems: 'center',
        backgroundColor: primaryBlue, color: '#fff', border: 'none',
        padding: '12px 22px', borderRadius: '14px', cursor: 'pointer',
        fontWeight: '700', fontSize: '13px', transition: 'background-color 0.2s'
    },
    cancelBtn: {
        display: 'flex', alignItems: 'center',
        backgroundColor: '#EF4444', color: '#fff', border: 'none',
        padding: '12px 22px', borderRadius: '14px', cursor: 'pointer',
        fontWeight: '700', fontSize: '13px', transition: 'background-color 0.2s'
    },
    confirmBtn: {
        display: 'inline-flex', alignItems: 'center',
        backgroundColor: '#16A34A', color: '#fff', border: 'none',
        padding: '7px 16px', borderRadius: '10px', cursor: 'pointer',
        fontSize: '12px', fontWeight: '700', transition: 'background-color 0.2s'
    },
    input: {
        width: '100%', padding: '14px 16px', borderRadius: '16px', border: '1px solid #E2E8F0',
        backgroundColor: '#F8FAFF', color: '#0F172A', fontSize: '14px', outline: 'none'
    },
    createBtn: {
        backgroundColor: primaryBlue, color: '#fff', border: 'none', padding: '12px 22px',
        borderRadius: '14px', cursor: 'pointer', fontWeight: '700', fontSize: '13px'
    },
    detailPill: {
        backgroundColor: '#2A5AF1', color: '#fff', border: 'none', padding: '10px 20px',
        borderRadius: '12px', fontSize: '13px', fontWeight: '700', cursor: 'pointer', transition: 'background-color 0.2s'
    },
    metaPill: {
        display: 'inline-flex',
        alignItems: 'center',
        backgroundColor: '#EFF6FF',
        color: '#1D4ED8',
        border: '1px solid #BFDBFE',
        padding: '6px 10px',
        borderRadius: '999px',
        fontSize: '12px',
        fontWeight: '700'
    },
    editBtn: {
        display: 'inline-flex', alignItems: 'center', gap: '4px',
        border: 'none', background: 'none', fontSize: '12px',
        cursor: 'pointer', color: '#2A5AF1', fontWeight: '600', padding: '6px 10px',
        borderRadius: '8px', backgroundColor: '#EFF6FF'
    },
    deleteBtn: {
        display: 'inline-flex', alignItems: 'center', gap: '4px',
        border: 'none', background: 'none', fontSize: '12px',
        cursor: 'pointer', color: '#EF4444', fontWeight: '600', padding: '6px 10px',
        borderRadius: '8px', backgroundColor: '#FEF2F2'
    },
    modalOverlay: {
        position: 'fixed', top: 0, left: 0, right: 0, bottom: 0,
        backgroundColor: 'rgba(15, 23, 42, 0.35)', display: 'flex', justifyContent: 'center', alignItems: 'center', zIndex: 1200,
        padding: '20px'
    },
    modalContent: {
        width: '100%', maxWidth: '680px', backgroundColor: '#fff', borderRadius: '28px', padding: '28px', boxShadow: '0 20px 70px rgba(15, 23, 42, 0.12)'
    },
    closeBtn: {
        width: '44px', height: '44px', borderRadius: '14px', border: '1px solid #E2E8F0', backgroundColor: '#fff', cursor: 'pointer', display: 'inline-flex', alignItems: 'center', justifyContent: 'center'
    }
};

export default TopUp;
