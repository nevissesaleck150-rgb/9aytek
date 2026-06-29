import React from 'react';
import { Navigate } from 'react-router-dom';

const ProtectedRoute = ({ children }) => {
    // Check for an access token in browser storage.
    const token = localStorage.getItem('access_token');

    if (!token) {
        // Redirect immediately to login when no token exists.
        return <Navigate to="/" replace />;
    }

    // Token exists; allow access to the dashboard content.
    return children;
};

export default ProtectedRoute;
