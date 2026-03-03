import LOGIN from "../models/login.js";
import REQUEST from "../models/userRequest.js";
import WORKER from "../models/worker.js";
import bcrypt from "bcryptjs";
import workModel from "../models/workModel.js";

export const registerworker = async (req, res) => {
  try {
    const {
      name,
      email,
      phone_number,
      dob,
      age,
      password,
      wage,
      wage_unit,
      skills,
      uniqueid,
      location,
      gender
    } = req.body;

    const existinguser = await LOGIN.findOne({ username: email });
    if (existinguser) {
      return res.status(400).json({ message: "User already exists" });
    }

    const hashpassword = await bcrypt.hash(password, 10);
    const login = new LOGIN({
      username: email,
      password: hashpassword,
      role: "Worker",
    });
    await login.save();

    const skillsArray = skills
      .split(',')
      .map((skill) => skill.trim())
      .filter((skill) => skill.length > 0);

    const worker = new WORKER({
      name,
      email,
      phone_number,
      dob,
      age,
      wage,
      gender,
      wage_unit,
      skills: skillsArray,
      uniqueid,
      location,
      common_Key: login._id,
      photo: req.file?.path,
    });

    await worker.save();
    return res.status(200).json({ message: "Message recieved SuccesFully" });
  } catch (error) {
    console.log(error);
    return res.status(500).json({ message: "Server side Error" });
  }
};

export const workerdetails = async (req, res) => {
  try {
    const all = await WORKER.find()
      .populate("common_Key", "verify")
      .sort({ createdAt: -1 });

    return res.status(200).json({
      message: "All workers fetched successfully",
      workers: all,
    });
  } catch (e) {
    console.log(e);
    return res.status(500).json({ message: "An Error occured" });
  }
};

export const getWorkerById = async (req, res) => {
  try {
    const { id } = req.params;
    const worker = await WORKER.findById(id).populate("common_Key", "verify");

    if (!worker) {
      return res.status(404).json({ message: "Worker not found" });
    }

    return res
      .status(200)
      .json({ message: "Worker fetched successfully", worker });
  } catch (e) {
    console.log(e);
    return res.status(500).json({ message: "An Error occured" });
  }
};

export const toggleworkerstatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    const parsedStatus =
      typeof status === "boolean"
        ? status
        : String(status).toLowerCase() === "true";

    const updatedWorker = await LOGIN.findByIdAndUpdate(
      id,
      { verify: parsedStatus },
      { new: true }
    );

    if (!updatedWorker) {
      return res.status(404).json({ message: "Worker not found" });
    }

    return res.status(200).json({
      message: updatedWorker.verify ? "Worker Unblocked" : "Worker Blocked",
      worker: updatedWorker,
    });
  } catch (e) {
    console.log(e);
    return res.status(500).json({ message: "An Error occured" });
  }
};




// ================= GET OWN PROFILE =================
export const getWorkerProfile = async (req, res) => {
console.log(req.params);

  try {

    const { id } = req.params;   // ✅ FROM PARAMS

    if (!id) {
      return res.status(400).json({
        message: "Profile ID missing"
      });
    }

    const worker = await WORKER.findById(id);

    if (!worker) {
      return res.status(404).json({
        message: "Worker not found"
      });
    }

    return res.status(200).json(worker);

  } catch (error) {
    console.log(error);
    return res.status(500).json({
      message: "Server side error"
    });
  }
};



// ================= UPDATE OWN PROFILE =================
export const updateWorkerProfile = async (req, res) => {

  try {

    const { id } = req.params;   // ✅ FROM PARAMS

    if (!id) {
      return res.status(400).json({
        message: "Profile ID missing"
      });
    }

    const worker = await WORKER.findById(id);

    if (!worker) {
      return res.status(404).json({
        message: "Worker not found"
      });
    }

    // 🔒 PROTECTED FIELDS (CANNOT CHANGE)
    // email
    // dob

    if (req.body.name !== undefined)
      worker.name = req.body.name;

    if (req.body.phone_number !== undefined)
      worker.phone_number = req.body.phone_number;

    if (req.body.wage !== undefined)
      worker.wage = req.body.wage;

    if (req.body.isAvailable !== undefined)
      worker.isAvailable = req.body.isAvailable;

    // ===== SKILLS ARRAY SAFE =====
    if (req.body.skills !== undefined) {
      worker.skills = Array.isArray(req.body.skills)
        ? req.body.skills
        : [req.body.skills];
    }

    // ===== PHOTO =====
    if (req.file) {
      worker.photo = `uploads/${req.file.filename}`;
    }

    await worker.save();

    return res.status(200).json({
      message: "Profile updated successfully",
      worker
    });

  } catch (error) {
    console.log(error);
    return res.status(500).json({
      message: "Server side error"
    });
  }
};

