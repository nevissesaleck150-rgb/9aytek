import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';

const primaryBlue = '#2A5AF1';
const API_BASE = 'http://127.0.0.1:8000/api';

const AppHeader = ({ title, subtitle, actions }) => {
    const navigate = useNavigate();
    const username = localStorage.getItem('username') || 'Admin';
    const [notifications, setNotifications] = useState([]);
    const [showNotifications, setShowNotifications] = useState(false);
    const [loadingNotifications, setLoadingNotifications] = useState(false);

    const token = useMemo(() => localStorage.getItem('access_token'), []);

    const cleanText = useCallback((value) => {
        const text = `${value || ''}`.trim();
        return text === 'null' ? '' : text;
    }, []);

    const joinInfo = useCallback(
        (parts) => parts.map(cleanText).filter(Boolean).join(' - '),
        [cleanText]
    );

    const labeled = useCallback(
        (label, value) => {
            const text = cleanText(value);
            return text ? `${label}: ${text}` : '';
        },
        [cleanText]
    );

    const loadNotifications = useCallback(async () => {
        if (!token) return;

        setLoadingNotifications(true);
        try {
            const headers = { Authorization: `Bearer ${token}` };
            const [usersRes, productsRes, topupsRes] = await Promise.all([
                axios.get(`${API_BASE}/users/`, { headers }),
                axios.get(`${API_BASE}/products/`, { headers }),
                axios.get(`${API_BASE}/services/topup_requests/`, { headers })
            ]);

            const users = Array.isArray(usersRes.data) ? usersRes.data : usersRes.data?.results || [];
            const products = Array.isArray(productsRes.data) ? productsRes.data : productsRes.data?.results || [];
            const topups = Array.isArray(topupsRes.data) ? topupsRes.data : topupsRes.data?.results || [];

            const next = [];

            users
                .filter((user) => user.is_approved !== true)
                .forEach((user) => {
                    next.push({
                        id: `user-${user.id}`,
                        icon: 'U',
                        title: 'Compte a verifier',
                        body: joinInfo([
                            joinInfo([user.first_name, user.last_name]) || user.username,
                            user.role,
                            user.email
                        ]),
                        navigateTo: '/users'
                    });
                });

            products
                .filter((product) => product.is_approved !== true)
                .forEach((product) => {
                    next.push({
                        id: `product-${product.id}`,
                        icon: 'P',
                        title: 'Produit a approuver',
                        body: joinInfo([
                            product.name,
                            labeled('Boutique', product.vendor_name || product.shop_name || product.vendor)
                        ]),
                        navigateTo: '/dashboard'
                    });
                });

            topups
                .filter((request) => cleanText(request.order_status).toLowerCase() !== 'delivered')
                .forEach((request) => {
                    next.push({
                        id: `topup-${request.id || request.order_id}`,
                        icon: 'R',
                        title: 'Recharge a completer',
                        body: joinInfo([
                            request.item_name || request.digital_service_title || request.service_title || request.title,
                            labeled('ID', request.topup_account_id),
                            labeled('Payer', request.topup_payer)
                        ]),
                        navigateTo: '/topup'
                    });
                });

            setNotifications(next);
        } catch (err) {
            console.error('Erreur notifications:', err);
        } finally {
            setLoadingNotifications(false);
        }
    }, [cleanText, joinInfo, labeled, token]);

    useEffect(() => {
        loadNotifications();
        const timer = setInterval(loadNotifications, 60000);
        return () => clearInterval(timer);
    }, [loadNotifications]);

    return (
        <div style={styles.headerContainer}>
            <div>
                <div style={styles.welcomeRow}>
                    <div style={styles.brandAvatar}>
                        <span style={styles.brandInitial}>9</span>
                    </div>
                    <div>
                        <p style={styles.welcomeText}>Bienvenue, {username}</p>
                        <h1 style={styles.title}>{title}</h1>
                        <p style={styles.subtitle}>{subtitle}</p>
                    </div>
                </div>
            </div>
            <div style={styles.actionsRow}>
                {actions}
                <button
                    style={styles.notificationBtn}
                    aria-label="Notifications"
                    onClick={() => {
                        setShowNotifications((current) => !current);
                        loadNotifications();
                    }}
                >
                    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke={primaryBlue} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                        <path d="M18 8a6 6 0 0 0-12 0c0 7-3 9-3 9h18s-3-2-3-9" />
                        <path d="M13.73 21a2 2 0 0 1-3.46 0" />
                    </svg>
                    {notifications.length > 0 && (
                        <span style={styles.notificationBadge}>{notifications.length}</span>
                    )}
                </button>
                {showNotifications && (
                    <div style={styles.notificationPanel}>
                        <div style={styles.notificationPanelHeader}>
                            <strong>Notifications</strong>
                            <button style={styles.refreshBtn} onClick={loadNotifications}>
                                {loadingNotifications ? '...' : 'Actualiser'}
                            </button>
                        </div>
                        {notifications.length === 0 ? (
                            <div style={styles.emptyNotification}>
                                Aucune notification pour le moment
                            </div>
                        ) : (
                            <div style={styles.notificationList}>
                                {notifications.map((item) => (
                                    <div
                                        key={item.id}
                                        style={{ ...styles.notificationItem, cursor: item.navigateTo ? 'pointer' : 'default' }}
                                        onClick={() => {
                                            if (item.navigateTo) {
                                                setShowNotifications(false);
                                                navigate(item.navigateTo);
                                            }
                                        }}
                                    >
                                        <span style={styles.notificationIcon}>{item.icon}</span>
                                        <div>
                                            <div style={styles.notificationTitle}>{item.title}</div>
                                            <div style={styles.notificationBody}>
                                                {item.body || 'Nouvelle demande en attente'}
                                            </div>
                                        </div>
                                    </div>
                                ))}
                            </div>
                        )}
                    </div>
                )}
            </div>
        </div>
    );
};

