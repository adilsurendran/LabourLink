import mongoose from "mongoose";
const registerschema = mongoose.Schema({
    name:{type:String,required:true},
    email:{type:String,required:true,unique:true},
    phone_Number:{type:Number,required:true},
    location:{lat:{type:String},lng:{type:String}},
    photo:{type:String},
    place:{type:String},
    common_Key:{type:mongoose.Schema.Types.ObjectId,ref:"Login"}
})
const User = mongoose.model("User",registerschema)
export default User