export const getAvailableWorkers = async (req, res) => {
  try {

    const workers = await WORKER.find({ isAvailable: true })
console.log(workers);

    return res.status(200).json(workers);

  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Server Error" });
  }
};


export const getWorkerRequests = async (req, res) => {
  try {
    const { workerId } = req.params;

    const requests = await REQUEST.find({ workerId })
      .populate("userId", "name email phone")
      .sort({ createdAt: -1 });

    res.status(200).json(requests);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Update status (Accept / Reject)
export const updateRequestStatus = async (req, res) => {
  try {
    const { requestId } = req.params;
    const { status } = req.body;

    if (!["accepted", "rejected"].includes(status)) {
      return res.status(400).json({ message: "Invalid status" });
    }

    const updated = await REQUEST.findByIdAndUpdate(
      requestId,
      { status },
      { new: true }
    );

    res.status(200).json(updated);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};


export const getPendingJobs = async (req, res) => {
  
  try {

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const jobs = await workModel.find({
      status: "pending",
      date: { $gte: today },
    })
      .populate("profileId", "name location place")
      .sort({ date: 1 });

    res.status(200).json({
      success: true,
      data: jobs,
    });

  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: "Server Error",
    });
  }
};

import JobRequest from "../models/jobRequestModel.js";
import mongoose from "mongoose";

export const requestJob = async (req, res) => {
  try {
    const { workId, workerId } = req.body;

    if (!mongoose.Types.ObjectId.isValid(workId) ||
        !mongoose.Types.ObjectId.isValid(workerId)) {
      return res.status(400).json({
        success: false,
        message: "Invalid ID",
      });
    }

    const work = await workModel.findById(workId);

    if (!work) {
      return res.status(404).json({
        success: false,
        message: "Job not found",
      });
    }

    // prevent duplicate request
    const alreadyRequested =
      await JobRequest.findOne({
        workId,
        workerId,
      });

    if (alreadyRequested) {
      return res.status(400).json({
        success: false,
        message: "Already requested",
      });
    }

    const newRequest = new JobRequest({
      workId,
      userId: work.profileId,
      workerId,
    });

    await newRequest.save();

    res.status(201).json({
      success: true,
      message: "Request submitted",
      data: newRequest,
    });

  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: "Server Error",
    });
  }
};

export const getWorkerRequest = async (req, res) => {
  try {
    const { workerId } = req.params;

    if (!mongoose.Types.ObjectId.isValid(workerId)) {
      return res.status(400).json({
        success: false,
        message: "Invalid Worker ID",
      });
    }

    const requests = await JobRequest.find({ workerId })
      .populate({
        path: "workId",
        populate: {
          path: "profileId",
          select: "name place",
        },
      })
      .sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      data: requests,
    });

  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: "Server Error",
    });
  }
};

export const cancelRequest = async (req, res) => {
  try {
    const { requestId } = req.params;

    if (!mongoose.Types.ObjectId.isValid(requestId)) {
      return res.status(400).json({
        success: false,
        message: "Invalid Request ID",
      });
    }

    const request = await JobRequest.findById(requestId);

    if (!request) {
      return res.status(404).json({
        success: false,
        message: "Request not found",
      });
    }

    if (request.status !== "pending") {
      return res.status(400).json({
        success: false,
        message: "Only pending requests can be cancelled",
      });
    }

    request.status="cancelled"

    await request.save();

    res.status(200).json({
      success: true,
      message: "Request cancelled successfully",
    });

  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: "Server Error",
    });
  }
};

