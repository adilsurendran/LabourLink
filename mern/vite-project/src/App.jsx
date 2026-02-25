import './App.css'
import { Route, Routes, Navigate } from 'react-router-dom'
import Manageworker from './Components/Admin/Manageworker'
import ManageUser from './Components/Admin/ManageUser'
import Login from './Components/Login'
import AdminComplaints from './Components/Admin/AdminComplaints'
import AdminFeedback from './Components/Admin/AdminFeedback'
import AdminUserRequests from './Components/Admin/AdminUserRequests'
import AdminJobRequests from './Components/Admin/AdminJobRequests'
import AdminDashboard from './Components/Admin/AdminDashboard'
import AdminDashboardHome from './Components/Admin/AdminDashboardHome'

function App() {
  return (
    <>
      <Routes>
        <Route path='/' element={<Login />} />

        {/* Redirect old routes to new nested ones if necessary, or just use nested */}
        <Route path='/ManageWorker' element={<Navigate to="/Admin/ManageWorker" replace />} />
        <Route path='/ManageUser' element={<Navigate to="/Admin/ManageUser" replace />} />
        <Route path='/Complaint' element={<Navigate to="/Admin/Complaint" replace />} />
        <Route path='/Feedback' element={<Navigate to="/Admin/Feedback" replace />} />

        {/* Premium Admin Dashboard with Nested Routing */}
        <Route path='/Admin' element={<AdminDashboard />}>
          <Route path='Dashboard' element={<AdminDashboardHome />} />
          <Route path='ManageWorker' element={<Manageworker />} />
          <Route path='ManageUser' element={<ManageUser />} />
          <Route path='Complaint' element={<AdminComplaints />} />
          <Route path='Feedback' element={<AdminFeedback />} />
          <Route path='UserRequests' element={<AdminUserRequests />} />
          <Route path='JobRequests' element={<AdminJobRequests />} />
          {/* Default admin view */}
          <Route index element={<Navigate to="Dashboard" replace />} />
        </Route>
      </Routes>
    </>
  )
}

export default App
