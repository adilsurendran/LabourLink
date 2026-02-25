import React, { useEffect, useState } from 'react';
import api from '../../api';
import './AdminRequests.css';

const AdminUserRequests = () => {
    const [requests, setRequests] = useState([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        fetchUserRequests();
    }, []);

    const fetchUserRequests = async () => {
        try {
            const res = await api.get('/admin/get-user-requests');
            if (res.data.success) {
                setRequests(res.data.data);
            }
        } catch (error) {
            console.error("Error fetching user requests:", error);
        } finally {
            setLoading(false);
        }
    };

    if (loading) {
        return (
            <div className="admin-page-container" style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '60vh' }}>
                <div style={{ textAlign: 'center' }}>
                    <div className="brand-logo" style={{ marginBottom: '20px', animation: 'pulse 1.5s infinite ease-in-out' }}>
                        <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="#4A00E0" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M12 2L2 7l10 5 10-5-10-5z"></path><path d="M2 17l10 5 10-5"></path><path d="M2 12l10 5 10-5"></path></svg>
                    </div>
                    <h3 style={{ color: 'var(--primary)', fontWeight: '600' }}>Fetching User Requests...</h3>
                    <p style={{ color: 'var(--text-muted)' }}>Please wait a moment</p>
                </div>
            </div>
        );
    }

    return (
        <div className="admin-page-container">
            <div className="page-header-flex">
                <h1 className="page-title">
                    <span>📝</span> User Direct Requests
                </h1>
                <p style={{ color: 'var(--text-muted)', fontSize: '14px', marginTop: '-20px', marginBottom: '25px', display: 'block' }}>
                    Monitor and manage direct work requests from users to workers
                </p>
            </div>

            <div className="requests-grid">
                {requests.length === 0 ? (
                    <div className="no-requests" style={{ textAlign: 'center', padding: '100px', background: 'white', borderRadius: '20px', width: '100%', gridColumn: '1 / -1' }}>
                        <span style={{ fontSize: '50px' }}>📁</span>
                        <p style={{ marginTop: '20px', color: '#636e72' }}>No user requests found.</p>
                    </div>
                ) : (
                    requests.map((request) => (
                        <div key={request._id} className="request-card">
                            <div className="card-header">
                                <span className="job-type">{request.jobType}</span>
                                <span className={`status-badge status-${request.status}`}>
                                    {request.status}
                                </span>
                            </div>

                            <div className="card-body">
                                <div className="info-item">
                                    <div>
                                        <span className="info-label">Requested By</span>
                                        <span className="info-value">
                                            {request.userId?.name || 'Unknown User'} ({request.userId?.email || 'N/A'})
                                        </span>
                                    </div>
                                </div>

                                <div className="info-item">
                                    <div>
                                        <span className="info-label">Assigned To</span>
                                        <span className="info-value">
                                            {request.workerId?.name || 'Unknown Worker'} ({request.workerId?.email || 'N/A'})
                                        </span>
                                    </div>
                                </div>

                                <div className="info-item">
                                    <div>
                                        <span className="info-label">Location & Date</span>
                                        <span className="info-value">
                                            {request.place} | {request.date} at {request.startTime}
                                        </span>
                                    </div>
                                </div>

                                {request.description && (
                                    <div className="info-item">
                                        <div>
                                            <span className="info-label">Description</span>
                                            <span className="info-value">{request.description}</span>
                                        </div>
                                    </div>
                                )}
                            </div>

                            <div className="request-card-footer">
                                <span>Request ID: ...{request._id.substring(request._id.length - 8)}</span>
                                <span>Created: {new Date(request.createdAt).toLocaleDateString()}</span>
                            </div>
                        </div>
                    ))
                )}
            </div>
        </div>
    );
};

export default AdminUserRequests;
