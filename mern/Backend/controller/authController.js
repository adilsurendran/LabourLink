import LOGIN from "../models/login.js";
import User from "../models/user.js";
import bcrypt from "bcryptjs";
import WORKER from "../models/worker.js";

export const login = async (req, res) => {
    console.log(req.body);
    

  const { username, password } = req.body;

  try {

    const user = await LOGIN.findOne({ username });

    if (!user) {
      return res.status(400).json({
        message: "Invalid Username or Password"
      });
    }

    const isMatch = await bcrypt.compare(password, user.password);

    if (!isMatch) {
      return res.status(400).json({
        message: "Invalid Username or Password"
      });
    }

    let profileId = user._id; // default (Admin fallback)

    // ===== WORKER =====
    if (user.role === "Worker") {
      const worker = await WORKER.findOne({
        common_Key: user._id
      });

      if (worker) {
        profileId = worker._id;
      }
    }

    // ===== NORMAL USER =====
    else if (user.role === "User") {
      const normalUser = await User.findOne({
        common_Key: user._id
      });

      if (normalUser) {
        profileId = normalUser._id;
      }
    }

    return res.status(200).json({
      message: "Login Successful",
      role: user.role,
      profileId: profileId,
      verify:user.verify
    });

  } catch (e) {
    console.log(e);
    return res.status(500).json({
      message: "Server side error"
    });
  }
};
