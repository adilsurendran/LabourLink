import React, { useState } from 'react'
import './login.css'
import api from '../api'
import { useNavigate } from 'react-router-dom'
function Login() {
  const [username, setusername] = useState("")
  const [password, Setpassword] = useState("")
  const [showPassword, setShowPassword] = useState(false)
  const navigate = useNavigate()

  const login = async (e) => {
    e.preventDefault()
    try {
      const body = {
        username, password
      }
      const res = await api.post("/auth/login", body)

      if (res.status === 200) {
        if (res.data.role === "admin") {
          alert("Login Successful!")
          navigate("/Admin")
        } else {
          alert("You are not allowed to enter here")
        }
      }
    }
    catch (e) {
      console.log(e);
      if (e.response && e.response.data && e.response.data.message) {
        alert(e.response.data.message)
      } else {
        alert("Something went wrong. Please try again.")
      }
    }
  }

  return (
    <div className='login-container'>
      <div className='login-card'>
        <div className="login-header">
          <h1>Welcome Back</h1>
          <p>Please login to your account</p>
        </div>
        <form className='login-form' onSubmit={login}>
          <div className="input-group">
            {/* <label htmlFor="username">Email</label> */}
            <input
              id="username"
              type="email"
              placeholder='Enter your email'
              className='login-input'
              onChange={(e) => setusername(e.target.value)}
              required
            />
          </div>

          <div className="input-group">
            {/* <label htmlFor="password">Password</label> */}
            <div className="password-input-wrapper">
              <input
                id="password"
                type={showPassword ? "text" : "password"}
                placeholder='Enter your password'
                className='login-input'
                onChange={(e) => Setpassword(e.target.value)}
                required
              />
              <button
                type="button"
                className="password-toggle"
                onClick={() => setShowPassword(!showPassword)}
                aria-label={showPassword ? "Hide password" : "Show password"}
              >
                {showPassword ? (
                  <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"></path><line x1="1" y1="1" x2="23" y2="23"></line></svg>
                ) : (
                  <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path><circle cx="12" cy="12" r="3"></circle></svg>
                )}
              </button>
            </div>
          </div>

          <button type='submit' className='login-button'>
            Login to Account
          </button>

        </form>
      </div>
    </div>
  )
}

export default Login