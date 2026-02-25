import mongoose from "mongoose";

const feedbackSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      default: null,
    },

    workerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Register",
      default: null,
    },

    feedback: {
      type: String,
      required: true,
      trim: true,
    },
  },
  { timestamps: true }
);

export default mongoose.model("Feedback", feedbackSchema);