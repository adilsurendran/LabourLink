import mongoose from "mongoose"
import express from "express"
import cors from "cors"
import authRoutes from "./routes/authRoutes.js"

import workerRoutes from "./routes/workerRoutes.js"
import userRouter from "./routes/userRoutes.js"
import Crouter from "./routes/adminRoutes.js"

mongoose.connect("mongodb://localhost:27017/LABOURLINK").then(()=>{
    console.log("MongoDb connected successfully")
}).catch((error) =>{
    console.log("connection failed",error)
})
 
const server = express()
server.use(express.json())
server.use(cors({
    origin:"*"
}))
server.listen(8000,()=>{
    console.log("Server starte running at port 8000")
})

server.use('/api/auth',authRoutes)
server.use('/api/worker',workerRoutes)
server.use('/api/user',userRouter)
server.use('/api/admin',Crouter)
server.use("/uploads", express.static("uploads"));
