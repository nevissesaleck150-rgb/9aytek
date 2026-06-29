import React, { useState, useEffect } from 'react';
import axios from 'axios';
import Sidebar from '../components/Sidebar';
import AppHeader from '../components/AppHeader';

const primaryBlue = '#2A5AF1';
const bgLight = '#F8FAFF';
const MEDIA_BASE = 'http://127.0.0.1:8000';

const buildMediaUrl = (path) => {
    if (!path) return null;
    if (path.startsWith('http')) return path;
    if (path.startsWith('/media/')) return `${MEDIA_BASE}${path}`;
    const p = path.startsWith('/') ? `/media${path}` : `/media/${path}`;
    return `${MEDIA_BASE}${p}`;
};

const formatValue = (value, fallback = 'Non renseigné') => {
    if (value === null || value === undefined) return fallback;
    if (typeof value === 'string' && value.trim() === '') return fallback;
    return value;
};

const roleConfig = {
    admin:      { bg: '#EFF6FF', color: primaryBlue,  label: 'Admin' },
    customer:   { bg: '#EFF6FF', color: '#2563EB',    label: 'Client' },
    vendor:     { bg: '#EFF6FF', color: primaryBlue,  label: 'Marchand' },
    influencer: { bg: '#F5F3FF', color: '#8B5CF6',    label: 'Influenceur' },
    driver:     { bg: '#ECFDF5', color: '#10B981',    label: 'Livreur' },
};

