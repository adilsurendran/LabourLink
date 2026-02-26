// import mongoose from "mongoose";

// const workSchema = new mongoose.Schema(
//   {
//     profileId: {
//       type: mongoose.Schema.Types.ObjectId,
//       ref: "User",
//       required: true,
//     },

//     title: {
//       type: String,
//       required: true,
//       trim: true,
//     },

//     description: {
//       type: String,
//       required: true,
//       trim: true,
//     },

//     date: {
//       type: Date,
//       required: true,
//     },

//     place: {
//       type: String,
//       required: true,
//       trim: true,
//     },

//     status: {
//       type: String,
//       default: "pending",
//     },
//     rating:{type:Number,default:null},
//     review:{type:String,default:null},
//   },
//   {
//     timestamps: true,
//   }
// );

// export default mongoose.model("Work", workSchema);

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

    // Hybrid Rating Fields
    userRating: { type: Number, default: null },
    sentimentRating: { type: Number, default: null },
    compoundScore: { type: Number, default: null },
    finalRating: { type: Number, default: null },
    review: { type: String, default: null },
    isFlagged: { type: Boolean, default: false },
  },
  { timestamps: true }
);

export default mongoose.model("Work", workSchema);