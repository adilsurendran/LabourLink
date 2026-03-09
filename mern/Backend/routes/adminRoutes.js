import express from "express";
import {
    getAllFeedback,
    getAllJobRequests,
    getAllUserRequests,
    getAdminStats,
    getComplaints,
    replyComplaint,
    sendFeedback,
    getFlaggedReviews,
    approveFlaggedReview,
    deleteFlaggedReview,
    adjustFlaggedReview,
    getWorkFlaggedReviews,
    approveWorkFlaggedReview,
    deleteWorkFlaggedReview,
    adjustWorkFlaggedReview
} from "../controller/adminController.js";


const Crouter = express.Router();

Crouter.get("/getcomplaint", getComplaints);
Crouter.put("/reply/:id", replyComplaint);
Crouter.post("/send", sendFeedback);
Crouter.get("/getall", getAllFeedback);
Crouter.get("/get-user-requests", getAllUserRequests);
Crouter.get("/get-job-requests", getAllJobRequests);
Crouter.get("/get-stats", getAdminStats);

Crouter.get("/flagged-reviews", getFlaggedReviews);

// Approve review
Crouter.put("/approve-review/:requestId", approveFlaggedReview);

// Delete review
Crouter.delete("/delete-review/:requestId", deleteFlaggedReview);

// Adjust rating manually
Crouter.put("/adjust-review/:requestId", adjustFlaggedReview);


// new routesssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssss

Crouter.get("/work-flagged-reviews", getWorkFlaggedReviews);

Crouter.put("/work-approve-review/:requestId", approveWorkFlaggedReview);

Crouter.delete("/work-delete-review/:requestId", deleteWorkFlaggedReview);

Crouter.put("/work-adjust-review/:requestId", adjustWorkFlaggedReview);

export default Crouter;