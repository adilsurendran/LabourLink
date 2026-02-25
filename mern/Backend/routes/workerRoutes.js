import express from "express";
import { upload } from "../middleware/upload.js";
import {
  cancelRequest,
  getAvailableWorkers,
  getPendingJobs,
  getWorkerById,
  getWorkerProfile,
  getWorkerRequest,
  getWorkerRequests,
  registerworker,
  requestJob,
  toggleworkerstatus,
  updateRequestStatus,
  updateWorkerProfile,
  workerdetails,
} from "../controller/workerController.js";

const router = express.Router();

router.post('/register', upload.single("photo"), registerworker);
router.get('/getdetails', workerdetails);
router.get("/available", getAvailableWorkers);
router.get("/pending-jobs", getPendingJobs);
router.post("/request-job", requestJob);
router.get("/worker-requests/:workerId", getWorkerRequest);
router.delete("/cancel-request/:requestId", cancelRequest);
router.put('/block/worker/:id', toggleworkerstatus);
router.get("/profile/:id", getWorkerProfile);
router.put("/profile/:id", upload.single("photo"), updateWorkerProfile);
router.get("/getrequest/:workerId", getWorkerRequests);
router.put("/update-status/:requestId", updateRequestStatus);
router.get('/:id', getWorkerById);

export default router;
