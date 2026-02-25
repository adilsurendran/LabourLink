import LOGIN from "../models/login.js";
import bcrypt from "bcryptjs";
import User from "../models/user.js";
import REQUEST from "../models/userRequest.js";
import WORKER from "../models/worker.js";

export const registeruser = async (req, res) => {
  try {
    const { name, place, email, phone, password, location } = req.body;

    const existinguser = await LOGIN.findOne({ username: email });
    if (existinguser) {
      return res.status(400).json({ message: "User already exists" });
    }

    const hashpassword = await bcrypt.hash(password, 10);
    const login = new LOGIN({
      username: email,
      password: hashpassword,
      role: "User",
    });
    await login.save();

    const user = new User({
      name,
      email,
      phone_Number: phone,
      location,
      photo: req.file?.path,
      place,
      common_Key: login._id,
    });

    await user.save();
    return res.status(200).json({ message: "User Registred Successfully" });
  } catch (e) {
    console.log(e);
    return res.status(500).json({ message: "Server side error" });
  }
};

export const userdetails = async (req, res) => {
  try {
    const all = await User.find()
      .populate("common_Key", "verify")
      .sort({ createdAt: -1 });

    return res
      .status(200)
      .json({ message: "all users Fetched Successfully", users: all });
  } catch (e) {
    console.log(e);
    return res.status(500).json({ message: "An Error occured" });
  }
};

export const getUserById = async (req, res) => {
  try {
    const { id } = req.params;
    const user = await User.findById(id).populate("common_Key", "verify");

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    return res.status(200).json(user);
  } catch (e) {
    console.log(e);
    return res.status(500).json({ message: "An Error occured" });
  }
};

export const togglestatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    const parsedStatus =
      typeof status === "boolean"
        ? status
        : String(status).toLowerCase() === "true";

    const updatedUser = await LOGIN.findByIdAndUpdate(
      id,
      { verify: parsedStatus },
      { new: true }
    );

    if (!updatedUser) {
      return res.status(404).json({ message: "User not found" });
    }

    return res.status(200).json({
      message: updatedUser.verify ? "User Unblocked" : "User Blocked",
      user: updatedUser,
    });
  } catch (e) {
    console.log(e);
    return res.status(500).json({ message: "An Error occured" });
  }
};


export const createRequest = async (req, res) => {
  try {
    const {
      workerId,
      userId,
      date,
      startTime,
      jobType,
      description,
      place,
    } = req.body;

    const request = await REQUEST.create({
      workerId,
      userId,
      date,
      startTime,
      jobType,
      description,
      place,
    });

    res.status(201).json(request);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Server Error" });
  }
};

export const getUserRequests = async (req, res) => {
  try {
    const { userId } = req.params;

    const requests = await REQUEST.find({ userId })
      .populate("workerId", "name skills avgRating")
      .sort({ createdAt: -1 });

    res.status(200).json(requests);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Cancel request (only if pending)
export const cancelUserRequest = async (req, res) => {
  try {
    const { requestId } = req.params;

    const request = await REQUEST.findById(requestId);

    if (!request)
      return res.status(404).json({ message: "Not found" });

    if (request.status !== "pending")
      return res.status(400).json({
        message: "Only pending requests can be cancelled",
      });

    request.status = "cancelled";
    await request.save();

    res.status(200).json(request);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Complete work + rating
export const completeWorkAndRate = async (req, res) => {
  try {
    const { requestId } = req.params;
    const { rating, review } = req.body;

    if (!rating)
      return res.status(400).json({ message: "Rating required" });

    const request = await REQUEST.findById(requestId);

    if (!request)
      return res.status(404).json({ message: "Not found" });

    if (request.status !== "accepted")
      return res.status(400).json({
        message: "Only accepted work can be completed",
      });

    // Update request
    request.status = "completed";
    request.rating = rating;
    request.review = review || null;
    await request.save();

    // Update worker rating
    const worker = await WORKER.findById(request.workerId);

    worker.rating.push(rating);

    const total =
      worker.rating.reduce((a, b) => a + b, 0);

    worker.avgRating =
      total / worker.rating.length;

    await worker.save();

    res.status(200).json(request);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};


import Work from "../models/workModel.js";
import mongoose from "mongoose";
import jobRequestModel from "../models/jobRequestModel.js";
import workModel from "../models/workModel.js";

// ================= ADD WORK =================

export const addWork = async (req, res) => {
  try {
    const { profileId, title, description, date, place } = req.body;

    // Validation
    if (!profileId || !title || !description || !date || !place) {
      return res.status(400).json({
        success: false,
        message: "All fields are required",
      });
    }

    if (!mongoose.Types.ObjectId.isValid(profileId)) {
      return res.status(400).json({
        success: false,
        message: "Invalid profileId",
      });
    }

    const newWork = new Work({
      profileId,
      title,
      description,
      date,
      place,
      // status automatically = "pending"
    });

    await newWork.save();

    res.status(201).json({
      success: true,
      message: "Work added successfully",
      data: newWork,
    });

  } catch (error) {
    console.error("Add Work Error:", error);
    res.status(500).json({
      success: false,
      message: "Server Error",
    });
  }
};


export const getWorksByProfile = async (req, res) => {
  try {
    const { profileId } = req.params;

    if (!mongoose.Types.ObjectId.isValid(profileId)) {
      return res.status(400).json({
        success: false,
        message: "Invalid profileId",
      });
    }

    const works = await Work.find({ profileId })
      .sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      data: works,
    });

  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: "Server Error",
    });
  }
};

// ================= UPDATE WORK (ONLY IF PENDING) =================

export const updateWork = async (req, res) => {
  try {
    const { id } = req.params;
    const { title, description, date, place } = req.body;

    const work = await Work.findById(id);

    if (!work) {
      return res.status(404).json({
        success: false,
        message: "Work not found",
      });
    }

    if (work.status !== "pending") {
      return res.status(403).json({
        success: false,
        message: "Only pending works can be edited",
      });
    }

    work.title = title ?? work.title;
    work.description = description ?? work.description;
    work.date = date ?? work.date;
    work.place = place ?? work.place;

    await work.save();

    res.status(200).json({
      success: true,
      message: "Work updated successfully",
      data: work,
    });

  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: "Server Error",
    });
  }
};

// ================= DELETE WORK (ONLY IF PENDING) =================

export const deleteWork = async (req, res) => {
  try {
    const { id } = req.params;

    const work = await Work.findById(id);

    if (!work) {
      return res.status(404).json({
        success: false,
        message: "Work not found",
      });
    }

    if (work.status !== "pending") {
      return res.status(403).json({
        success: false,
        message: "Only pending works can be deleted",
      });
    }

    await work.deleteOne();

    res.status(200).json({
      success: true,
      message: "Work deleted successfully",
    });

  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: "Server Error",
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

    console.log("requestttttttttt---", request);


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

    await workModel.findByIdAndUpdate(request.workId, { status: "completed" })

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

import Complaint from "../models/Complaint.js";

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
  console.log(req.params);
  console.log("hiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii");


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

    const totalJobPosts = await Work.countDocuments({ profileId: userId });
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
      message: "Server side error"
    });
  }
};
