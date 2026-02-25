import { useEffect, useState } from "react";
import api from "../../api";
import "./AdminTables.css";

const AdminFeedback = () => {
  const [feedbacks, setFeedbacks] = useState([]);

  const fetchFeedback = async () => {
    try {
      const res = await api.get("/admin/getall");
      setFeedbacks(res.data.data);
    } catch (error) {
      console.error(error);
    }
  };

  useEffect(() => {
    fetchFeedback();
  }, []);

  return (
    <div className="admin-page-container">
      <div className="page-header-flex">
        <h1 className="page-title">
          <span>💬</span> Community Feedback
        </h1>
      </div>

      {feedbacks.length === 0 ? (
        <div style={{ textAlign: 'center', padding: '100px', background: 'white', borderRadius: '20px', boxShadow: 'var(--shadow-premium)' }}>
          <span style={{ fontSize: '50px' }}>📭</span>
          <p style={{ marginTop: '20px', color: '#636e72', fontSize: '18px' }}>No feedback has been received yet.</p>
        </div>
      ) : (
        <div className="feedback-grid" style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fill, minmax(320px, 1fr))',
          gap: '25px'
        }}>
          {feedbacks.map((item) => {
            const isUser = item.userId !== null;
            const sender = isUser ? item.userId?.name : item.workerId?.name;

            return (
              <div key={item._id} className="feedback-card-premium" style={{
                background: 'white',
                padding: '25px',
                borderRadius: '20px',
                boxShadow: 'var(--shadow-premium)',
                border: '1px solid rgba(0,0,0,0.05)',
                display: 'flex',
                flexDirection: 'column',
                gap: '15px',
                transition: 'all 0.3s ease',
                cursor: 'default'
              }}>
                <div className="card-top" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <span className={`status-pill ${isUser ? 'status-unblocked' : 'status-blocked'}`} style={{
                    background: isUser ? '#e7f5ff' : '#f3f0ff',
                    color: isUser ? '#228be6' : '#7950f2'
                  }}>
                    {isUser ? "USER" : "WORKER"}
                  </span>
                  <small style={{ color: '#b2bec3', fontSize: '12px', fontWeight: '500' }}>
                    {new Date(item.createdAt).toLocaleDateString(undefined, { day: 'numeric', month: 'short', year: 'numeric' })}
                  </small>
                </div>

                <div className="card-content">
                  <h5 style={{ margin: '0 0 10px 0', fontSize: '18px', fontWeight: '700', color: '#2d3436' }}>
                    {sender || "Anonymous Member"}
                  </h5>
                  <p style={{ margin: 0, color: '#636e72', lineHeight: '1.6', fontSize: '14px' }}>
                    "{item.feedback}"
                  </p>
                </div>

                <div className="card-footer-premium" style={{
                  marginTop: 'auto',
                  paddingTop: '15px',
                  borderTop: '1px dashed rgba(0,0,0,0.05)',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '8px'
                }}>
                  <span style={{ fontSize: '12px', color: '#b2bec3' }}>Verified submission</span>
                  <span style={{ color: '#40c057' }}>✓</span>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
};

export default AdminFeedback;