const Users = () => {
    const [users, setUsers] = useState([]);
    const [loading, setLoading] = useState(true);
    const [showModal, setShowModal] = useState(false);
    const [previewUser, setPreviewUser] = useState(null);
    const [newUser, setNewUser] = useState({
        email: '',
        password: '',
        role: 'customer',
        full_name: '',
        phone: '',
        address: '',
        latitude: '',
        longitude: '',
        vehicle_type: '',
        vehicle_plate: '',
        store_name: '',
        store_description: '',
        store_type: '',
    });
    const [profileImageFile, setProfileImageFile] = useState(null);
    const [vehicleImageFile, setVehicleImageFile] = useState(null);

    const fetchUsers = async () => {
        try {
            const token = localStorage.getItem('access_token');
            const res = await axios.get('http://127.0.0.1:8000/api/users/', {
                headers: { Authorization: `Bearer ${token}` }
            });
            setUsers(res.data);
            setLoading(false);
        } catch (err) {
            console.error('Erreur lors du chargement des utilisateurs', err);
            setLoading(false);
        }
    };

    useEffect(() => { fetchUsers(); }, []);

    const handleApprove = async (userId) => {
        try {
            const token = localStorage.getItem('access_token');
            await axios.post(`http://127.0.0.1:8000/api/users/${userId}/approve/`, {}, {
                headers: { Authorization: `Bearer ${token}` }
            });
            fetchUsers();
            alert('Utilisateur approuvé avec succès !');
        } catch (err) {
            console.error('Erreur approbation:', err);
            alert("Erreur lors de l'approbation. Vérifiez les permissions.");
        }
    };

    const handleReject = async (userId) => {
        if (window.confirm('Êtes-vous sûr de vouloir rejeter cet utilisateur ?')) {
            try {
                const token = localStorage.getItem('access_token');
                await axios.post(`http://127.0.0.1:8000/api/users/${userId}/reject/`, {}, {
                    headers: { Authorization: `Bearer ${token}` }
                });
                setPreviewUser(null);
                fetchUsers();
                alert('Utilisateur rejeté avec succès.');
            } catch (err) {
                console.error('Erreur rejet:', err);
                alert('Erreur lors du rejet. Vérifiez les permissions.');
            }
        }
    };

    const handlePreview = async (userId) => {
        try {
            const token = localStorage.getItem('access_token');
            const res = await axios.get(`http://127.0.0.1:8000/api/users/${userId}/`, {
                headers: { Authorization: `Bearer ${token}` }
            });
            setPreviewUser(res.data);
        } catch (err) {
            console.error('Erreur preview:', err);
            alert('Impossible de charger les détails de l\'utilisateur.');
        }
    };

    const resetNewUserForm = () => {
        setNewUser({
            email: '',
            password: '',
            role: 'customer',
            full_name: '',
            phone: '',
            address: '',
            latitude: '',
            longitude: '',
            vehicle_type: '',
            vehicle_plate: '',
            store_name: '',
            store_description: '',
            store_type: '',
        });
        setProfileImageFile(null);
        setVehicleImageFile(null);
    };

    const handleCreateUser = async (e) => {
        e.preventDefault();
        try {
            const token = localStorage.getItem('access_token');
            const formData = new FormData();

            Object.entries(newUser).forEach(([key, value]) => {
                if (value !== null && value !== undefined && String(value).trim() !== '') {
                    formData.append(key, value);
                }
            });

            if (profileImageFile) {
                formData.append('profile_image', profileImageFile);
            }
            if (vehicleImageFile && newUser.role === 'driver') {
                formData.append('vehicle_image', vehicleImageFile);
            }

            await axios.post('http://127.0.0.1:8000/api/register/', formData, {
                headers: {
                    Authorization: `Bearer ${token}`,
                    'Content-Type': 'multipart/form-data',
                }
            });

            setShowModal(false);
            resetNewUserForm();
            fetchUsers();
            alert('Utilisateur créé avec succès.');
        } catch (err) {
            console.error('Erreur création utilisateur', err.response?.data || err);
            const data = err.response?.data;
            const errors = data?.errors || data || {};

            if (errors?.email) {
                alert('Cette adresse e-mail est déjà utilisée.');
            } else if (errors?.password) {
                const pwErr = Array.isArray(errors.password) ? errors.password[0] : errors.password;
                alert(`Mot de passe invalide : ${pwErr}`);
            } else if (errors?.role) {
                alert('Rôle invalide.');
            } else {
                alert('Impossible de créer l\'utilisateur. Vérifiez les informations saisies.');
            }
        }
    };

    const totalCustomers  = users.filter(u => u.role === 'customer').length;
    const totalVendors     = users.filter(u => u.role === 'vendor').length;
    const totalInfluencers = users.filter(u => u.role === 'influencer').length;
    const totalDrivers     = users.filter(u => u.role === 'driver').length;

    return (
        <div style={{ display: 'flex', backgroundColor: bgLight, minHeight: '100vh' }}>
            <Sidebar />
            <main style={{ marginLeft: '260px', flex: 1, padding: '40px' }}>

                <AppHeader
                    title="Utilisateurs"
                    subtitle="Gestion des comptes clients, vendeurs, influenceurs et livreurs"
                    actions={
                        <button
                            onClick={() => {
                                resetNewUserForm();
                                setShowModal(true);
                            }}
                            style={styles.addBtn}
                        >
                            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#fff"
                                strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"
                                style={{ marginRight: '7px' }}>
                                <line x1="12" y1="5" x2="12" y2="19" />
                                <line x1="5" y1="12" x2="19" y2="12" />
                            </svg>
                            Ajouter un utilisateur
                        </button>
                    }
                />

                {/* ── StatCards ── */}
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, minmax(0, 1fr))', gap: '28px', marginBottom: '44px' }}>
                    <StatCard
                        label="CLIENTS"
                        value={totalCustomers}
                        unit="Clt."
                        color="#2A5AF1"
                        icon={
                            <>
                                <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" />
                                <circle cx="12" cy="7" r="4" />
                            </>
                        }
                    />
                    <StatCard
                        label="MARCHANDS"
                        value={totalVendors}
                        unit="Marc."
                        color={primaryBlue}
                        icon={
                            <>
                                <path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z" />
                                <polyline points="9 22 9 12 15 12 15 22" />
                            </>
                        }
                    />
                    <StatCard
                        label="INFLUENCEURS"
                        value={totalInfluencers}
                        unit="Inf."
                        color="#8B5CF6"
                        icon={
                            <>
                                <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
                            </>
                        }
                    />
                    <StatCard
                        label="LIVREURS"
                        value={totalDrivers}
                        unit="Liv."
                        color="#10B981"
                        icon={
                            <>
                                <rect x="1" y="3" width="15" height="13" rx="2" />
                                <path d="M16 8h4l3 5v4h-7V8z" />
                                <circle cx="5.5" cy="18.5" r="2.5" />
                                <circle cx="18.5" cy="18.5" r="2.5" />
                            </>
                        }
                    />
                </div>

                {/* ── Table Card ── */}
                <div style={styles.tableCard}>
                    <div style={{ marginBottom: '20px', paddingBottom: '14px', borderBottom: '1px solid #F1F5F9' }}>
                        <h3 style={{ fontSize: '15px', fontWeight: '700', color: '#0F172A', margin: 0 }}>
                            Liste des Utilisateurs
                        </h3>
                        <p style={{ margin: '4px 0 0', fontSize: '12px', color: '#94A3B8' }}>
                            {users.length} utilisateur{users.length !== 1 ? 's' : ''} enregistré{users.length !== 1 ? 's' : ''}
                        </p>
                    </div>

                    <table style={{ width: '100%', borderCollapse: 'separate', borderSpacing: '0 14px' }}>
                        <thead>
                            <tr style={{ textAlign: 'left' }}>
                                <th style={{...styles.th, width: '30%'}}>UTILISATEUR</th>
                                <th style={{...styles.th, width: '18%'}}>RÔLE</th>
                                <th style={{...styles.th, width: '18%'}}>STATUT</th>
                                <th style={{...styles.th, width: '34%'}}>ACTIONS</th>
                            </tr>
                        </thead>
                        <tbody>
                            {loading ? (
                                <tr>
                                    <td colSpan="4" style={{ textAlign: 'center', padding: '30px', color: '#94A3B8', fontSize: '14px' }}>
                                        Chargement...
                                    </td>
                                </tr>
                            ) : users.map((u, idx) => {
                                const rc = roleConfig[u.role] || { bg: '#F1F5F9', color: '#64748B', label: u.role };
                                return (
                                    <tr key={u.id} style={{
                                        ...styles.tableRow,
                                        backgroundColor: idx % 2 === 0 ? '#FAFCFF' : '#FFFFFF',
                                    }}
                                    onMouseEnter={e => e.currentTarget.style.backgroundColor = '#F0F6FF'}
                                    onMouseLeave={e => e.currentTarget.style.backgroundColor = idx % 2 === 0 ? '#FAFCFF' : '#FFFFFF'}
                                    >

                                        {/* Utilisateur */}
                                        <td style={styles.td}>
                                            <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                                                <div style={{
                                                    width: '36px', height: '36px', borderRadius: '50%',
                                                    backgroundColor: `${primaryBlue}12`,
                                                    display: 'flex', alignItems: 'center', justifyContent: 'center'
                                                }}>
                                                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none"
                                                        stroke={primaryBlue} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                                                        <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" />
                                                        <circle cx="12" cy="7" r="4" />
                                                    </svg>
                                                </div>
                                                <div>
                                                    <div style={{ fontWeight: '700', color: '#0F172A', fontSize: '14px' }}>{u.username}</div>
                                                    <div style={{ fontSize: '11px', color: '#94A3B8', marginTop: '2px' }}>{u.email}</div>
                                                </div>
                                            </div>
                                        </td>

                                        {/* Rôle */}
                                        <td style={styles.td}>
                                            <span style={{
                                                backgroundColor: rc.bg, color: rc.color,
                                                padding: '4px 12px', borderRadius: '20px',
                                                fontSize: '12px', fontWeight: '700'
                                            }}>
                                                {rc.label}
                                            </span>
                                        </td>

                                        {/* Statut */}
                                        <td style={styles.td}>
                                            {u.is_approved ? (
                                                <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                                                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none"
                                                        stroke="#10B981" strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round">
                                                        <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14" />
                                                        <polyline points="22 4 12 14.01 9 11.01" />
                                                    </svg>
                                                    <span style={{ color: '#10B981', fontSize: '13px', fontWeight: '600' }}>Approuvé</span>
                                                </div>
                                            ) : (
                                                <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                                                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none"
                                                        stroke="#F97316" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                                                        <circle cx="12" cy="12" r="10" />
                                                        <polyline points="12 6 12 12 16 14" />
                                                    </svg>
                                                    <span style={{ color: '#F97316', fontSize: '13px', fontWeight: '600' }}>En attente</span>
                                                </div>
                                            )}
                                        </td>

                                        {/* Actions */}
                                        <td style={styles.td}>
                                            <div style={{ display: 'flex', gap: '12px', alignItems: 'center' }}>
                                                {!u.is_approved && (
                                                    <>
                                                        <button
                                                            onClick={() => handleApprove(u.id)}
                                                            style={styles.approveBtn}
                                                            onMouseEnter={e => e.currentTarget.style.backgroundColor = '#15803D'}
                                                            onMouseLeave={e => e.currentTarget.style.backgroundColor = '#16A34A'}
                                                        >
                                                            <svg width="12" height="12" viewBox="0 0 24 24" fill="none"
                                                                stroke="#fff" strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round"
                                                                style={{ marginRight: '5px' }}>
                                                                <path d="M20 6L9 17l-5-5" />
                                                            </svg>
                                                            Approuver
                                                        </button>
                                                        <button
                                                            onClick={() => handleReject(u.id)}
                                                            style={styles.rejectBtn}
                                                            onMouseEnter={e => e.currentTarget.style.backgroundColor = '#B91C1C'}
                                                            onMouseLeave={e => e.currentTarget.style.backgroundColor = '#EF4444'}
                                                        >
                                                            <svg width="12" height="12" viewBox="0 0 24 24" fill="none"
                                                                stroke="#fff" strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round"
                                                                style={{ marginRight: '5px' }}>
                                                                <line x1="18" y1="6" x2="6" y2="18" />
                                                                <line x1="6" y1="6" x2="18" y2="18" />
                                                            </svg>
                                                            Rejeter
                                                        </button>
                                                    </>
                                                )}
                                                <button
                                                    onClick={() => handlePreview(u.id)}
                                                    style={styles.eyeBtn}
                                                    title="Voir les détails"
                                                >
                                                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none"
                                                        stroke={primaryBlue} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                                                        <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" />
                                                        <circle cx="12" cy="12" r="3" />
                                                    </svg>
                                                </button>
                                                {u.is_approved && (
                                                    <span style={{ color: '#64748B', fontSize: '12px', fontWeight: '600' }}>
                                                        Consulter les infos
                                                    </span>
                                                )}
                                            </div>
                                        </td>
                                    </tr>
                                );
                            })}
                        </tbody>
                    </table>
                </div>

                {showModal && (
                    <div style={styles.modalOverlay} onClick={() => setShowModal(false)}>
                        <div style={styles.modalCard} onClick={(e) => e.stopPropagation()}>
                            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
                                <div>
                                    <h3 style={{ margin: 0, color: '#0F172A', fontSize: '18px', fontWeight: '800' }}>Nouvel utilisateur</h3>
                                    <p style={{ margin: '4px 0 0', color: '#94A3B8', fontSize: '13px' }}>
                                        Créez un compte selon le type d'utilisateur.
                                    </p>
                                </div>
                                <button style={styles.closeModalBtn} onClick={() => setShowModal(false)}>✕</button>
                            </div>

                            <form onSubmit={handleCreateUser} style={{ display: 'grid', gap: '14px' }}>
                                <div>
                                    <label style={styles.fieldLabel}>Type d'utilisateur</label>
                                    <select
                                        value={newUser.role}
                                        onChange={(e) => setNewUser({ ...newUser, role: e.target.value })}
                                        style={styles.input}
                                    >
                                        <option value="customer">Client</option>
                                        <option value="vendor">Marchand</option>
                                        <option value="influencer">Influenceur</option>
                                        <option value="driver">Livreur</option>
                                    </select>
                                </div>

                                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '14px' }}>
                                    <div>
                                        <label style={styles.fieldLabel}>Nom complet</label>
                                        <input
                                            value={newUser.full_name}
                                            onChange={(e) => setNewUser({ ...newUser, full_name: e.target.value })}
                                            placeholder="Nom complet"
                                            style={styles.input}
                                        />
                                    </div>
                                    <div>
                                        <label style={styles.fieldLabel}>Adresse e-mail</label>
                                        <input
                                            type="email"
                                            value={newUser.email}
                                            onChange={(e) => setNewUser({ ...newUser, email: e.target.value })}
                                            placeholder="email@exemple.com"
                                            style={styles.input}
                                            required
                                        />
                                    </div>
                                </div>

                                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '14px' }}>
                                    <div>
                                        <label style={styles.fieldLabel}>Mot de passe</label>
                                        <input
                                            type="password"
                                            value={newUser.password}
                                            onChange={(e) => setNewUser({ ...newUser, password: e.target.value })}
                                            placeholder="Minimum 8 caractères"
                                            style={styles.input}
                                            minLength={8}
                                            required
                                        />
                                    </div>
                                    <div>
                                        <label style={styles.fieldLabel}>Téléphone</label>
                                        <input
                                            value={newUser.phone}
                                            onChange={(e) => setNewUser({ ...newUser, phone: e.target.value })}
                                            placeholder="Téléphone"
                                            style={styles.input}
                                        />
                                    </div>
                                </div>

                                <div>
                                    <label style={styles.fieldLabel}>Adresse</label>
                                    <input
                                        value={newUser.address}
                                        onChange={(e) => setNewUser({ ...newUser, address: e.target.value })}
                                        placeholder="Adresse"
                                        style={styles.input}
                                    />
                                </div>

                                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '14px' }}>
                                    <div>
                                        <label style={styles.fieldLabel}>Latitude</label>
                                        <input
                                            value={newUser.latitude}
                                            onChange={(e) => setNewUser({ ...newUser, latitude: e.target.value })}
                                            placeholder="Latitude"
                                            style={styles.input}
                                        />
                                    </div>
                                    <div>
                                        <label style={styles.fieldLabel}>Longitude</label>
                                        <input
                                            value={newUser.longitude}
                                            onChange={(e) => setNewUser({ ...newUser, longitude: e.target.value })}
                                            placeholder="Longitude"
                                            style={styles.input}
                                        />
                                    </div>
                                </div>

                                <div>
                                    <label style={styles.fieldLabel}>Photo de profil</label>
                                    <input
                                        type="file"
                                        accept="image/*"
                                        onChange={(e) => setProfileImageFile(e.target.files?.[0] || null)}
                                        style={styles.input}
                                    />
                                </div>

                                {newUser.role === 'vendor' && (
                                    <>
                                        <div>
                                            <label style={styles.fieldLabel}>Nom de la boutique</label>
                                            <input
                                                value={newUser.store_name}
                                                onChange={(e) => setNewUser({ ...newUser, store_name: e.target.value })}
                                                placeholder="Nom de la boutique"
                                                style={styles.input}
                                            />
                                        </div>
                                        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '14px' }}>
                                            <div>
                                                <label style={styles.fieldLabel}>Catégorie</label>
                                                <input
                                                    value={newUser.store_type}
                                                    onChange={(e) => setNewUser({ ...newUser, store_type: e.target.value })}
                                                    placeholder="Catégorie"
                                                    style={styles.input}
                                                />
                                            </div>
                                            <div>
                                                <label style={styles.fieldLabel}>Description</label>
                                                <input
                                                    value={newUser.store_description}
                                                    onChange={(e) => setNewUser({ ...newUser, store_description: e.target.value })}
                                                    placeholder="Description"
                                                    style={styles.input}
                                                />
                                            </div>
                                        </div>
                                    </>
                                )}

                                {newUser.role === 'driver' && (
                                    <>
                                        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '14px' }}>
                                            <div>
                                                <label style={styles.fieldLabel}>Type de véhicule</label>
                                                <input
                                                    value={newUser.vehicle_type}
                                                    onChange={(e) => setNewUser({ ...newUser, vehicle_type: e.target.value })}
                                                    placeholder="Type de véhicule"
                                                    style={styles.input}
                                                />
                                            </div>
                                            <div>
                                                <label style={styles.fieldLabel}>Plaque d'immatriculation</label>
                                                <input
                                                    value={newUser.vehicle_plate}
                                                    onChange={(e) => setNewUser({ ...newUser, vehicle_plate: e.target.value })}
                                                    placeholder="Plaque"
                                                    style={styles.input}
                                                />
                                            </div>
                                        </div>
                                        <div>
                                            <label style={styles.fieldLabel}>Image du véhicule</label>
                                            <input
                                                type="file"
                                                accept="image/*"
                                                onChange={(e) => setVehicleImageFile(e.target.files?.[0] || null)}
                                                style={styles.input}
                                            />
                                        </div>
                                    </>
                                )}

                                <div style={{ display: 'flex', gap: '10px', marginTop: '6px' }}>
                                    <button type="submit" style={styles.confirmBtn}>Créer</button>
                                    <button type="button" onClick={() => setShowModal(false)} style={styles.cancelModalBtn}>Annuler</button>
                                </div>
                            </form>
                        </div>
                    </div>
                )}

                {/* ── Preview User Modal ── */}
                {previewUser && (() => {
                    const rc = roleConfig[previewUser.role] || { bg: '#F1F5F9', color: '#64748B', label: previewUser.role };
                    const profileImg = buildMediaUrl(previewUser.profile_image);
                    const fullName = `${previewUser.first_name || ''} ${previewUser.last_name || ''}`.trim();
                    const isDriver = previewUser.role === 'driver';
                    const isVendor = previewUser.role === 'vendor';
                    const isInfluencer = previewUser.role === 'influencer';

                    const InfoRow = ({ label, value }) => (
                        <div style={styles.previewRow}>
                            <span style={styles.previewLabel}>{label}</span>
                            <span style={styles.previewValue}>{formatValue(value)}</span>
                        </div>
                    );

                    const ImagePreview = ({ label, value }) => {
                        const imageUrl = buildMediaUrl(value);
                        if (!imageUrl) return null;
                        return (
                            <div style={{ marginTop: '12px' }}>
                                <div style={{ fontSize: '12px', color: '#64748B', fontWeight: '600', marginBottom: '6px' }}>{label}</div>
                                <img
                                    src={imageUrl}
                                    alt={label}
                                    style={styles.previewImage}
                                    onError={(e) => {
                                        e.currentTarget.style.display = 'none';
                                        const fallback = e.currentTarget.nextSibling;
                                        if (fallback) fallback.style.display = 'block';
                                    }}
                                />
                                <div style={{ display: 'none', color: '#EF4444', fontSize: '12px', padding: '10px', backgroundColor: '#FEF2F2', borderRadius: '10px' }}>
                                    Impossible d'afficher cette image.
                                </div>
                            </div>
                        );
                    };

                    return (
                    <div style={styles.modalOverlay} onClick={() => setPreviewUser(null)}>
                        <div style={{ ...styles.modalCard, maxWidth: '680px', maxHeight: '90vh', overflowY: 'auto' }} onClick={(e) => e.stopPropagation()}>

                            {/* ── Header ── */}
                            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
                                <h3 style={{ margin: 0, color: '#0F172A', fontSize: '17px', fontWeight: '800' }}>Détails de l'utilisateur</h3>
                                <button style={styles.closeModalBtn} onClick={() => setPreviewUser(null)}>✕</button>
                            </div>

                            {/* ── Profile header ── */}
                            <div style={{ display: 'flex', alignItems: 'center', gap: '16px', padding: '16px', backgroundColor: '#F8FAFF', borderRadius: '16px', marginBottom: '18px', border: '1px solid #E8EFFF' }}>
                                {profileImg ? (
                                    <img src={profileImg} alt={previewUser.username}
                                        style={{ width: '64px', height: '64px', borderRadius: '50%', objectFit: 'cover', border: '2px solid #DBEAFE', flexShrink: 0 }}
                                        onError={(e) => { e.currentTarget.style.display = 'none'; e.currentTarget.nextSibling.style.display = 'flex'; }}
                                    />
                                ) : null}
                                <div style={{ width: '64px', height: '64px', borderRadius: '50%', backgroundColor: rc.bg, border: `2px solid ${rc.color}30`, display: profileImg ? 'none' : 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '24px', fontWeight: '800', color: rc.color, flexShrink: 0 }}>
                                    {(previewUser.username || '?').charAt(0).toUpperCase()}
                                </div>
                                <div style={{ flex: 1, minWidth: 0 }}>
                                    <div style={{ fontWeight: '800', color: '#0F172A', fontSize: '16px' }}>{previewUser.username}</div>
                                    {fullName && <div style={{ color: '#475569', fontSize: '13px', marginTop: '2px' }}>{fullName}</div>}
                                    <div style={{ display: 'flex', gap: '8px', marginTop: '8px', flexWrap: 'wrap' }}>
                                        <span style={{ backgroundColor: rc.bg, color: rc.color, padding: '3px 10px', borderRadius: '20px', fontSize: '12px', fontWeight: '700' }}>{rc.label}</span>
                                        <span style={{ backgroundColor: previewUser.is_approved ? '#ECFDF5' : '#FEF3C7', color: previewUser.is_approved ? '#16A34A' : '#B45309', padding: '3px 10px', borderRadius: '20px', fontSize: '12px', fontWeight: '700' }}>
                                            {previewUser.is_approved ? 'Approuvé' : 'En attente'}
                                        </span>
                                    </div>
                                </div>
                                <div style={{ textAlign: 'right', flexShrink: 0 }}>
                                    <div style={{ fontSize: '11px', color: '#94A3B8', fontWeight: '600', marginBottom: '4px' }}>SOLDE</div>
                                    <div style={{ fontSize: '18px', fontWeight: '800', color: primaryBlue }}>{previewUser.wallet_balance || 0} <span style={{ fontSize: '12px' }}>MRU</span></div>
                                </div>
                            </div>

                            {/* ── Common info ── */}
                            <div style={{ ...styles.previewSection, marginBottom: '14px' }}>
                                <h4 style={styles.previewSectionTitle}>Informations générales</h4>
                                <div style={{ display: 'grid', gap: '8px' }}>
                                    <InfoRow label="Email" value={previewUser.email} />
                                    <InfoRow label="Téléphone" value={previewUser.phone} />
                                    <InfoRow label="Adresse" value={previewUser.address} />
                                </div>
                            </div>

                            {/* ── Driver-specific ── */}
                            {isDriver && (
                                <div style={{ ...styles.previewSection, marginBottom: '14px' }}>
                                    <h4 style={styles.previewSectionTitle}>Informations du livreur</h4>
                                    <div style={{ display: 'grid', gap: '8px' }}>
                                        <InfoRow label="Type de véhicule" value={previewUser.vehicle_type} />
                                        <InfoRow label="Plaque d'immatriculation" value={previewUser.vehicle_plate} />
                                        <InfoRow label="Compte bancaire" value={previewUser.bank_account} />
                                        {previewUser.resume && <InfoRow label="CV / Notes" value={previewUser.resume} />}
                                    </div>
                                    <ImagePreview label="Carte nationale" value={previewUser.national_id} />
                                    <ImagePreview label="Permis de conduire" value={previewUser.driving_license} />
                                    <ImagePreview label="Image du véhicule" value={previewUser.vehicle_image} />
                                </div>
                            )}

                            {/* ── Vendor-specific ── */}
                            {isVendor && (
                                <div style={{ ...styles.previewSection, marginBottom: '14px' }}>
                                    <h4 style={styles.previewSectionTitle}>Informations du marchand</h4>
                                    <div style={{ display: 'grid', gap: '8px' }}>
                                        <InfoRow label="Spécialité" value={previewUser.specialty} />
                                        <InfoRow label="Compte bancaire" value={previewUser.bank_account} />
                                        {previewUser.social_links && <InfoRow label="Réseaux sociaux" value={previewUser.social_links} />}
                                    </div>
                                    <ImagePreview label="Carte nationale" value={previewUser.national_id} />
                                </div>
                            )}

                            {/* ── Influencer-specific ── */}
                            {isInfluencer && (
                                <div style={{ ...styles.previewSection, marginBottom: '14px' }}>
                                    <h4 style={styles.previewSectionTitle}>Informations de l'influenceur</h4>
                                    <div style={{ display: 'grid', gap: '8px' }}>
                                        <InfoRow label="Spécialité" value={previewUser.specialty} />
                                        <InfoRow label="Réseaux sociaux" value={previewUser.social_links} />
                                        <InfoRow label="Compte bancaire" value={previewUser.bank_account} />
                                    </div>
                                    <ImagePreview label="Carte nationale" value={previewUser.national_id} />
                                </div>
                            )}

                            {/* ── Actions ── */}
                            {!previewUser.is_approved && (
                                <div style={{ display: 'flex', gap: '10px', marginTop: '8px' }}>
                                    <button onClick={() => handleApprove(previewUser.id)} style={styles.approveBtn}>Approuver</button>
                                    <button onClick={() => handleReject(previewUser.id)} style={styles.rejectBtn}>Rejeter</button>
                                </div>
                            )}
                        </div>
                    </div>
                    );
                })()}
            </main>
        </div>
    );
};

