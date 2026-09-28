import React from 'react';
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import Home from './pages/user/Home'; 
import AdminLayout from './layouts/AdminLayout';
import AdminDashboard from './pages/admin/AdminDashboard';
import AuthPage from './pages/admin/Auth/AuthPage';
import UserList from './pages/admin/User/UserList';
import UserCreate from './pages/admin/User/UserCreate';
import UserEdit from './pages/admin/User/UserEdit';
import CourseTopicList from './pages/admin/course/CourseTopicList';
import CourseTopicAdd from './pages/admin/course/CourseTopicAdd';
import CourseTopicEdit from './pages/admin/course/CourseTopicEdit';
import CourseManagementMain from './pages/admin/course/CourseManagementMain';
import VocabItemManager from './pages/admin/course/items/VocabItemManager';
import BattleAdminPanel from './pages/admin/Battle/BattleAdminPanel';

// Import component bảo vệ vừa tạo ở Bước 1
import AdminRoute from './routes/AdminRoute'; 

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        {/* Trang chủ khách hàng (Ai cũng vào được) */}
        <Route path="/" element={<Home />} />

        {/* Trang đăng nhập/đăng ký quản trị */}
        <Route path="/admin/auth" element={<AuthPage />} />

        {/* KHU VỰC ĐƯỢC BẢO VỆ CHO ADMIN */}
        <Route element={<AdminRoute />}>
          <Route path="/admin" element={<AdminLayout />}>
            <Route index element={<AdminDashboard />} />
            <Route path="users" element={<UserList />} />
            <Route path="users/create" element={<UserCreate />} />
            <Route path="users/edit/:id" element={<UserEdit />} />
            <Route path="courses" element={<CourseManagementMain />} />
            <Route path="courses/topics" element={<CourseTopicList />} />
            <Route path="courses/topics/add" element={<CourseTopicAdd />} />
            <Route path="courses/topics/edit/:id" element={<CourseTopicEdit />} />
            <Route path="courses/topics/:topicId/items" element={<VocabItemManager />} />
            <Route path="battles" element={<BattleAdminPanel />} />
          </Route>
        </Route>
      </Routes>
    </BrowserRouter>
  );
}