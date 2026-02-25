import React, { useEffect, useState } from 'react';
import { Button, Modal } from 'react-bootstrap';
import api from '../../api';
import './AdminTables.css';

function ManageUser() {
  const [users, setUsers] = useState([]);
  const [selectedUser, setSelectedUser] = useState(null);
  const [showModal, setShowModal] = useState(false);

  const getdetails = async () => {
    try {
      const res = await api.get('/user/getdetails');
      setUsers(res.data.users || []);
    } catch (e) {
      console.log(e);
    }
  };

  const toggleStatus = async (id, status) => {
    try {
      await api.put(`/user/block/user/${id}`, { status });
      getdetails();
    } catch (e) {
      console.log(e);
    }
  };

  const handleView = async (id) => {
    try {
      const res = await api.get(`/user/${id}`);
      console.log(res);

      setSelectedUser(res.data);
      setShowModal(true);
    } catch (e) {
      console.log(e);
    }
  };

  useEffect(() => {
    getdetails();
  }, []);

  return (
    <div className="admin-page-container">
      <div className="page-header-flex">
        <h1 className="page-title">
          <span>👥</span> Registered Users
        </h1>
      </div>

      <div className="table-container-premium">
        <table className="premium-table">
          <thead>
            <tr>
              <th>SI NO</th>
              <th>Name</th>
              <th>Username</th>
              <th>Phone Number</th>
              <th>Status</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {users.length === 0 ? (
              <tr>
                <td colSpan={6} style={{ textAlign: 'center', padding: '40px', color: '#636e72' }}>
                  No Users found yet.
                </td>
              </tr>
            ) : (
              users.map((user, i) => (
                <tr key={user._id}>
                  <td>{String(i + 1).padStart(2, '0')}</td>
                  <td style={{ fontWeight: '600' }}>{user.name}</td>
                  <td style={{ color: '#636e72' }}>{user.email}</td>
                  <td>{user.phone_Number}</td>
                  <td>
                    <span className={`status-pill ${user.common_Key?.verify ? 'status-unblocked' : 'status-blocked'}`}>
                      {user.common_Key?.verify ? 'Active' : 'Blocked'}
                    </span>
                  </td>
                  <td>
                    <div style={{ display: 'flex', gap: '8px' }}>
                      <button className="btn-premium-view" onClick={() => handleView(user._id)}>
                        View
                      </button>
                      {user.common_Key?.verify ? (
                        <button className="btn-premium-block" onClick={() => toggleStatus(user.common_Key?._id, false)}>
                          Block
                        </button>
                      ) : (
                        <button className="btn-premium-unblock" onClick={() => toggleStatus(user.common_Key?._id, true)}>
                          Unblock
                        </button>
                      )}
                    </div>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      <Modal show={showModal} onHide={() => setShowModal(false)} centered className="premium-modal">
        <Modal.Header closeButton>
          <Modal.Title>User Profile Details</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          {selectedUser ? (
            <div className="modal-details">
              <div className="detail-row">
                <span className="detail-label">Full Name</span>
                <span className="detail-value">{selectedUser.name}</span>
              </div>
              <div className="detail-row">
                <span className="detail-label">Email Address</span>
                <span className="detail-value">{selectedUser.email}</span>
              </div>
              <div className="detail-row">
                <span className="detail-label">Phone Number</span>
                <span className="detail-value">{selectedUser.phone_Number}</span>
              </div>
              <div className="detail-row">
                <span className="detail-label">City/Place</span>
                <span className="detail-value">{selectedUser.place || 'Not provided'}</span>
              </div>
              <div className="detail-row">
                <span className="detail-label">Account Status</span>
                <span className={`status-pill ${selectedUser.common_Key?.verify ? 'status-unblocked' : 'status-blocked'}`}>
                  {selectedUser.common_Key?.verify ? 'Active' : 'Blocked'}
                </span>
              </div>
            </div>
          ) : (
            <div style={{ textAlign: 'center', padding: '20px' }}>Loading...</div>
          )}
        </Modal.Body>
      </Modal>
    </div>
  );
}

export default ManageUser;

