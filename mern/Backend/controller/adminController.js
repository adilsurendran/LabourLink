import Complaint from "../models/Complaint.js";
import mongoose from "mongoose";
import Feedback from "../models/Feedback.js";
import REQUEST from "../models/userRequest.js";
import JobRequest from "../models/jobRequestModel.js";
import User from "../models/user.js";
import WORKER from "../models/worker.js";

// ================= GET COMPLAINTS =================

export const getComplaints = async (req, res) => {

  try {
    const { status } = req.query;

    let filter = {};

    if (status && status !== "all") {
      filter.status = status;
    }

    const complaints = await Complaint.find(filter)
      .populate("userId", "name email")
      .populate("workerId", "name")
      .populate("workId", "title")
      .sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      data: complaints,
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Server Error",
    });
  }
};

// ================= REPLY TO COMPLAINT =================

export const replyComplaint = async (req, res) => {
  try {
    const { id } = req.params;
    const { reply } = req.body;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: "Invalid Complaint ID",
      });
    }

    const complaint = await Complaint.findById(id);

    if (!complaint) {
      return res.status(404).json({
        success: false,
        message: "Complaint not found",
      });
    }

    complaint.reply = reply;
    complaint.status = "resolved";

    await complaint.save();

    res.status(200).json({
      success: true,
      message: "Reply submitted",
      data: complaint,
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Server Error",
    });
  }
};


export const sendFeedback = async (req, res) => {
  try {
    const { userId, workerId, feedback } = req.body;

    if (!feedback || feedback.trim() === "") {
      return res.status(400).json({
        success: false,
        message: "Feedback is required",
      });
    }

    // Only one should exist
    if (userId && workerId) {
      return res.status(400).json({
        success: false,
        message: "Invalid request",
      });
    }

    if (!userId && !workerId) {
      return res.status(400).json({
        success: false,
        message: "Profile ID required",
      });
    }

    if (userId && !mongoose.Types.ObjectId.isValid(userId)) {
      return res.status(400).json({
        success: false,
        message: "Invalid userId",
      });
    }

    if (workerId && !mongoose.Types.ObjectId.isValid(workerId)) {
      return res.status(400).json({
        success: false,
        message: "Invalid workerId",
      });
    }

    const newFeedback = new Feedback({
      userId: userId || null,
      workerId: workerId || null,
      feedback,
    });

    await newFeedback.save();

    res.status(201).json({
      success: true,
      message: "Feedback submitted successfully",
      data: newFeedback,
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Server Error",
    });
  }
};


export const getAllFeedback = async (req, res) => {
  try {

    const feedbacks = await Feedback.find()
      .populate("userId", "name email")
      .populate("workerId", "name email")
      .sort({ createdAt: -1 }); // latest first

    res.status(200).json({
      success: true,
      data: feedbacks,
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Server Error",
    });
  }
};

// ================= GET ALL USER REQUESTS =================

export const getAllUserRequests = async (req, res) => {
  try {
    const requests = await REQUEST.find()
      .populate("userId", "name email phone_Number")
      .populate("workerId", "name email phone_number")
      .sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      data: requests,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Server Error",
    });
  }
};

// ================= GET ALL JOB REQUESTS =================

export const getAllJobRequests = async (req, res) => {
  try {
    const jobRequests = await JobRequest.find()
      .populate({
        path: "workId",
        select: "title description date place status",
      })
      .populate("userId", "name email")
      .populate("workerId", "name email phone_number")
      .sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      data: jobRequests,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Server Error",
    });
  }
};

// ================= GET ADMIN STATS =================

