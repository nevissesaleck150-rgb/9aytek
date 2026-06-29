import React from 'react';
import { Navigate } from 'react-router-dom';

const ProtectedRoute = ({ children }) => {
    // Check the real token in localStorage.
    const token = localStorage.getItem('access_token');
    const isLoggedIn = localStorage.getItem('is_logged_in') === 'true';

    // Require both flags for a safer session check.
    if (!token || !isLoggedIn) {
        // Clear stale session data and redirect to login.
        localStorage.removeItem('is_logged_in');
        localStorage.removeItem('access_token');
        return <Navigate to="/" replace />;
    }

    // Session is valid; allow access.
    return children;
};

export default ProtectedRoute;
