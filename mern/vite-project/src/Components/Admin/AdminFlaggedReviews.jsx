import { useEffect, useState } from "react";
import {
    Modal,
} from "react-bootstrap";
import api from "../../api";
import "./AdminTables.css";

const AdminFlaggedReviews = () => {
    const [reviews, setReviews] = useState([]);
    const [showModal, setShowModal] = useState(false);
    const [selectedReview, setSelectedReview] = useState(null);
    const [newRating, setNewRating] = useState("");

    const fetchReviews = async () => {
        const res = await api.get(
            "/admin/flagged-reviews"
        );
        setReviews(res.data.data);
    };

    useEffect(() => {
        fetchReviews();
    }, []);

    const approveReview = async (id) => {
        await api.put(
            `/admin/approve-review/${id}`
        );
        fetchReviews();
    };

    const deleteReview = async (id) => {
        await api.delete(
            `/admin/delete-review/${id}`
        );
        fetchReviews();
    };

    const openAdjustModal = (review) => {
        setSelectedReview(review);
        setNewRating(review.finalRating);
        setShowModal(true);
    };

    const adjustReview = async () => {
        await api.put(
            `/admin/adjust-review/${selectedReview._id}`,
            { newRating }
        );
        setShowModal(false);
        fetchReviews();
    };

    return (
        <div className="admin-page-container">
            <div className="page-header-flex">
                <h1 className="page-title">
                    <span>🚩</span> Flagged Reviews
                </h1>
            </div>

            <div className="table-container-premium">
                <table className="premium-table">
                    <thead>
                        <tr>
                            <th>SI NO</th>
                            <th>Worker</th>
                            <th>User</th>
                            <th>User Rating</th>
                            <th>Sentiment Rating</th>
                            <th>Final Rating</th>
                            <th>Review</th>
                            <th>Actions</th>
                        </tr>
                    </thead>

                    <tbody>
                        {reviews.length === 0 ? (
                            <tr>
                                <td colSpan={8} style={{ textAlign: 'center', padding: '40px', color: '#636e72' }}>
                                    No Flagged Reviews found.
                                </td>
                            </tr>
                        ) : (
                            reviews.map((review, i) => (
                                <tr key={review._id}>
                                    <td>{String(i + 1).padStart(2, '0')}</td>
                                    <td style={{ fontWeight: '600' }}>{review.workerId?.name}</td>
                                    <td>{review.userId?.name}</td>
                                    <td style={{ textAlign: 'center' }}>{review.userRating}</td>
                                    <td style={{ textAlign: 'center' }}>{review.sentimentRating}</td>
                                    <td style={{ textAlign: 'center' }}>
                                        <span className="status-pill status-warning">
                                            {review.finalRating}
                                        </span>
                                    </td>
                                    <td style={{ color: '#636e72', maxWidth: '250px', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                                        {review.review}
                                    </td>
                                    <td>
                                        <div style={{ display: 'flex', gap: '8px' }}>
                                            <button
                                                className="btn-premium-unblock"
                                                onClick={() => approveReview(review._id)}
                                            >
                                                Approve
                                            </button>
                                            <button
                                                className="btn-premium-block"
                                                onClick={() => deleteReview(review._id)}
                                            >
                                                Delete
                                            </button>
                                            <button
                                                className="btn-premium-adjust"
                                                onClick={() => openAdjustModal(review)}
                                            >
                                                Adjust
                                            </button>
                                        </div>
                                    </td>
                                </tr>
                            ))
                        )}
                    </tbody>
                </table>
            </div>

            {/* Adjust Modal */}
            <Modal show={showModal} onHide={() => setShowModal(false)} centered className="premium-modal">
                <Modal.Header closeButton>
                    <Modal.Title>Adjust Rating</Modal.Title>
                </Modal.Header>
                <Modal.Body>
                    <div className="modal-details">
                        <div className="detail-row" style={{ flexDirection: 'column', alignItems: 'flex-start', borderBottom: 'none' }}>
                            <span className="detail-label" style={{ marginBottom: '8px' }}>New Rating (1-5)</span>
                            <input
                                type="number"
                                min="1"
                                max="5"
                                className="form-control"
                                style={{
                                    borderRadius: '12px',
                                    padding: '12px',
                                    border: '1px solid rgba(74, 0, 224, 0.1)',
                                    width: '100%'
                                }}
                                value={newRating}
                                onChange={(e) => setNewRating(e.target.value)}
                            />
                        </div>
                    </div>
                </Modal.Body>
                <Modal.Footer style={{ borderTop: 'none', padding: '0 30px 30px' }}>
                    <div style={{ display: 'flex', gap: '12px', width: '100%' }}>
                        <button
                            className="btn-premium-view"
                            style={{ flex: 1, padding: '12px' }}
                            onClick={() => setShowModal(false)}
                        >
                            Cancel
                        </button>
                        <button
                            className="btn-premium-unblock"
                            style={{ flex: 1, padding: '12px' }}
                            onClick={adjustReview}
                        >
                            Save Rating
                        </button>
                    </div>
                </Modal.Footer>
            </Modal>
        </div>
    );
};

export default AdminFlaggedReviews;