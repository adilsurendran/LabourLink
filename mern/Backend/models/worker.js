// import mongoose from "mongoose";
// const workerregistrationschema=mongoose.Schema({

//     photo:{type:String},
//     name:{type:String,required:true},
//     email:{type:String,required:true,unique:true},
//     phone_number:{type:Number,required:true,unique:true},
//     dob:{type:String,required:true},
//     age:{type:Number},
//     wage:{type:Number,required:true},
//     rating:{type:[Number], default: []},
//     avgRating:{type:Number, default:0},
//     skills: {type: [String],required: true}, 
//     uniqueid:{type:String,required:true},
//     location:{lat:{type:String},lng:{type:String}},
//     isAvailable:{type:Boolean,default:true},
//     common_Key:{type:mongoose.Schema.Types.ObjectId,ref:"Login"}

// })
// const WORKER = mongoose.model("Register",workerregistrationschema)
// export default WORKER

import mongoose from "mongoose";

const workerregistrationschema = mongoose.Schema({
  photo: { type: String },
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  phone_number: { type: Number, required: true, unique: true },
  dob: { type: String, required: true },
  age: { type: Number },
  wage: { type: Number, required: true },

  // Structured ratings
  ratings: [
    {
      userRating: Number,
      sentimentRating: Number,
      finalRating: Number,
      compoundScore: Number,
      isFlagged: Boolean,
      review: String,
    },
  ],

  avgRating: { type: Number, default: 0 },
  reviewCount: { type: Number, default: 0 },

  skills: { type: [String], required: true },
  uniqueid: { type: String, required: true },
  location: {
    lat: { type: String },
    lng: { type: String },
  },
  isAvailable: { type: Boolean, default: true },
  common_Key: { type: mongoose.Schema.Types.ObjectId, ref: "Login" },
});

const WORKER = mongoose.model("Register", workerregistrationschema);
export default WORKER;