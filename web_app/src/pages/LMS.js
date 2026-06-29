import React, { useState, useEffect } from 'react';
import Sidebar from '../components/Sidebar';
import AppHeader from '../components/AppHeader';
import axios from 'axios';

const primaryBlue = '#2A5AF1';
const bgLight = '#F8FAFF';
const SERVER_BASE = 'http://127.0.0.1:8000';

const getImageUrl = (path) => {
    if (!path) return null;
    if (path.startsWith('http')) return path;
    return `${SERVER_BASE}${path.startsWith('/') ? '' : '/'}${path}`;
};

const LMS = () => {
    const [courses, setCourses] = useState([]);
    const [orders, setOrders] = useState([]);
    const [loading, setLoading] = useState(true);
    const [showModal, setShowModal] = useState(false);
    const [editingCourse, setEditingCourse] = useState(null);
    const [newCourse, setNewCourse] = useState({
        title: '', price: '', description: '', content_link: '', type: 'course'
    });
    const [imageFile, setImageFile] = useState(null);
    const [imagePreview, setImagePreview] = useState(null);

    const fetchCourses = async () => {
        try {
            const token = localStorage.getItem('access_token');
            const [servicesRes, ordersRes] = await Promise.all([
                axios.get('http://127.0.0.1:8000/api/services/', {
                    headers: { Authorization: `Bearer ${token}` }
                }),
                axios.get('http://127.0.0.1:8000/api/orders/', {
                    headers: { Authorization: `Bearer ${token}` }
                }),
            ]);
            const coursesOnly = servicesRes.data.filter(item => String(item.type || '').toLowerCase().includes('course'));
            setCourses(coursesOnly);
            setOrders(ordersRes.data);
            setLoading(false);
        } catch (err) {
            console.error('Erreur LMS:', err);
            setLoading(false);
        }
    };

    useEffect(() => { fetchCourses(); }, []);

    const handleCreateCourse = async (e) => {
        e.preventDefault();
        try {
            const token = localStorage.getItem('access_token');
            if (imageFile) {
                // Multipart upload with image
                const formData = new FormData();
                formData.append('title', newCourse.title);
                formData.append('price', parseFloat(newCourse.price) || 0);
                formData.append('description', newCourse.description || '');
                formData.append('content_link', newCourse.content_link || '');
                formData.append('type', 'course');
                formData.append('required_field_name', 'Lien vidéo');
                formData.append('image', imageFile);
                await axios.post('http://127.0.0.1:8000/api/services/', formData, {
                    headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'multipart/form-data' }
                });
            } else {
                const payload = {
                    ...newCourse,
                    price: parseFloat(newCourse.price) || 0,
                    required_field_name: 'Lien vidéo',
                };
                await axios.post('http://127.0.0.1:8000/api/services/', payload, {
                    headers: { Authorization: `Bearer ${token}` }
                });
            }
            setShowModal(false);
            setNewCourse({ title: '', price: '', description: '', content_link: '', type: 'course' });
            setImageFile(null);
            setImagePreview(null);
            fetchCourses();
            alert('Cours ajouté avec succès.');
        } catch (err) {
            console.error('Erreur ajout cours:', err);
            const errMsg = err.response?.data ? JSON.stringify(err.response.data) : '';
            alert(`Impossible d'ajouter le cours. ${errMsg || 'Vérifiez les champs et réessayez.'}`);
        }
    };

    const handleUpdateCourse = async (e) => {
        e.preventDefault();
        try {
            const token = localStorage.getItem('access_token');
            if (imageFile) {
                // Multipart update with new image
                const formData = new FormData();
                formData.append('title', newCourse.title);
                formData.append('price', parseFloat(newCourse.price) || 0);
                formData.append('description', newCourse.description || '');
                formData.append('content_link', newCourse.content_link || '');
                formData.append('type', 'course');
                formData.append('image', imageFile);
                await axios.patch(`http://127.0.0.1:8000/api/services/${editingCourse.id}/`, formData, {
                    headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'multipart/form-data' }
                });
            } else {
                const payload = {
                    ...newCourse,
                    price: parseFloat(newCourse.price) || 0,
                };
                await axios.patch(`http://127.0.0.1:8000/api/services/${editingCourse.id}/`, payload, {
                    headers: { Authorization: `Bearer ${token}` }
                });
            }
            setShowModal(false);
            setEditingCourse(null);
            setNewCourse({ title: '', price: '', description: '', content_link: '', type: 'course' });
            setImageFile(null);
            setImagePreview(null);
            fetchCourses();
            alert('Cours modifié avec succès.');
        } catch (err) {
            console.error('Erreur modification cours:', err);
            alert('Impossible de modifier le cours.');
        }
    };

    const handleDeleteCourse = async (course) => {
        if (!window.confirm(`Supprimer le cours « ${course.title} » ?`)) return;
        try {
            const token = localStorage.getItem('access_token');
            await axios.delete(`http://127.0.0.1:8000/api/services/${course.id}/`, {
                headers: { Authorization: `Bearer ${token}` }
            });
            setCourses(courses.filter(c => c.id !== course.id));
            alert('Cours supprimé.');
        } catch (err) {
            console.error('Erreur suppression cours:', err);
            alert('Impossible de supprimer le cours.');
        }
    };

    const openEditModal = (course) => {
        setEditingCourse(course);
        setNewCourse({
            title: course.title || '',
            price: String(course.price || ''),
            description: course.description || '',
            content_link: course.content_link || '',
            type: course.type || 'course',
        });
        setImageFile(null);
        setImagePreview(getImageUrl(course.image) || null);
        setShowModal(true);
    };

    const openCreateModal = () => {
        setEditingCourse(null);
        setNewCourse({ title: '', price: '', description: '', content_link: '', type: 'course' });
        setImageFile(null);
        setImagePreview(null);
        setShowModal(true);
    };

    const handleImageChange = (e) => {
        const file = e.target.files[0];
        if (file) {
            setImageFile(file);
            setImagePreview(URL.createObjectURL(file));
        }
    };

    const studentCount = new Set(
        orders.flatMap(order =>
            order.items
                .filter(item => item.order_status !== 'pending' && courses.some(course => course.title === item.item_name))
                .map(() => order.customer_name)
        )
    ).size;

    return (
        <div style={{ display: 'flex', backgroundColor: bgLight, minHeight: '100vh' }}>
            <Sidebar />
            <main style={{ marginLeft: '260px', flex: 1, padding: '40px' }}>

                <AppHeader
                    title="Formations"
                    subtitle="Pilotez les cours en ligne et suivez les apprenants"
                    actions={
                        <button
                            onClick={openCreateModal}
                            style={styles.addBtn}
                        >
                            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#fff"
                                strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"
                                style={{ marginRight: '7px' }}>
                                <line x1="12" y1="5" x2="12" y2="19" />
                                <line x1="5" y1="12" x2="19" y2="12" />
                            </svg>
                            Ajouter un cours
                        </button>
                    }
                />

                {/* ── Stats Row ── */}
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, minmax(0, 1fr))', gap: '24px', marginBottom: '40px' }}>
                    <StatCard
                        label="TOTAL COURS"
                        value={courses.length}
                        unit="Cours"
                        color={primaryBlue}
                        icon={
                            <>
                                <path d="M2 3h6a4 4 0 0 1 4 4v14a3 3 0 0 0-3-3H2z" />
                                <path d="M22 3h-6a4 4 0 0 0-4 4v14a3 3 0 0 1 3-3h7z" />
                            </>
                        }
                    />
                    <StatCard
                        label="APPRENANTS"
                        value={studentCount}
                        unit="Inscrits"
                        color="#10B981"
                        icon={
                            <>
                                <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" />
                                <circle cx="9" cy="7" r="4" />
                                <path d="M23 21v-2a4 4 0 0 0-3-3.87" />
                                <path d="M16 3.13a4 4 0 0 1 0 7.75" />
                            </>
                        }
                    />
                </div>

                {/* ── Course Grid ── */}
                <div style={styles.tableCard}>
                    <div style={{ marginBottom: '25px' }}>
                        <h3 style={{ fontSize: '18px', fontWeight: '700', color: '#0F172A', margin: 0 }}>
                            Liste des Cours
                        </h3>
                    </div>

                    {loading ? (
                        <p style={{ textAlign: 'center', color: '#94A3B8', padding: '30px' }}>Chargement des cours...</p>
                    ) : courses.length === 0 ? (
                        <div style={{ textAlign: 'center', padding: '50px 0', color: '#94A3B8' }}>
                            <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="#BFDBFE"
                                strokeWidth="1.2" strokeLinecap="round" strokeLinejoin="round"
                                style={{ marginBottom: '12px' }}>
                                <path d="M2 3h6a4 4 0 0 1 4 4v14a3 3 0 0 0-3-3H2z" />
                                <path d="M22 3h-6a4 4 0 0 0-4 4v14a3 3 0 0 1 3-3h7z" />
                            </svg>
                            <p style={{ fontSize: '14px' }}>Aucun cours disponible.</p>
                        </div>
                    ) : (
                        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(290px, 1fr))', gap: '20px' }}>
                            {courses.map(course => (
                                <div key={course.id} style={styles.courseCard}
                                    onMouseEnter={e => e.currentTarget.style.boxShadow = '0 8px 30px rgba(42,90,241,0.12)'}
                                    onMouseLeave={e => e.currentTarget.style.boxShadow = '0 2px 8px rgba(42,90,241,0.04)'}
                                >
                                    {/* Thumbnail */}
                                    <div style={styles.videoPlaceholder}>
                                        {course.image ? (
                                            <img src={getImageUrl(course.image)} alt={course.title} style={{
                                                width: '100%', height: '100%', objectFit: 'cover'
                                            }} />
                                        ) : (
                                            <div style={styles.playCircle}>
                                                <svg width="22" height="22" viewBox="0 0 24 24" fill="none"
                                                    stroke={primaryBlue} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                                                    <circle cx="12" cy="12" r="10" />
                                                    <polygon points="10 8 16 12 10 16 10 8" fill={primaryBlue} stroke="none" />
                                                </svg>
                                            </div>
                                        )}
                                    </div>

                                    {/* Body */}
                                    <div style={{ padding: '20px' }}>
                                        <h3 style={{ fontSize: '15px', color: '#0F172A', margin: '0 0 12px 0', fontWeight: '700' }}>
                                            {course.title}
                                        </h3>
                                        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '14px', alignItems: 'center' }}>
                                            <span style={styles.priceTag}>{parseFloat(course.price).toFixed(2)} MRU</span>
                                            <div style={{ display: 'flex', alignItems: 'center', gap: '5px', color: '#94A3B8', fontSize: '12px' }}>
                                                <svg width="13" height="13" viewBox="0 0 24 24" fill="none"
                                                    stroke="#94A3B8" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                                                    <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" />
                                                    <circle cx="9" cy="7" r="4" />
                                                    <path d="M23 21v-2a4 4 0 0 0-3-3.87" />
                                                    <path d="M16 3.13a4 4 0 0 1 0 7.75" />
                                                </svg>
                                                {course.student_count ?? 0} Étudiant{course.student_count > 1 ? 's' : ''}
                                            </div>
                                        </div>
                                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', paddingTop: '14px', borderTop: '1px solid #EFF6FF' }}>
                                            <span style={styles.statusBadge}>Publié</span>
                                            <div style={{ display: 'flex', gap: '4px' }}>
                                                <button onClick={() => openEditModal(course)} style={styles.editBtn}>
                                                    <svg width="13" height="13" viewBox="0 0 24 24" fill="none"
                                                        stroke={primaryBlue} strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
                                                        <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7" />
                                                        <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z" />
                                                    </svg>
                                                    Edit
                                                </button>
                                                <button onClick={() => handleDeleteCourse(course)} style={styles.deleteBtn}>
                                                    <svg width="13" height="13" viewBox="0 0 24 24" fill="none"
                                                        stroke="#EF4444" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
                                                        <polyline points="3 6 5 6 21 6" />
                                                        <path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6" />
                                                        <path d="M10 11v6M14 11v6" />
                                                        <path d="M9 6V4a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2" />
                                                    </svg>
                                                    Delete
                                                </button>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            ))}
                        </div>
                    )}
                </div>
            </main>

            {/* ── Modal ── */}
            {showModal && (
                <div style={styles.modalOverlay}>
                    <div style={styles.modalContent}>
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px' }}>
                            <h2 style={{ fontSize: '18px', fontWeight: '800', color: '#0F172A', margin: 0 }}>
                                {editingCourse ? 'Modifier le cours' : 'Nouveau Cours'}
                            </h2>
                            <button onClick={() => { setShowModal(false); setEditingCourse(null); }} style={styles.closeBtn}>
                                <svg width="16" height="16" viewBox="0 0 24 24" fill="none"
                                    stroke="#64748B" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
                                    <line x1="18" y1="6" x2="6" y2="18" />
                                    <line x1="6" y1="6" x2="18" y2="18" />
                                </svg>
                            </button>
                        </div>

                        <form onSubmit={editingCourse ? handleUpdateCourse : handleCreateCourse}>
                            {[
                                { placeholder: 'Titre du cours', type: 'text', key: 'title', required: true },
                                { placeholder: 'Prix (MRU)', type: 'number', key: 'price', required: true },
                                { placeholder: 'Lien de la vidéo (Google Drive / YouTube)', type: 'text', key: 'content_link', required: true },
                            ].map(field => (
                                <div key={field.key} style={{ marginBottom: '14px' }}>
                                    <input
                                        style={styles.input}
                                        type={field.type}
                                        placeholder={field.placeholder}
                                        required={field.required}
                                        value={newCourse[field.key]}
                                        onChange={e => setNewCourse({ ...newCourse, [field.key]: e.target.value })}
                                    />
                                </div>
                            ))}
                            <div style={{ marginBottom: '20px' }}>
                                <textarea
                                    style={{ ...styles.input, height: '90px', resize: 'vertical' }}
                                    placeholder="Description du cours"
                                    value={newCourse.description}
                                    onChange={e => setNewCourse({ ...newCourse, description: e.target.value })}
                                />
                            </div>
                            {/* Image upload */}
                            <div style={{ marginBottom: '20px' }}>
                                <label style={{ display: 'block', fontSize: '13px', color: '#475569', fontWeight: '600', marginBottom: '8px' }}>
                                    Image du cours
                                </label>
                                <div style={{
                                    border: '2px dashed #DBEAFE', borderRadius: '12px', padding: '20px',
                                    textAlign: 'center', cursor: 'pointer', position: 'relative',
                                    backgroundColor: '#FAFCFF', transition: 'border-color 0.2s',
                                }}
                                    onClick={() => document.getElementById('course-image-input').click()}
                                    onMouseEnter={e => e.currentTarget.style.borderColor = '#93C5FD'}
                                    onMouseLeave={e => e.currentTarget.style.borderColor = '#DBEAFE'}
                                >
                                    {imagePreview ? (
                                        <img src={imagePreview} alt="Aperçu" style={{
                                            maxWidth: '100%', maxHeight: '120px', borderRadius: '8px', objectFit: 'cover'
                                        }} />
                                    ) : (
                                        <>
                                            <svg width="32" height="32" viewBox="0 0 24 24" fill="none"
                                                stroke="#94A3B8" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"
                                                style={{ marginBottom: '8px' }}>
                                                <rect x="3" y="3" width="18" height="18" rx="2" ry="2" />
                                                <circle cx="8.5" cy="8.5" r="1.5" />
                                                <polyline points="21 15 16 10 5 21" />
                                            </svg>
                                            <p style={{ fontSize: '12px', color: '#94A3B8', margin: 0 }}>Cliquez pour ajouter une image</p>
                                        </>
                                    )}
                                    <input
                                        id="course-image-input"
                                        type="file"
                                        accept="image/*"
                                        style={{ display: 'none' }}
                                        onChange={handleImageChange}
                                    />
                                </div>
                            </div>
                            <div style={{ display: 'flex', gap: '10px' }}>
                                <button type="submit" style={styles.saveBtn}
                                    onMouseEnter={e => e.currentTarget.style.backgroundColor = '#1E40C8'}
                                    onMouseLeave={e => e.currentTarget.style.backgroundColor = primaryBlue}
                                >
                                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none"
                                        stroke="#fff" strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round"
                                        style={{ marginRight: '6px' }}>
                                        <path d="M20 6L9 17l-5-5" />
                                    </svg>
                                    {editingCourse ? 'Mettre à jour' : 'Enregistrer'}
                                </button>
                                <button type="button" onClick={() => { setShowModal(false); setEditingCourse(null); }} style={styles.cancelBtn}
                                    onMouseEnter={e => e.currentTarget.style.backgroundColor = '#E2E8F0'}
                                    onMouseLeave={e => e.currentTarget.style.backgroundColor = '#F1F5F9'}
                                >
                                    Annuler
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            )}
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
    addBtn: {
        display: 'flex', alignItems: 'center',
        backgroundColor: '#2A5AF1', color: '#fff', border: 'none',
        padding: '10px 20px', borderRadius: '12px', cursor: 'pointer',
        fontWeight: '700', fontSize: '13px', transition: 'background-color 0.2s'
    },
    tableCard: {
        backgroundColor: '#fff', padding: '30px', borderRadius: '24px',
        border: '1px solid #E8EFFF', boxShadow: '0 4px 20px rgba(42,90,241,0.03)',
        marginBottom: '28px'
    },
    refreshBtn: {},
    courseCard: {
        backgroundColor: '#fff', borderRadius: '16px', border: '1px solid #E8EFFF',
        overflow: 'hidden', transition: 'box-shadow 0.25s',
        boxShadow: '0 2px 8px rgba(42,90,241,0.04)'
    },
    videoPlaceholder: {
        height: '150px', backgroundColor: '#EFF6FF',
        display: 'flex', justifyContent: 'center', alignItems: 'center',
        borderBottom: '1px solid #DBEAFE'
    },
    playCircle: {
        width: '52px', height: '52px', borderRadius: '50%', backgroundColor: '#fff',
        display: 'flex', justifyContent: 'center', alignItems: 'center',
        boxShadow: '0 4px 14px rgba(42,90,241,0.15)'
    },
    priceTag: {
        color: '#2A5AF1', fontWeight: '800', fontSize: '15px',
        backgroundColor: '#EFF6FF', padding: '3px 10px', borderRadius: '8px'
    },
    statusBadge: {
        padding: '4px 12px', borderRadius: '20px', fontSize: '11px',
        fontWeight: '700', backgroundColor: '#ECFDF5', color: '#10B981'
    },
    editBtn: {
        display: 'inline-flex', alignItems: 'center', gap: '4px',
        border: 'none', background: 'none', fontSize: '12px',
        cursor: 'pointer', color: '#2A5AF1', fontWeight: '600', padding: '4px 8px',
        borderRadius: '6px', backgroundColor: '#EFF6FF'
    },
    deleteBtn: {
        display: 'inline-flex', alignItems: 'center', gap: '4px',
        border: 'none', background: 'none', fontSize: '12px',
        cursor: 'pointer', color: '#EF4444', fontWeight: '600', padding: '4px 8px',
        borderRadius: '6px', backgroundColor: '#FEF2F2'
    },
    accessSection: {
        backgroundColor: '#fff', padding: '24px', borderRadius: '20px',
        border: '1px solid #E8EFFF', boxShadow: '0 4px 20px rgba(42,90,241,0.03)'
    },
    modalOverlay: {
        position: 'fixed', top: 0, left: 0, width: '100%', height: '100%',
        backgroundColor: 'rgba(15,23,42,0.45)', display: 'flex',
        justifyContent: 'center', alignItems: 'center', zIndex: 1000,
        backdropFilter: 'blur(4px)'
    },
    modalContent: {
        backgroundColor: '#fff', padding: '32px', borderRadius: '20px',
        width: '420px', boxShadow: '0 20px 60px rgba(42,90,241,0.15)',
        border: '1px solid #E8EFFF'
    },
    closeBtn: {
        background: '#F1F5F9', border: 'none', borderRadius: '8px',
        padding: '6px', cursor: 'pointer', display: 'flex', alignItems: 'center'
    },
    input: {
        width: '100%', padding: '11px 14px', borderRadius: '10px',
        border: '1px solid #DBEAFE', outline: 'none', fontSize: '14px',
        color: '#0F172A', backgroundColor: '#FAFCFF',
        boxSizing: 'border-box', fontFamily: 'inherit'
    },
    saveBtn: {
        flex: 1, display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
        backgroundColor: '#2A5AF1', color: '#fff', border: 'none',
        padding: '12px', borderRadius: '10px', cursor: 'pointer',
        fontWeight: '700', fontSize: '14px', transition: 'background-color 0.2s'
    },
    cancelBtn: {
        flex: 1, backgroundColor: '#F1F5F9', color: '#64748B', border: 'none',
        padding: '12px', borderRadius: '10px', cursor: 'pointer',
        fontWeight: '600', fontSize: '14px', transition: 'background-color 0.2s'
    }
};

export default LMS;