export const getAdminStats = async (req, res) => {
  try {
    const pendingComplaints = await Complaint.countDocuments({ status: "pending" });
    const totalFeedback = await Feedback.countDocuments();
    const totalUsers = await User.countDocuments();
    const totalWorkers = await WORKER.countDocuments();

    res.status(200).json({
      success: true,
      data: {
        pendingComplaints,
        totalFeedback,
        totalUsers,
        totalWorkers,
        totalJobs: totalFeedback, // example
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Server Error",
    });
  }
};


export const getFlaggedReviews = async (req, res) => {
  try {
    const reviews = await REQUEST.find({
      isFlagged: true,
      status: "completed",
    })
      .populate("workerId", "name email")
      .populate("userId", "name email")
      .sort({ createdAt: -1 });

    res.status(200).json({ success: true, data: reviews });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const approveFlaggedReview = async (req, res) => {
  try {
    const { requestId } = req.params;

    const request = await REQUEST.findById(requestId);
    request.isFlagged = false;
    await request.save();

    res.status(200).json({ success: true, message: "Review approved" });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const deleteFlaggedReview = async (req, res) => {
  try {
    const { requestId } = req.params;

    const request = await REQUEST.findById(requestId);
    const worker = await WORKER.findById(request.workerId);

    worker.ratings = worker.ratings.filter(
      (r) => r.compoundScore !== request.compoundScore
    );

    const total = worker.ratings.reduce(
      (sum, r) => sum + (Number(r.finalRating) || 0),
      0
    );

    worker.reviewCount = worker.ratings.length;
    worker.avgRating =
      worker.reviewCount > 0
        ? Number((total / worker.reviewCount).toFixed(2))
        : 0;

    await worker.save();
    await REQUEST.findByIdAndDelete(requestId);

    res.status(200).json({ success: true, message: "Review deleted" });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const adjustFlaggedReview = async (req, res) => {
  try {
    const { requestId } = req.params;
    const { newRating } = req.body;

    const request = await REQUEST.findById(requestId);
    const worker = await WORKER.findById(request.workerId);

    request.finalRating = newRating;
    request.isFlagged = false;
    await request.save();

    const ratingObj = worker.ratings.find(
      (r) => r.compoundScore === request.compoundScore
    );

    if (ratingObj) {
      ratingObj.finalRating = newRating;
    }

    const total = worker.ratings.reduce(
      (sum, r) => sum + (Number(r.finalRating) || 0),
      0
    );

    worker.avgRating =
      worker.ratings.length > 0
        ? Number((total / worker.ratings.length).toFixed(2))
        : 0;

    await worker.save();

    res.status(200).json({ success: true, message: "Rating adjusted" });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// ================= WORK FLAGGED REVIEWS =================
import jobRequestModel from "../models/jobRequestModel.js";
import workModel from "../models/workModel.js";

export const getWorkFlaggedReviews = async (req, res) => {
  try {

    const reviews = await workModel
      .find({
        isFlagged: true,
        status: "completed"
      })
      .populate("profileId", "name phone_Number")
      .sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      data: reviews
    });

  } catch (error) {
    console.log(error);

    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

export const approveWorkFlaggedReview = async (req, res) => {
  try {

    const { requestId } = req.params;

    const request = await workModel.findById(requestId);

    request.isFlagged = false;

    await request.save();

    res.status(200).json({
      success: true,
      message: "Review approved"
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

export const deleteWorkFlaggedReview = async (req, res) => {
  // Logic removed as per user request
};

export const adjustWorkFlaggedReview = async (req, res) => {
  try {

    const { requestId } = req.params;
    const { newRating } = req.body;

    const request = await workModel.findById(requestId);
    if (!request) {
      return res.status(404).json({ success: false, message: "Work not found" });
    }

    // Find the completed job request to get the workerId
    const jobRequest = await jobRequestModel.findOne({
      workId: requestId,
      status: "completed"
    });

    if (!jobRequest) {
      return res.status(404).json({
        success: false,
        message: "Associated completed job request not found"
      });
    }

    const worker = await WORKER.findById(jobRequest.workerId);
    if (!worker) {
      return res.status(404).json({ success: false, message: "Worker not found" });
    }

    // Update Work model
    request.finalRating = Number(newRating);
    request.isFlagged = false;
    await request.save();

    // Update JobRequest model
    jobRequest.finalRating = Number(newRating);
    await jobRequest.save();

    // Update Worker ratings array
    const ratingObj = worker.ratings.find(
      (r) => r.compoundScore === request.compoundScore
    );

    if (ratingObj) {
      ratingObj.finalRating = Number(newRating);
    }

    const total = worker.ratings.reduce(
      (sum, r) => sum + (Number(r.finalRating) || 0),
      0
    );

    worker.avgRating = worker.ratings.length > 0
      ? Number((total / worker.ratings.length).toFixed(2))
      : 0;

    await worker.save();

    res.status(200).json({
      success: true,
      message: "Rating adjusted successfully"
    });

  } catch (error) {
    console.log(error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

export const getRequestsByWork = async (req, res) => {
  try {
    const { workId } = req.params;

    const requests = await jobRequestModel.find({ workId })
      .populate({
        path: "workerId",
        select: "name wage avgRating location",
      })
      .populate("workId");

    res.status(200).json({
      success: true,
      data: requests,
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Server Error",
    });
  }
};


export const acceptRequest = async (req, res) => {
  try {
    const { requestId } = req.params;

    const request = await jobRequestModel.findById(requestId);

    if (!request)
      return res.status(404).json({
        success: false,
        message: "Request not found",
      });

    // Accept selected worker
    request.status = "accepted";
    await request.save();

    // Reject all others for same job
    await jobRequestModel.updateMany(
      {
        workId: request.workId,
        _id: { $ne: requestId },
      },
      { status: "rejected" }
    );

    await workModel.findByIdAndUpdate(request.workId, { status: "accepted" });

    res.status(200).json({
      success: true,
      message: "Worker Accepted",
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Server Error",
    });
  }
};

export const rejectRequest = async (req, res) => {
  try {
    const { requestId } = req.params;

    await jobRequestModel.findByIdAndUpdate(
      requestId,
      { status: "rejected" }
    );

    res.status(200).json({
      success: true,
      message: "Worker Rejected",
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Server Error",
    });
  }
};

export const createComplaint = async (req, res) => {
  try {
    const { userId, workId, workerId, complaint } = req.body;

    if (
      !mongoose.Types.ObjectId.isValid(userId) ||
      !mongoose.Types.ObjectId.isValid(workId) ||
      !mongoose.Types.ObjectId.isValid(workerId)
    ) {
      return res.status(400).json({
        success: false,
        message: "Invalid IDs",
      });
    }

    const newComplaint = new Complaint({
      userId,
      workId,
      workerId,
      complaint,
    });

    await newComplaint.save();

    res.status(201).json({
      success: true,
      message: "Complaint submitted successfully",
      data: newComplaint,
    });

  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: "Server Error",
    });
  }
};

export const getUserComplaints = async (req, res) => {
  try {
    const { userId } = req.params;
    const { workId } = req.query;

    if (!mongoose.Types.ObjectId.isValid(userId)) {
      return res.status(400).json({
        success: false,
        message: "Invalid User ID",
      });
    }

    let filter = { userId };

    if (workId && mongoose.Types.ObjectId.isValid(workId)) {
      filter.workId = workId;
    }

    const complaints = await Complaint.find(filter)
      .populate("workId", "title")
      .populate("workerId", "name")
      .sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      data: complaints,
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Server Error",
    });
  }
};

export const getUserDashboardStats = async (req, res) => {
  try {
    const { userId } = req.params;

    if (!mongoose.Types.ObjectId.isValid(userId)) {
      return res.status(400).json({
        success: false,
        message: "Invalid User ID",
      });
    }

    const totalJobPosts = await workModel.countDocuments({ profileId: userId });
    const totalRequests = await REQUEST.countDocuments({ userId: userId });

    res.status(200).json({
      success: true,
      data: {
        totalJobPosts,
        totalRequests,
      },
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: "Server Error",
    });
  }
};

export const updateUserProfile = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, place, phone_Number, location } = req.body;

    const user = await User.findById(id);
    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    if (name) user.name = name;
    if (place) user.place = place;
    if (phone_Number) user.phone_Number = phone_Number;
    if (location) {
      user.location = typeof location === 'string' ? JSON.parse(location) : location;
    }
    if (req.file) {
      user.photo = req.file.path.replace(/\\/g, '/');
    }

    await user.save();
    return res.status(200).json({
      success: true,
      message: "Profile updated successfully",
      data: user
    });
  } catch (error) {
    console.error(error);
    return res.status(500).json({
      success: false,
      message: "Server Error",
    });
  }
};