const styles = {
    headerContainer: {
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'flex-start',
        gap: '18px',
        marginBottom: '40px',
        flexWrap: 'wrap'
    },
    welcomeRow: {
        display: 'flex',
        alignItems: 'center',
        gap: '18px'
    },
    brandAvatar: {
        width: '54px',
        height: '54px',
        borderRadius: '18px',
        backgroundColor: '#EFF6FF',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center'
    },
    brandInitial: {
        color: primaryBlue,
        fontSize: '20px',
        fontWeight: '900'
    },
    welcomeText: {
        margin: 0,
        color: '#64748B',
        fontSize: '13px',
        fontWeight: '600'
    },
    title: {
        margin: '6px 0 6px',
        color: '#0F172A',
        fontSize: '30px',
        lineHeight: '1.05',
        fontWeight: '800'
    },
    subtitle: {
        margin: 0,
        color: '#64748B',
        fontSize: '14px'
    },
    actionsRow: {
        position: 'relative',
        display: 'flex',
        alignItems: 'center',
        gap: '14px',
        flexWrap: 'wrap'
    },
    notificationBtn: {
        position: 'relative',
        width: '48px',
        height: '48px',
        borderRadius: '16px',
        border: '1px solid #E2E8F0',
        backgroundColor: '#FFFFFF',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        cursor: 'pointer'
    },
    notificationBadge: {
        position: 'absolute',
        top: '-6px',
        right: '-6px',
        minWidth: '22px',
        height: '22px',
        padding: '0 6px',
        borderRadius: '999px',
        backgroundColor: '#DC2626',
        color: '#FFFFFF',
        fontSize: '12px',
        fontWeight: '800',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        border: '2px solid #FFFFFF'
    },
    notificationPanel: {
        position: 'absolute',
        top: '58px',
        right: 0,
        width: '360px',
        maxWidth: 'calc(100vw - 32px)',
        backgroundColor: '#FFFFFF',
        border: '1px solid #E2E8F0',
        borderRadius: '18px',
        boxShadow: '0 22px 45px rgba(15, 23, 42, 0.14)',
        zIndex: 20,
        overflow: 'hidden'
    },
    notificationPanelHeader: {
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        padding: '14px 16px',
        color: '#0F172A',
        borderBottom: '1px solid #E2E8F0'
    },
    refreshBtn: {
        border: 'none',
        backgroundColor: '#EFF6FF',
        color: primaryBlue,
        borderRadius: '10px',
        padding: '7px 10px',
        fontWeight: '800',
        cursor: 'pointer'
    },
    notificationList: {
        maxHeight: '380px',
        overflowY: 'auto',
        padding: '10px'
    },
    notificationItem: {
        display: 'flex',
        gap: '12px',
        padding: '12px',
        borderRadius: '14px',
        backgroundColor: '#F8FAFF',
        border: '1px solid #EAF0FF',
        marginBottom: '10px'
    },
    notificationIcon: {
        width: '34px',
        height: '34px',
        borderRadius: '12px',
        backgroundColor: '#FFFFFF',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        flexShrink: 0
    },
    notificationTitle: {
        color: '#0F172A',
        fontWeight: '800',
        fontSize: '14px',
        marginBottom: '4px'
    },
    notificationBody: {
        color: '#111827',
        fontSize: '13px',
        lineHeight: 1.45
    },
    emptyNotification: {
        padding: '28px 16px',
        color: '#111827',
        fontWeight: '700',
        textAlign: 'center'
    },

};

export default AppHeader;
