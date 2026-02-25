import { useEffect, useState } from "react";
import { Modal, Form } from "react-bootstrap";
import api from "../../api";
import "./AdminTables.css";

const AdminComplaints = () => {
  const [complaints, setComplaints] = useState([]);
  const [filter, setFilter] = useState("pending");
  const [showModal, setShowModal] = useState(false);
  const [selectedId, setSelectedId] = useState(null);
  const [replyText, setReplyText] = useState("");

  const fetchComplaints = async () => {
    try {
      const res = await api.get(`admin/getcomplaint?status=${filter}`);
      setComplaints(res.data.data);
    } catch (error) {
      console.error(error);
    }
  };

  useEffect(() => {
    fetchComplaints();
  }, [filter]);

  const openReplyModal = (id) => {
    setSelectedId(id);
    setReplyText("");
    setShowModal(true);
  };

  const submitReply = async () => {
    try {
      await api.put(`/admin/reply/${selectedId}`, { reply: replyText });
      setShowModal(false);
      fetchComplaints();
    } catch (error) {
      console.error(error);
    }
  };

  return (
    <div className="admin-page-container">
      <div className="page-header-flex" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '25px' }}>
        <h1 className="page-title" style={{ margin: 0 }}>
          <span>⚠️</span> User Complaints
        </h1>
        <div className="filter-wrapper">
          <Form.Select
            className="premium-select"
            value={filter}
            onChange={(e) => setFilter(e.target.value)}
            style={{
              width: "180px",
              borderRadius: '10px',
              border: '1px solid rgba(74, 0, 224, 0.2)',
              padding: '8px 12px',
              fontSize: '14px',
              fontWeight: '500',
              color: '#4A00E0'
            }}
          >
            <option value="pending">Pending Only</option>
            <option value="all">View All</option>
          </Form.Select>
        </div>
      </div>

      <div className="table-container-premium">
        <table className="premium-table">
          <thead>
            <tr>
              <th>User</th>
              <th>Worker</th>
              <th>Work Post</th>
              <th>Complaint Details</th>
              <th>Status</th>
              <th>Admin Reply</th>
              <th>Action</th>
            </tr>
          </thead>
          <tbody>
            {complaints.length === 0 ? (
              <tr>
                <td colSpan={7} style={{ textAlign: 'center', padding: '40px', color: '#636e72' }}>
                  No complaints found for this filter.
                </td>
              </tr>
            ) : (
              complaints.map((c) => (
                <tr key={c._id}>
                  <td style={{ fontWeight: '600' }}>{c.userId?.name}</td>
                  <td>{c.workerId?.name}</td>
                  <td>{c.workId?.title}</td>
                  <td style={{ maxWidth: '250px', fontSize: '13px', color: '#636e72' }}>{c.complaint}</td>
                  <td>
                    <span className={`status-pill ${c.status === "pending" ? 'status-blocked' : 'status-unblocked'}`}>
                      {c.status.toUpperCase()}
                    </span>
                  </td>
                  <td style={{ fontStyle: c.reply ? 'normal' : 'italic', color: c.reply ? '#2d3436' : '#b2bec3' }}>
                    {c.reply || "No reply yet"}
                  </td>
                  <td>
                    {c.status === "pending" ? (
                      <button className="btn-premium-view" onClick={() => openReplyModal(c._id)}>
                        Reply
                      </button>
                    ) : (
                      <span style={{ color: '#40c057', fontSize: '12px', fontWeight: 'bold' }}>RESOLVED</span>
                    )}
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      <Modal show={showModal} onHide={() => setShowModal(false)} centered className="premium-modal">
        <Modal.Header closeButton>
          <Modal.Title>Reply to Complaint</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <Form.Group>
            <Form.Label style={{ fontWeight: '600', color: '#636e72', marginBottom: '10px' }}>Your Official Reply</Form.Label>
            <Form.Control
              as="textarea"
              rows={4}
              placeholder="Type your resolution or response here..."
              value={replyText}
              onChange={(e) => setReplyText(e.target.value)}
              style={{ borderRadius: '12px', border: '1px solid rgba(0,0,0,0.1)', padding: '15px' }}
            />
          </Form.Group>
          <div style={{ display: 'flex', gap: '10px', marginTop: '25px' }}>
            <button className="btn-premium-view" style={{ flex: 1 }} onClick={() => setShowModal(false)}>
              Cancel
            </button>
            <button
              className="btn-premium-unblock"
              style={{ flex: 2 }}
              onClick={submitReply}
              disabled={!replyText.trim()}
            >
              Submit Response
            </button>
          </div>
        </Modal.Body>
      </Modal>
    </div>
  );
};

export default AdminComplaints;
