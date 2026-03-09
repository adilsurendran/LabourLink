import mongoose from "mongoose";

const requestSchema = mongoose.Schema(
  {
    workerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Register",
      required: true,
    },
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    date: { type: String, required: true },
    startTime: { type: String, required: true },
    jobType: { type: String, required: true },
    description: { type: String },
    place: { type: String, required: true },

    // Hybrid rating fields
    userRating: { type: Number, default: null },
    sentimentRating: { type: Number, default: null },
    compoundScore: { type: Number, default: null },
    finalRating: { type: Number, default: null },
    review: { type: String, default: null },
    isFlagged: { type: Boolean, default: false },

    status: {
      type: String,
      default: "pending",
    },
  },
  { timestamps: true }
);

const REQUEST = mongoose.model("Request", requestSchema);
export default REQUEST;