// ── StatCard ─────────────────────────────────────────────────
const StatCard = ({ label, value, unit, icon, color }) => (
    <div style={{
        backgroundColor: '#fff', padding: '26px 28px', borderRadius: '20px',
        border: '1px solid #E8EFFF', boxShadow: '0 4px 20px rgba(42,90,241,0.03)'
    }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <div>
                <p style={{ fontSize: '11px', color: '#64748B', fontWeight: '700', marginBottom: '10px', letterSpacing: '0.8px', textTransform: 'uppercase' }}>
                    {label}
                </p>
                <h2 style={{ fontSize: '28px', color: '#0F172A', margin: 0, fontWeight: '800' }}>
                    {value} <span style={{ fontSize: '13px', color: '#94A3B8', fontWeight: '600' }}>{unit}</span>
                </h2>
            </div>
            <div style={{
                padding: '12px', borderRadius: '14px', backgroundColor: `${color}12`,
                display: 'flex', alignItems: 'center', justifyContent: 'center'
            }}>
                <svg width="22" height="22" viewBox="0 0 24 24" fill="none"
                    stroke={color} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                    {icon}
                </svg>
            </div>
        </div>
    </div>
);

// ── Styles ────────────────────────────────────────────────────
const styles = {
    modalOverlay: {
        position: 'fixed',
        top: 0,
        left: 0,
        width: '100vw',
        height: '100vh',
        backgroundColor: 'rgba(15, 23, 42, 0.35)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        zIndex: 2000,
        padding: '20px'
    },
    modalCard: {
        width: '100%',
        maxWidth: '560px',
        backgroundColor: '#fff',
        borderRadius: '24px',
        padding: '30px',
        boxShadow: '0 20px 50px rgba(15, 23, 42, 0.12)'
    },
    closeModalBtn: {
        width: '34px',
        height: '34px',
        borderRadius: '12px',
        border: '1px solid #E2E8F0',
        backgroundColor: '#F8FAFF',
        color: '#0F172A',
        cursor: 'pointer',
        fontSize: '16px',
        fontWeight: '700'
    },
    dateBadge: {
        backgroundColor: '#FFF', padding: '10px 16px', borderRadius: '12px',
        border: '1px solid #E2E8F0', fontSize: '13px', color: '#475569', fontWeight: '600'
    },
    addBtn: {
        display: 'flex',
        alignItems: 'center',
        backgroundColor: primaryBlue,
        color: '#fff',
        border: 'none',
        padding: '10px 20px',
        borderRadius: '12px',
        cursor: 'pointer',
        fontWeight: '700',
        fontSize: '13px',
        transition: 'background-color 0.2s'
    },
    tableCard: {
        backgroundColor: '#fff', padding: '34px 38px', borderRadius: '24px',
        border: '1px solid #E8EFFF', boxShadow: '0 4px 20px rgba(42,90,241,0.03)'
    },
    refreshBtn: {},
    th: { padding: '14px 24px', color: '#94A3B8', fontSize: '11px', fontWeight: '800', letterSpacing: '1.2px', textTransform: 'uppercase' },
    td: { padding: '20px 24px', color: '#334155', fontSize: '14px' },
    tableRow: { backgroundColor: '#FAFCFF', borderRadius: '12px' },
    approveBtn: {
        display: 'inline-flex', alignItems: 'center',
        backgroundColor: '#16A34A', color: '#fff', border: 'none',
        padding: '7px 14px', borderRadius: '10px', cursor: 'pointer',
        fontSize: '12px', fontWeight: '700', transition: 'background-color 0.2s'
    },
    rejectBtn: {
        display: 'inline-flex', alignItems: 'center',
        backgroundColor: '#EF4444', color: '#fff', border: 'none',
        padding: '7px 14px', borderRadius: '10px', cursor: 'pointer',
        fontSize: '12px', fontWeight: '700', transition: 'background-color 0.2s'
    },
    eyeBtn: {
        display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
        width: '34px', height: '34px', borderRadius: '10px',
        border: '1px solid #DBEAFE', backgroundColor: '#EFF6FF',
        cursor: 'pointer', transition: 'background-color 0.2s',
    },
    fieldLabel: {
        display: 'block',
        marginBottom: '6px',
        fontSize: '13px',
        fontWeight: '600',
        color: '#334155'
    },
    input: {
        width: '100%',
        padding: '12px 16px',
        borderRadius: '12px',
        border: '1px solid #E2E8F0',
        backgroundColor: '#F8FAFF',
        color: '#0F172A',
        fontSize: '14px',
        outline: 'none',
        boxSizing: 'border-box'
    },
    confirmBtn: {
        display: 'inline-flex',
        alignItems: 'center',
        justifyContent: 'center',
        backgroundColor: primaryBlue,
        color: '#fff',
        border: 'none',
        padding: '14px 22px',
        borderRadius: '14px',
        cursor: 'pointer',
        fontWeight: '700',
        fontSize: '14px',
        flex: 1
    },
    cancelModalBtn: {
        backgroundColor: '#F1F5F9',
        color: '#64748B',
        border: 'none',
        padding: '14px 22px',
        borderRadius: '14px',
        cursor: 'pointer',
        fontWeight: '600',
        fontSize: '14px'
    },
    previewSection: {
        backgroundColor: '#fff',
        border: '1px solid #E8EFFF',
        borderRadius: '18px',
        padding: '16px'
    },
    previewSectionTitle: {
        margin: '0 0 12px',
        color: '#0F172A',
        fontSize: '15px',
        fontWeight: '800'
    },
    previewRow: {
        display: 'flex',
        justifyContent: 'space-between',
        gap: '12px',
        padding: '10px 14px',
        backgroundColor: '#F8FAFF',
        borderRadius: '10px',
        border: '1px solid #E8EFFF'
    },
    previewLabel: {
        color: '#64748B',
        fontSize: '13px',
        fontWeight: '600'
    },
    previewValue: {
        color: '#0F172A',
        fontSize: '13px',
        fontWeight: '700',
        textAlign: 'right'
    },
    imageCard: {
        display: 'grid',
        gap: '10px',
        padding: '12px',
        backgroundColor: '#F8FAFF',
        borderRadius: '12px',
        border: '1px solid #E8EFFF'
    },
    previewImage: {
        width: '100%',
        height: '180px',
        objectFit: 'cover',
        borderRadius: '12px',
        border: '1px solid #DBEAFE'
    },
    previewImageFallback: {
        height: '180px',
        borderRadius: '12px',
        border: '1px dashed #CBD5E1',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        color: '#94A3B8',
        backgroundColor: '#FFFFFF',
        fontSize: '13px',
        fontWeight: '600'
    },
};

export default Users;
