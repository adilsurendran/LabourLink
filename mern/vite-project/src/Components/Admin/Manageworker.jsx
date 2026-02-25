import React, { useEffect, useState } from 'react';
import { Button, Modal } from 'react-bootstrap';
import api from '../../api';
import './AdminTables.css';

function Manageworker() {
  const [workers, setWorkers] = useState([]);
  const [selectedWorker, setSelectedWorker] = useState(null);
  const [showModal, setShowModal] = useState(false);

  const getdetails = async () => {
    try {
      const res = await api.get('/worker/getdetails');
      setWorkers(res.data.workers || []);
    } catch (e) {
      console.log(e);
    }
  };

  const toggleStatus = async (id, status) => {
    try {
      await api.put(`/worker/block/worker/${id}`, { status });
      getdetails();
    } catch (e) {
      console.log(e);
    }
  };

  const handleView = async (id) => {
    try {
      const res = await api.get(`/worker/${id}`);
      setSelectedWorker(res.data.worker);
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
          <span>👷</span> Worker Registrations
        </h1>
      </div>

      <div className="table-container-premium">
        <table className="premium-table">
          <thead>
            <tr>
              <th>SI NO</th>
              <th>Name</th>
              <th>Email</th>
              <th>Skills</th>
              <th>Wage/Day</th>
              <th>Status</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {workers.length === 0 ? (
              <tr>
                <td colSpan={7} style={{ textAlign: 'center', padding: '40px', color: '#636e72' }}>
                  No Workers registered yet.
                </td>
              </tr>
            ) : (
              workers.map((worker, i) => (
                <tr key={worker._id}>
                  <td>{String(i + 1).padStart(2, '0')}</td>
                  <td style={{ fontWeight: '600' }}>{worker.name}</td>
                  <td style={{ color: '#636e72' }}>{worker.email}</td>
                  <td>
                    <div className="skills-list">
                      {Array.isArray(worker.skills) && worker.skills.length > 0 ? (
                        worker.skills.slice(0, 2).map((skill, index) => (
                          <span key={index} className="skill-tag">{skill}</span>
                        ))
                      ) : (
                        <span style={{ color: '#b2bec3' }}>No skills listed</span>
                      )}
                      {Array.isArray(worker.skills) && worker.skills.length > 2 && (
                        <span className="skill-tag">+{worker.skills.length - 2} more</span>
                      )}
                    </div>
                  </td>
                  <td style={{ fontWeight: '600', color: '#4A00E0' }}>₹{worker.wage}</td>
                  <td>
                    <span className={`status-pill ${worker.common_Key?.verify ? 'status-unblocked' : 'status-blocked'}`}>
                      {worker.common_Key?.verify ? 'Active' : 'Blocked'}
                    </span>
                  </td>
                  <td>
                    <div style={{ display: 'flex', gap: '8px' }}>
                      <button className="btn-premium-view" onClick={() => handleView(worker._id)}>
                        View
                      </button>
                      {worker.common_Key?.verify ? (
                        <button className="btn-premium-block" onClick={() => toggleStatus(worker.common_Key?._id, false)}>
                          Block
                        </button>
                      ) : (
                        <button className="btn-premium-unblock" onClick={() => toggleStatus(worker.common_Key?._id, true)}>
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
          <Modal.Title>Worker Profile Details</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          {selectedWorker ? (
            <div className="modal-details">
              <div className="detail-row">
                <span className="detail-label">Full Name</span>
                <span className="detail-value">{selectedWorker.name}</span>
              </div>
              <div className="detail-row">
                <span className="detail-label">Email Address</span>
                <span className="detail-value">{selectedWorker.email}</span>
              </div>
              <div className="detail-row">
                <span className="detail-label">Phone Number</span>
                <span className="detail-value">{selectedWorker.phone_number}</span>
              </div>
              <div className="detail-row">
                <span className="detail-label">Date of Birth</span>
                <span className="detail-value">{selectedWorker.dob}</span>
              </div>
              <div className="detail-row">
                <span className="detail-label">Daily Wage</span>
                <span className="detail-value" style={{ color: '#4A00E0' }}>₹{selectedWorker.wage}</span>
              </div>
              <div className="detail-row" style={{ flexDirection: 'column', alignItems: 'flex-start', borderBottom: 'none' }}>
                <span className="detail-label" style={{ marginBottom: '10px' }}>Skills & Expertise</span>
                <div className="skills-list">
                  {Array.isArray(selectedWorker.skills) ? (
                    selectedWorker.skills.map((skill, index) => (
                      <span key={index} className="skill-tag" style={{ padding: '6px 12px' }}>{skill}</span>
                    ))
                  ) : (
                    <span className="detail-value">No skills listed</span>
                  )}
                </div>
              </div>
              <div className="detail-row" style={{ marginTop: '20px' }}>
                <span className="detail-label">Account Status</span>
                <span className={`status-pill ${selectedWorker.common_Key?.verify ? 'status-unblocked' : 'status-blocked'}`}>
                  {selectedWorker.common_Key?.verify ? 'Active' : 'Blocked'}
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

export default Manageworker;
