import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import axios from 'axios'; // Configure global axios settings.

// Pages
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import TopUp from './pages/TopUp'; 
import LMS from './pages/LMS';
import Finance from './pages/Finance'; 
import Users from './pages/Users';
import Orders from './pages/Orders'; 
import Delivery from './pages/Delivery';
import Shops from './pages/Shops';

// Security components
import ProtectedRoute from './components/ProtectedRoute';

// Enable credentials globally for API requests.
// React will send secure cookies with each request when the backend uses them.
axios.defaults.withCredentials = true;

function App() {
    return (
        <Router>
            <Routes>
                {/* Public login page */}
                <Route path="/" element={<Login />} />

                {/* Protected routes */}
                <Route 
                    path="/dashboard" 
                    element={<ProtectedRoute><Dashboard /></ProtectedRoute>} 
                />

                <Route 
                    path="/topup" 
                    element={<ProtectedRoute><TopUp /></ProtectedRoute>} 
                />

                <Route 
                    path="/lms" 
                    element={<ProtectedRoute><LMS /></ProtectedRoute>} 
                />

                <Route 
                    path="/finance" 
                    element={<ProtectedRoute><Finance /></ProtectedRoute>} 
                />

                <Route 
                    path="/shops" 
                    element={<ProtectedRoute><Shops /></ProtectedRoute>} 
                />

                <Route 
                    path="/users" 
                    element={<ProtectedRoute><Users /></ProtectedRoute>} 
                />

                <Route 
                    path="/orders" 
                    element={<ProtectedRoute><Orders /></ProtectedRoute>} 
                />

                <Route 
                    path="/delivery" 
                    element={<ProtectedRoute><Delivery /></ProtectedRoute>} 
                />

                {/* legacy frontend routes restored - custom pages removed */}
            </Routes>
        </Router>
    );
}

export default App;
