import express from "express";
import {
  acceptRequest,
  addWork,
  cancelUserRequest,
  completeJobRequest,
  completeWorkAndRate,
  createComplaint,
  createRequest,
  deleteWork,
  getRequestsByWork,
  getUserById,
  getUserComplaints,
  getUserRequests,
  getWorksByProfile,
  getUserDashboardStats,
  registeruser,
  rejectRequest,
  togglestatus,
  updateWork,
  userdetails,
  updateUserProfile,
} from "../controller/usercontroller.js";
import { upload } from "../middleware/upload.js";

const userRouter = express.Router();

userRouter.post('/register', upload.single("profile_image"), registeruser);
userRouter.get("/get-reply/:userId", getUserComplaints);
userRouter.get('/getdetails', userdetails);
userRouter.get('/:id', getUserById);
userRouter.put('/block/user/:id', togglestatus);
userRouter.post("/create", createRequest);
userRouter.post("/createComplaint", createComplaint);
userRouter.get("/getmyrequest/:userId", getUserRequests);

// Cancel request (pending only)
userRouter.put("/cancel/:requestId", cancelUserRequest);

// Complete work + rating
userRouter.put("/complete/:requestId", completeWorkAndRate);

// Complete job request (from worker selection page)
userRouter.put("/complete-job-request/:requestId", completeJobRequest);

userRouter.post("/add-work", addWork);

userRouter.get("/get-works/:profileId", getWorksByProfile);
userRouter.put("/update-work/:id", updateWork);
userRouter.delete("/delete-work/:id", deleteWork);
userRouter.get("/job-requests/:workId", getRequestsByWork);
userRouter.put("/accept/:requestId", acceptRequest);
userRouter.put("/reject/:requestId", rejectRequest);
userRouter.get("/stats/:userId", getUserDashboardStats);
userRouter.put("/update-profile/:id", upload.single("photo"), updateUserProfile);

export default userRouter;
