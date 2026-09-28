import React from 'react';
import { Navigate, Outlet } from 'react-router-dom';

export default function AdminRoute() {
  // Lấy thông tin user và token từ localStorage (hoặc Context/Redux tùy cách bạn lưu khi gọi API C#)
  const token = localStorage.getItem('token');
  const userRole = localStorage.getItem('role'); // Ví dụ: 'Admin', 'User'

  // 1. Nếu chưa đăng nhập (không có token) -> Đẩy về trang đăng nhập /admin/auth
  if (!token) {
    return <Navigate to="/admin/auth" replace />;
  }

  // 2. Nếu đã đăng nhập nhưng role KHÔNG phải là Admin -> Thông báo không có quyền
  if (userRole !== 'Admin') {
    return (
      <div style={{
        display: 'flex', 
        flexDirection: 'column', 
        alignItems: 'center', 
        justifyContent: 'center', 
        height: '100vh',
        fontFamily: 'sans-serif'
      }}>
        <h2 style={{ color: '#ef4444', marginBottom: '8px' }}>🚫 Truy cập bị từ chối</h2>
        <p style={{ color: '#64748b', marginBottom: '16px' }}>
          Bạn không có quyền quản trị viên (Admin) để truy cập trang này.
        </p>
        <button 
          onClick={() => {
            // Xóa thông tin đăng nhập nếu muốn hoặc chuyển về trang chủ
            window.location.href = '/';
          }}
          style={{
            padding: '10px 20px',
            backgroundColor: '#3b82f6',
            color: 'white',
            border: 'none',
            borderRadius: '8px',
            cursor: 'pointer',
            fontWeight: 'bold'
          }}
        >
          Về trang chủ khách hàng
        </button>
      </div>
    );
  }

  // 3. Nếu đúng là Admin -> Cho phép truy cập vào các trang con bên trong
  return <Outlet />;
}