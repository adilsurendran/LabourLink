import mongoose from "mongoose";

const workSchema = new mongoose.Schema(
  {
    profileId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },

    title: {
      type: String,
      required: true,
      trim: true,
    },

    description: {
      type: String,
      required: true,
      trim: true,
    },

    date: {
      type: Date,
      required: true,
    },

    place: {
      type: String,
      required: true,
      trim: true,
    },

    status: {
      type: String,
      default: "pending",
    },
    rating:{type:Number,default:null},
    review:{type:String,default:null},
  },
  {
    timestamps: true,
  }
);

export default mongoose.model("Work", workSchema);