import React, { useState, useEffect } from 'react';
import Sidebar from '../components/Sidebar';
import AppHeader from '../components/AppHeader';
import axios from 'axios';

const primaryBlue = '#2A5AF1';
const bgLight = '#F8FAFF';
const API_BASE = 'http://127.0.0.1:8000/api';
const MEDIA_BASE = 'http://127.0.0.1:8000';

const buildMediaUrl = (path) => {
    if (!path) return null;
    if (path.startsWith('http')) return path;
    if (path.startsWith('/media/')) return `${MEDIA_BASE}${path}`;
    const p = path.startsWith('/') ? `/media${path}` : `/media/${path}`;
    return `${MEDIA_BASE}${p}`;
};

const Shops = () => {
    const [shops, setShops] = useState([]);
    const [users, setUsers] = useState([]);
    const [products, setProducts] = useState([]);
    const [selectedShop, setSelectedShop] = useState(null);
    const [shopProducts, setShopProducts] = useState([]);
    const [loading, setLoading] = useState(true);
    const [form, setForm] = useState({ name: '', description: '', category: '', vendor: '' });

    useEffect(() => { fetchShops(); fetchProducts(); fetchUsers(); }, []);

    const fetchShops = async () => {
        try {
            const token = localStorage.getItem('access_token');
            const res = await axios.get(`${API_BASE}/shops/`, {
                headers: { Authorization: `Bearer ${token}` }
            });
            setShops(res.data);
        } catch (err) {
            console.error('Erreur Shops:', err);
        } finally {
            setLoading(false);
        }
    };

    const fetchProducts = async () => {
        try {
            const token = localStorage.getItem('access_token');
            const res = await axios.get(`${API_BASE}/products/`, {
                headers: { Authorization: `Bearer ${token}` }
            });
            setProducts(res.data);
        } catch (err) {
            console.error('Erreur Products:', err);
        }
    };

    const fetchUsers = async () => {
        try {
            const token = localStorage.getItem('access_token');
            const res = await axios.get(`${API_BASE}/users/`, {
                headers: { Authorization: `Bearer ${token}` }
            });
            setUsers(res.data);
        } catch (err) {
            console.error('Erreur Users:', err);
        }
    };

    const handleCreate = async () => {
        try {
            const token = localStorage.getItem('access_token');
            const payload = {
                name: form.name,
                description: form.description,
                category: form.category,
                ...(form.vendor ? { vendor: Number(form.vendor) } : {}),
            };
            const res = await axios.post(`${API_BASE}/shops/`, payload, {
                headers: { Authorization: `Bearer ${token}` }
            });
            setShops([res.data, ...shops]);
            setForm({ name: '', description: '', category: '', vendor: '' });
        } catch (err) {
            console.error('Erreur création boutique:', err);
            alert('Impossible de creer la boutique');
        }
    };

    const handleToggleActive = async (shop) => {
        try {
            const token = localStorage.getItem('access_token');
            const res = await axios.patch(`${API_BASE}/shops/${shop.id}/`, {
                is_active: !shop.is_active,
            }, {
                headers: { Authorization: `Bearer ${token}` }
            });
            setShops(shops.map((item) => item.id === shop.id ? res.data : item));
        } catch (err) {
            console.error('Erreur activation boutique:', err);
            alert('Impossible de mettre a jour le statut de la boutique');
        }
    };

    const handleDelete = async (shopId) => {
        if (!window.confirm('Supprimer cette boutique ?')) return;
        try {
            const token = localStorage.getItem('access_token');
            await axios.delete(`${API_BASE}/shops/${shopId}/`, {
                headers: { Authorization: `Bearer ${token}` }
            });
            setShops(shops.filter((shop) => shop.id !== shopId));
        } catch (err) {
            console.error('Erreur suppression boutique:', err);
            alert('Impossible de supprimer la boutique');
        }
    };

    const handleExploreShop = (shop) => {
        setSelectedShop(shop);
        const filtered = products.filter((product) => product.vendor === shop.vendor);
        setShopProducts(filtered);
    };

    const handleApproveProduct = async (product) => {
        try {
            const token = localStorage.getItem('access_token');
            const res = await axios.patch(`${API_BASE}/products/${product.id}/`, { is_approved: true }, {
                headers: { Authorization: `Bearer ${token}` }
            });
            const updated = res.data;
            setShopProducts(shopProducts.map((item) => item.id === product.id ? updated : item));
            setProducts(products.map((item) => item.id === product.id ? updated : item));
            // Also update selectedShop.vendorProducts so the modal reflects the change
            setSelectedShop(prev => ({
                ...prev,
                vendorProducts: prev.vendorProducts.map(p => p.id === product.id ? updated : p)
            }));
        } catch (err) {
            console.error('Erreur approbation produit:', err.response?.data || err);
            alert('Impossible d\u2019accepter le produit. Vérifiez les permissions.');
        }
    };

    const handleDeleteProduct = async (productId) => {
        if (!window.confirm('Supprimer ce produit ?')) return;
        try {
            const token = localStorage.getItem('access_token');
            await axios.delete(`${API_BASE}/products/${productId}/`, {
                headers: { Authorization: `Bearer ${token}` }
            });
            setShopProducts(shopProducts.filter((item) => item.id !== productId));
            setProducts(products.filter((item) => item.id !== productId));
        } catch (err) {
            console.error('Erreur suppression produit:', err);
            alert('Impossible de supprimer le produit.');
        }
    };

    const totalVendors = users.filter(user => user.role === 'vendor').length;
    const totalInfluencers = users.filter(user => user.role === 'influencer').length;
    const vendorUsers = users.filter(user => user.role === 'vendor');
    const influencerUsers = users.filter(user => user.role === 'influencer');
    const shopsByVendorId = new Map(shops.map((shop) => [shop.vendor, shop]));

    return (
        <div style={{ display: 'flex', backgroundColor: bgLight, minHeight: '100vh' }}>
            <Sidebar />
            <main style={{ marginLeft: '260px', flex: 1, padding: '40px' }}>
                <AppHeader
                    title="Boutiques"
                    subtitle="Surveillez les boutiques, explorez les produits et acceptez les collections"
                />

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '24px', marginBottom: '40px' }}>
                    <StatCard label="MARCHANDS" value={totalVendors} unit="Pers." color={primaryBlue}
                        icon={<><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z" /><polyline points="9 22 9 12 15 12 15 22" /></>}
                    />
                    <StatCard label="INFLUENCEURS" value={totalInfluencers} unit="Pers." color="#8B5CF6"
                        icon={<><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" /><circle cx="9" cy="7" r="4" /><path d="M23 21v-2a4 4 0 0 0-3-3.87" /><path d="M16 3.13a4 4 0 0 1 0 7.75" /></>}
                    />
                </div>

                <div style={styles.tableCard}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
                        <h3 style={{ margin: 0, color: '#0F172A' }}>Marchands</h3>
                        <span style={styles.counterPill}>{vendorUsers.length} marchands</span>
                    </div>
                    {vendorUsers.length === 0 ? (
                        <p style={{ color: '#94A3B8', textAlign: 'center', padding: '20px' }}>Aucun marchand enregistré.</p>
                    ) : (
                        <div style={{ display: 'grid', gap: '16px' }}>
                            {vendorUsers.map((vendor) => {
                                const shopInfo = shopsByVendorId.get(vendor.id);
                                const shopImage = buildMediaUrl(shopInfo?.image || vendor.profile_image);
                                return (
                                <div key={vendor.id} style={styles.shopCard}>
                                    <div style={{ display: 'flex', justifyContent: 'space-between', gap: '16px' }}>
                                        <div style={{ display: 'flex', gap: '16px', flex: 1 }}>
                                            <div style={styles.shopImageWrap}>
                                                {shopImage ? (
                                                    <img
                                                        src={shopImage}
                                                        alt={shopInfo?.name || vendor.username}
                                                        style={styles.shopImage}
                                                        onError={(e) => {
                                                            e.currentTarget.style.display = 'none';
                                                            const fallback = e.currentTarget.nextSibling;
                                                            if (fallback) fallback.style.display = 'flex';
                                                        }}
                                                    />
                                                ) : null}
                                                <div
                                                    style={{
                                                        ...styles.shopImageFallback,
                                                        display: shopImage ? 'none' : 'flex',
                                                    }}
                                                >
                                                    {(shopInfo?.name || vendor.username || 'S').charAt(0).toUpperCase()}
                                                </div>
                                            </div>
                                            <div>
                                            <h4 style={{ margin: 0, color: '#0F172A' }}>{shopInfo?.name || vendor.username}</h4>
                                            <p style={{ color: '#64748B', marginTop: '6px', fontSize: '13px' }}>{vendor.email}</p>
                                            {shopInfo?.category ? (
                                                <p style={{ color: '#475569', marginTop: '6px', fontSize: '13px' }}>
                                                    <strong>Catégorie:</strong> {shopInfo.category}
                                                </p>
                                            ) : null}
                                            {shopInfo?.description ? (
                                                <p style={{ color: '#64748B', marginTop: '6px', fontSize: '13px' }}>
                                                    {shopInfo.description}
                                                </p>
                                            ) : null}
                                            <p style={{ color: '#475569', marginTop: '6px', fontSize: '13px' }}>
                                                <strong>Statut:</strong> {vendor.is_approved ? 'Approuvé' : 'En attente'}
                                            </p>
                                        </div>
                                        </div>
                                        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end', gap: '10px' }}>
                                            <span style={{ ...styles.statusBadge, backgroundColor: vendor.is_approved ? '#ECFDF5' : '#FEF3C7', color: vendor.is_approved ? '#16A34A' : '#B45309' }}>
                                                {vendor.is_approved ? 'Actif' : 'En attente'}
                                            </span>
                                            <button onClick={() => {
                                                const vendorProducts = products.filter(p => p.vendor === vendor.id);
                                                setSelectedShop({ name: vendor.username, vendorId: vendor.id, vendorProducts });
                                            }} style={styles.smallBtn}>
                                                Explorer les produits
                                            </button>
                                        </div>
                                    </div>
                                </div>
                            )})}
                        </div>
                    )}
                </div>

                <div style={{ ...styles.tableCard, marginTop: '24px' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
                        <h3 style={{ margin: 0, color: '#0F172A' }}>Influenceurs</h3>
                        <span style={styles.counterPill}>{influencerUsers.length} influenceurs</span>
                    </div>
                    {influencerUsers.length === 0 ? (
                        <p style={{ color: '#94A3B8', textAlign: 'center', padding: '20px' }}>Aucun influenceur enregistré.</p>
                    ) : (
                        <div style={{ display: 'grid', gap: '16px' }}>
                            {influencerUsers.map((inf) => {
                                const infImage = buildMediaUrl(inf.profile_image);
                                return (
                                <div key={inf.id} style={styles.shopCard}>
                                    <div style={{ display: 'flex', justifyContent: 'space-between', gap: '16px' }}>
                                        <div style={{ display: 'flex', gap: '16px', flex: 1 }}>
                                            <div style={styles.shopImageWrap}>
                                                {infImage ? (
                                                    <img
                                                        src={infImage}
                                                        alt={inf.username}
                                                        style={styles.shopImage}
                                                        onError={(e) => {
                                                            e.currentTarget.style.display = 'none';
                                                            const fallback = e.currentTarget.nextSibling;
                                                            if (fallback) fallback.style.display = 'flex';
                                                        }}
                                                    />
                                                ) : null}
                                                <div style={{ ...styles.shopImageFallback, display: infImage ? 'none' : 'flex' }}>
                                                    {(inf.username || 'I').charAt(0).toUpperCase()}
                                                </div>
                                            </div>
                                            <div>
                                                <h4 style={{ margin: 0, color: '#0F172A' }}>{inf.username}</h4>
                                                <p style={{ color: '#64748B', marginTop: '6px', fontSize: '13px' }}>{inf.email}</p>
                                                <p style={{ color: '#475569', marginTop: '6px', fontSize: '13px' }}>
                                                    <strong>Statut:</strong> {inf.is_approved ? 'Approuvé' : 'En attente'}
                                                </p>
                                            </div>
                                        </div>
                                        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end', gap: '10px' }}>
                                            <span style={{ ...styles.statusBadge, backgroundColor: inf.is_approved ? '#ECFDF5' : '#FEF3C7', color: inf.is_approved ? '#16A34A' : '#B45309' }}>
                                                {inf.is_approved ? 'Actif' : 'En attente'}
                                            </span>
                                        </div>
                                    </div>
                                </div>
                            )})}
                        </div>
                    )}
                </div>

                {selectedShop && (
                    <div style={styles.modalOverlay} onClick={() => setSelectedShop(null)}>
                        <div style={styles.modalContent} onClick={(e) => e.stopPropagation()}>
                            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
                                <div>
                                    <h3 style={{ margin: 0, color: '#0F172A' }}>Produits de {selectedShop.name}</h3>
                                    <p style={{ margin: '8px 0 0', color: '#64748B', fontSize: '13px' }}>
                                        Gérez les produits et acceptez les nouveautés.
                                    </p>
                                </div>
                                <button style={styles.closeModalBtn} onClick={() => setSelectedShop(null)}>✕</button>
                            </div>
                            {selectedShop.vendorProducts.length === 0 ? (
                                <p style={{ color: '#64748B' }}>Aucun produit trouvé pour ce marchand.</p>
                            ) : (
                                <div style={{ display: 'grid', gap: '16px' }}>
                                    {selectedShop.vendorProducts.map((product) => (
                                        <div key={product.id} style={styles.productRow}>
                                            <div style={{ display: 'flex', alignItems: 'center', gap: '16px', flex: 1 }}>
                                                <div style={{
                                                    width: '64px', height: '64px', borderRadius: '12px',
                                                    backgroundColor: '#F1F5F9', overflow: 'hidden',
                                                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                                                    flexShrink: 0, border: '1px solid #E2E8F0'
                                                }}>
                                                    {product.image ? (
                                                        <img
                                                            src={product.image.startsWith('http') ? product.image : `http://127.0.0.1:8000${product.image}`}
                                                            alt={product.name}
                                                            style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                                                            onError={(e) => {
                                                                e.target.style.display = 'none';
                                                                e.target.parentElement.innerHTML = '<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#94A3B8" strokeWidth="1.5"><rect x="3" y="3" width="18" height="18" rx="2"/><circle cx="8.5" cy="8.5" r="1.5"/><path d="M21 15l-5-5L5 21"/></svg>';
                                                            }}
                                                        />
                                                    ) : (
                                                        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#94A3B8" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
                                                            <rect x="3" y="3" width="18" height="18" rx="2"/>
                                                            <circle cx="8.5" cy="8.5" r="1.5"/>
                                                            <path d="M21 15l-5-5L5 21"/>
                                                        </svg>
                                                    )}
                                                </div>
                                                <div>
                                                    <strong style={{ color: '#0F172A' }}>{product.name}</strong>
                                                    <p style={{ margin: '4px 0 0', color: '#64748B', fontSize: '13px' }}>{product.description || 'Pas de description'}</p>
                                                    <p style={{ margin: '4px 0 0', color: '#475569', fontSize: '13px', fontWeight: '700' }}>{parseFloat(product.price).toFixed(2)} MRU</p>
                                                </div>
                                            </div>
                                            <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
                                                <span style={{ padding: '6px 10px', borderRadius: '999px', backgroundColor: product.is_approved ? '#ECFDF5' : '#FEF3C7', color: product.is_approved ? '#16A34A' : '#B45309', fontWeight: '700', fontSize: '12px' }}>
                                                    {product.is_approved ? 'Approuvé' : 'En attente'}
                                                </span>
                                                {!product.is_approved && (
                                                    <button onClick={() => handleApproveProduct(product)} style={styles.productActionBtn}>
                                                        Accepter
                                                    </button>
                                                )}
                                                <button onClick={() => handleDeleteProduct(product.id)} style={styles.deleteBtn}>Supprimer</button>
                                            </div>
                                        </div>
                                    ))}
                                </div>
                            )}
                        </div>
                    </div>
                )}
            </main>
        </div>
    );
};

const StatCard = ({ label, value, unit, color, icon }) => (
    <div style={styles.card}>
        <div style={{ display: 'flex', justifyContent: 'space-between' }}>
            <div>
                <p style={styles.cardLabel}>{label}</p>
                <h2 style={styles.cardValue}>{value} <span style={{ fontSize: '14px', color: '#94A3B8' }}>{unit}</span></h2>
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

const styles = {
    card: {
        backgroundColor: '#fff',
        padding: '24px',
        borderRadius: '20px',
        border: '1px solid #E8EFFF',
        boxShadow: '0 4px 20px rgba(42, 90, 241, 0.03)',
    },
    modalOverlay: {
        position: 'fixed',
        inset: 0,
        backgroundColor: 'rgba(15, 23, 42, 0.35)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        padding: '24px',
        zIndex: 2000,
    },
    modalContent: {
        width: '100%',
        maxWidth: '760px',
        backgroundColor: '#fff',
        borderRadius: '24px',
        padding: '26px',
        boxShadow: '0 20px 60px rgba(15, 23, 42, 0.18)',
    },
    productRow: {
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        gap: '16px',
        backgroundColor: '#F8FAFF',
        padding: '18px',
        borderRadius: '18px',
        border: '1px solid #E8EFFF',
    },
    productActionBtn: {
        padding: '10px 16px',
        borderRadius: '12px',
        backgroundColor: '#2A5AF1',
        color: '#fff',
        border: 'none',
        cursor: 'pointer',
        fontWeight: '700',
        fontSize: '13px'
    },
    closeModalBtn: {
        backgroundColor: '#F8FAFF',
        color: '#0F172A',
        border: '1px solid #E2E8F0',
        borderRadius: '12px',
        width: '36px',
        height: '36px',
        cursor: 'pointer',
        fontSize: '16px',
        fontWeight: '700'
    },
    cardLabel: { fontSize: '12px', color: '#64748B', fontWeight: '700', marginBottom: '8px', letterSpacing: '0.5px' },
    cardValue: { fontSize: '26px', color: '#0F172A', margin: '0', fontWeight: '800' },
    tableCard: {
        backgroundColor: '#fff',
        padding: '30px',
        borderRadius: '24px',
        border: '1px solid #E8EFFF',
        boxShadow: '0 4px 20px rgba(42, 90, 241, 0.03)'
    },
    refreshBtn: {},
    confirmBtn: {
        backgroundColor: '#2A5AF1',
        color: '#fff',
        border: 'none',
        padding: '12px 20px',
        borderRadius: '14px',
        cursor: 'pointer',
        fontWeight: '700',
        fontSize: '14px'
    },
    input: {
        width: '100%',
        padding: '14px 16px',
        borderRadius: '14px',
        border: '1px solid #E2E8F0',
        fontSize: '14px',
        color: '#111827'
    },
    counterPill: {
        display: 'inline-flex',
        alignItems: 'center',
        padding: '8px 14px',
        borderRadius: '999px',
        backgroundColor: '#EFF6FF',
        color: '#2A5AF1',
        fontWeight: '700',
        fontSize: '12px'
    },
    shopCard: {
        backgroundColor: '#fff',
        borderRadius: '18px',
        border: '1px solid #E8EFFF',
        padding: '22px',
        boxShadow: '0 10px 30px rgba(15, 23, 42, 0.04)'
    },
    shopImageWrap: {
        width: '72px',
        height: '72px',
        borderRadius: '18px',
        overflow: 'hidden',
        backgroundColor: '#EFF6FF',
        border: '1px solid #DCE8FF',
        flexShrink: 0,
        position: 'relative'
    },
    shopImage: {
        width: '100%',
        height: '100%',
        objectFit: 'cover',
        display: 'block'
    },
    shopImageFallback: {
        position: 'absolute',
        inset: 0,
        alignItems: 'center',
        justifyContent: 'center',
        color: '#2A5AF1',
        fontWeight: '800',
        fontSize: '24px'
    },
    statusBadge: {
        padding: '8px 14px',
        borderRadius: '999px',
        fontSize: '12px',
        fontWeight: '700'
    },
    smallBtn: {
        padding: '10px 20px',
        borderRadius: '12px',
        border: 'none',
        backgroundColor: '#2A5AF1',
        color: '#fff',
        cursor: 'pointer',
        fontWeight: '700',
        fontSize: '13px',
        transition: 'background-color 0.2s'
    },
    deleteBtn: {
        padding: '10px 14px',
        borderRadius: '12px',
        border: '1px solid #FECACA',
        backgroundColor: '#FFF1F1',
        color: '#B91C1C',
        cursor: 'pointer',
        fontWeight: '700',
        fontSize: '13px'
    }
};

export default Shops;
