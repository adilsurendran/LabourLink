import mongoose from "mongoose";

const complaintSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },

    workId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Work",
      required: true,
    },

    workerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Register",
      required: true,
    },

    complaint: {
      type: String,
      required: true,
      trim: true,
    },

    status: {
      type: String,
      default: "pending", // admin review
    },
    reply:{
        type:String,
        default:null
    }
  },
  { timestamps: true }
);

export default mongoose.model("Complaint", complaintSchema);