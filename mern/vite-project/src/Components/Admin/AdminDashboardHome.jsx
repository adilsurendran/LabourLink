import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import api from '../../api';
import './AdminDashboard.css';

const AdminDashboardHome = () => {
    const [stats, setStats] = useState({
        pendingComplaints: 0,
        totalFeedback: 0,
        totalUsers: 0,
        totalWorkers: 0
    });
    const [loading, setLoading] = useState(true);
    const navigate = useNavigate();

    useEffect(() => {
        fetchStats();
    }, []);

    const fetchStats = async () => {
        try {
            const res = await api.get('/admin/get-stats');
            if (res.data.success) {
                setStats(res.data.data);
            }
        } catch (error) {
            console.error("Error fetching admin stats:", error);
        } finally {
            setLoading(false);
        }
    };

    const navItems = [
        { title: 'Manage Workers', desc: 'Verify and manage labout registrations', path: '/Admin/ManageWorker', icon: '👷' },
        { title: 'Manage Users', desc: 'View and manage registered employers', path: '/Admin/ManageUser', icon: '👥' },
        { title: 'User Requests', desc: 'Direct hire requests tracking', path: '/Admin/UserRequests', icon: '📝' },
        { title: 'Job Requests', desc: 'Public job application monitoring', path: '/Admin/JobRequests', icon: '💼' },
        { title: 'Complaints', desc: 'Resolve platform disputes', path: '/Admin/Complaint', icon: '⚠️' },
        { title: 'Feedback', desc: 'View user and worker opinions', path: '/Admin/Feedback', icon: '💬' },
    ];

    if (loading) {
        return <div className="loading-stats">Updating Dashboard...</div>;
    }

    return (
        <div className="dashboard-home">
            {/* Live Stats Cards */}
            <div className="stats-grid">
                <div className="stat-card">
                    <div className="stat-icon" style={{ color: '#f08c00', background: '#fff4e6' }}>⚠️</div>
                    <div className="stat-info">
                        <span className="stat-label">Pending Complaints</span>
                        <h2 className="stat-value">{stats.pendingComplaints}</h2>
                    </div>
                </div>
                <div className="stat-card">
                    <div className="stat-icon" style={{ color: '#228be6', background: '#e7f5ff' }}>💬</div>
                    <div className="stat-info">
                        <span className="stat-label">Total Feedback</span>
                        <h2 className="stat-value">{stats.totalFeedback}</h2>
                    </div>
                </div>
                <div className="stat-card">
                    <div className="stat-icon" style={{ color: '#40c057', background: '#ebfbee' }}>👥</div>
                    <div className="stat-info">
                        <span className="stat-label">Total Users</span>
                        <h2 className="stat-value">{stats.totalUsers}</h2>
                    </div>
                </div>
                <div className="stat-card">
                    <div className="stat-icon" style={{ color: '#be4bdb', background: '#f8f0fc' }}>👷</div>
                    <div className="stat-info">
                        <span className="stat-label">Total Workers</span>
                        <h2 className="stat-value">{stats.totalWorkers}</h2>
                    </div>
                </div>
            </div>

            {/* Navigation Cards */}
            <h3 className="section-title">Quick Navigation</h3>
            <div className="nav-grid-dashboard">
                {navItems.map((item, index) => (
                    <div key={index} className="nav-card-premium" onClick={() => navigate(item.path)}>
                        <div className="nav-card-icon">{item.icon}</div>
                        <h4>{item.title}</h4>
                        <p>{item.desc}</p>
                    </div>
                ))}
            </div>
        </div>
    );
};

export default AdminDashboardHome;
