import mongoose from "mongoose";

const loginschema = mongoose.Schema({
    username:{type:String,required:true,unique:true},
    password:{type:String,required:true},
    role:{type:String,required:true},
    verify:{type:Boolean,default:true}
})
const LOGIN = mongoose.model("Login",loginschema)
export default LOGIN