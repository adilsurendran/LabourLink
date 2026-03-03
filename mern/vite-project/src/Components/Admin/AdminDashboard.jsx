import React, { useState } from 'react';
import { NavLink, Outlet, useNavigate } from 'react-router-dom';
import './AdminDashboard.css';

const AdminDashboard = () => {
    const navigate = useNavigate();
    const [isCollapsed, setIsCollapsed] = useState(false);

    const handleLogout = () => {
        localStorage.removeItem("adminToken");
        alert("Logged out successfully");
        navigate('/');
    };

    const toggleSidebar = () => {
        setIsCollapsed(!isCollapsed);
    };

    return (
        <div className={`admin-layout ${isCollapsed ? 'sidebar-collapsed' : ''}`}>
            {/* Sidebar */}
            <aside className={`admin-sidebar ${isCollapsed ? 'collapsed' : ''}`}>
                <div className="sidebar-header">
                    <div className="sidebar-brand">
                        <div className="brand-logo">
                            <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><path d="M12 2L2 7l10 5 10-5-10-5z"></path><path d="M2 17l10 5 10-5"></path><path d="M2 12l10 5 10-5"></path></svg>
                        </div>
                        {!isCollapsed && <h2 className="brand-name">LabourLink</h2>}
                    </div>
                    <button className="sidebar-toggle-btn" onClick={toggleSidebar}>
                        {isCollapsed ? '❯' : '❮'}
                    </button>
                </div>

                <nav className="sidebar-nav">
                    <NavLink to="/Admin/Dashboard" end className={({ isActive }) => isActive ? "nav-link active" : "nav-link"}>
                        <span className="nav-icon">📊</span>
                        {!isCollapsed && <span className="nav-text">Dashboard</span>}
                    </NavLink>
                    <NavLink to="/Admin/ManageWorker" className={({ isActive }) => isActive ? "nav-link active" : "nav-link"}>
                        <span className="nav-icon">👷</span>
                        {!isCollapsed && <span className="nav-text">Manage Workers</span>}
                    </NavLink>
                    <NavLink to="/Admin/ManageUser" className={({ isActive }) => isActive ? "nav-link active" : "nav-link"}>
                        <span className="nav-icon">👥</span>
                        {!isCollapsed && <span className="nav-text">Manage Users</span>}
                    </NavLink>
                    <NavLink to="/Admin/UserRequests" className={({ isActive }) => isActive ? "nav-link active" : "nav-link"}>
                        <span className="nav-icon">📝</span>
                        {!isCollapsed && <span className="nav-text">User Requests</span>}
                    </NavLink>
                    <NavLink to="/Admin/JobRequests" className={({ isActive }) => isActive ? "nav-link active" : "nav-link"}>
                        <span className="nav-icon">💼</span>
                        {!isCollapsed && <span className="nav-text">Job Requests</span>}
                    </NavLink>
                    <NavLink to="/Admin/Complaint" className={({ isActive }) => isActive ? "nav-link active" : "nav-link"}>
                        <span className="nav-icon">⚠️</span>
                        {!isCollapsed && <span className="nav-text">Complaints</span>}
                    </NavLink>
                    <NavLink to="/Admin/Feedback" className={({ isActive }) => isActive ? "nav-link active" : "nav-link"}>
                        <span className="nav-icon">💬</span>
                        {!isCollapsed && <span className="nav-text">Feedback</span>}
                    </NavLink>
                    <NavLink to="/Admin/FlaggedReviews" className={({ isActive }) => isActive ? "nav-link active" : "nav-link"}>
                        <span className="nav-icon">🚩</span>
                        {!isCollapsed && <span className="nav-text">Flagged Reviews</span>}
                    </NavLink>
                </nav>

                <div className="sidebar-logout">
                    <button className="logout-btn-sidebar" onClick={handleLogout}>
                        <span className="logout-icon"><i class="fa-solid fa-arrow-right-from-bracket"></i></span>
                        {!isCollapsed && <span className="logout-text">Logout</span>}
                    </button>
                </div>
            </aside>

            {/* Main Content Area */}
            <main className="admin-main">
                <header className="admin-topbar">
                    <div className="topbar-welcome">
                        <h3>Welcome, Administrator</h3>
                        <p>Managing LabourLink Platform</p>
                    </div>
                    <div className="topbar-actions">
                        <button className="logout-btn-top" onClick={handleLogout}>Logout</button>
                    </div>
                </header>

                <div className="admin-content-render">
                    <Outlet />
                </div>
            </main>
        </div>
    );
};

export default AdminDashboard;
