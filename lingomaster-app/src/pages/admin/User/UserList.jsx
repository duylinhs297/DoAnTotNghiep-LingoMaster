import React, { useEffect, useState } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';

const API_USERS_URL = 'http://localhost:5208/api/Users';

export default function UserList() {
    const navigate = useNavigate();
    const location = useLocation(); // Lấy thông tin điều hướng truyền sang
    const [users, setUsers] = useState([]);
    const [filteredUsers, setFilteredUsers] = useState([]);
    const [loading, setLoading] = useState(true);
    const [roleFilter, setRoleFilter] = useState('ALL');
    const [searchTerm, setSearchTerm] = useState('');

    const [notification, setNotification] = useState({ message: '', type: 'success', visible: false });

    const showNotification = (message, type = 'success') => {
        setNotification({ message, type, visible: true });
        setTimeout(() => {
            setNotification(prev => ({ ...prev, visible: false }));
        }, 1000);
    };

    // Kiểm tra nếu có state thông báo truyền từ trang Create/Edit sang
    useEffect(() => {
        if (location.state && location.state.notification) {
            const { message, type } = location.state.notification;
            showNotification(message, type);
            // Xóa state đi để khi người dùng nhấn F5 hoặc chuyển trang không bị hiện lại thông báo cũ
            window.history.replaceState({}, document.title);
        }
    }, [location]);

    const fetchUsers = async () => {
        try {
            const res = await fetch(API_USERS_URL);
            if (res.ok) {
                const data = await res.json();
                setUsers(data);
            }
        } catch (err) {
            showNotification('Lỗi khi tải danh sách người dùng.', 'error');
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchUsers();
    }, []);

    useEffect(() => {
        let result = users;

        if (roleFilter !== 'ALL') {
            result = result.filter(u => u.role === roleFilter);
        }

        if (searchTerm.trim() !== '') {
            result = result.filter(u =>
                u.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                u.email.toLowerCase().includes(searchTerm.toLowerCase())
            );
        }

        setFilteredUsers(result);
    }, [roleFilter, searchTerm, users]);

    const handleDelete = async (id) => {
        if (id === 1) {
            showNotification('Không được phép xóa tài khoản quản trị tối cao!', 'error');
            return;
        }
        if (!window.confirm('Bạn có chắc chắn muốn xóa tài khoản này?')) return;
        try {
            const res = await fetch(`${API_USERS_URL}/${id}`, { method: 'DELETE' });
            const data = await res.json();
            if (res.ok) {
                showNotification('Xóa tài khoản thành công!', 'success');
                fetchUsers();
            } else {
                showNotification(data.message || 'Không thể xóa tài khoản.', 'error');
            }
        } catch (err) {
            showNotification('Lỗi kết nối khi xóa.', 'error');
        }
    };

    return (
        <div style={{ ...styles.container, position: 'relative' }}>
            <div
                style={{
                    position: 'fixed',
                    top: '20px',
                    right: '20px',
                    zIndex: 1100,
                    padding: '12px 16px',
                    borderRadius: '8px',
                    boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1)',
                    fontSize: '14px',
                    fontWeight: 600,
                    color: '#ffffff',
                    backgroundColor: notification.type === 'error' ? '#e11d48' : '#059669',
                    opacity: notification.visible ? 1 : 0,
                    transform: notification.visible ? 'translateY(0)' : 'translateY(-8px)',
                    transition: 'all 0.5s ease-in-out',
                    pointerEvents: notification.visible ? 'auto' : 'none'
                }}
            >
                {notification.message}
            </div>

            <div style={styles.header}>
                <h2>Quản Lý Tài Khoản</h2>
                <button style={styles.addBtn} onClick={() => navigate('/admin/users/create')}>
                    + Thêm Tài Khoản Mới
                </button>
            </div>

            <div style={styles.toolbar}>
                <input
                    type="text"
                    placeholder="Tìm theo tên hoặc email..."
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    style={styles.searchInput}
                />

                <div style={styles.filterGroup}>
                    <label>Lọc Vai trò: </label>
                    <select value={roleFilter} onChange={(e) => setRoleFilter(e.target.value)} style={styles.select}>
                        <option value="ALL">Tất cả ({users.length})</option>
                        <option value="Admin">Admin ({users.filter(u => u.role === 'Admin').length})</option>
                        <option value="User">User ({users.filter(u => u.role === 'User').length})</option>
                    </select>
                </div>
            </div>

            {loading ? (
                <p>Đang tải dữ liệu...</p>
            ) : (
                <table style={styles.table}>
                    <thead>
                        <tr>
                            <th style={styles.th}>ID</th>
                            <th style={styles.th}>Họ tên</th>
                            <th style={styles.th}>Email</th>
                            <th style={styles.th}>Số ĐT</th>
                            <th style={styles.th}>Vai trò</th>
                            <th style={styles.th}>Trình độ</th>
                            <th style={{ ...styles.th, textAlign: 'right' }}>Hành động</th>
                        </tr>
                    </thead>
                    <tbody>
                        {filteredUsers.length === 0 ? (
                            <tr><td colSpan="7" style={{ textAlign: 'center', padding: '20px' }}>Không có tài khoản nào.</td></tr>
                        ) : (
                            filteredUsers.map((u) => (
                                <tr key={u.id}>
                                    <td style={styles.td}>{u.id}</td>
                                    <td style={styles.td}>{u.name} {u.id === 1 && <span style={{ fontSize: '11px', color: '#6366f1', fontWeight: 'bold' }}>(Gốc)</span>}</td>
                                    <td style={styles.td}>{u.email}</td>
                                    <td style={styles.td}>{u.phone || '---'}</td>
                                    <td style={styles.td}>
                                        <span style={u.role === 'Admin' ? styles.badgeAdmin : styles.badgeUser}>
                                            {u.role}
                                        </span>
                                    </td>
                                    <td style={styles.td}>{u.currentLevel}</td>
                                    <td style={{ ...styles.td, textAlign: 'right' }}>
                                        <button
                                            onClick={() => navigate(`/admin/users/edit/${u.id}`)}
                                            style={styles.editBtn}
                                        >
                                            Sửa
                                        </button>

                                        {u.id !== 1 ? (
                                            <button onClick={() => handleDelete(u.id)} style={styles.deleteBtn}>Xóa</button>
                                        ) : (
                                            <span style={{ fontSize: '12px', color: '#94a3b8', fontStyle: 'italic' }}>Không thể xóa</span>
                                        )}
                                    </td>
                                </tr>
                            ))
                        )}
                    </tbody>
                </table>
            )}
        </div>
    );
}

const styles = {
    container: { padding: '30px', fontFamily: 'Arial, sans-serif', backgroundColor: '#f8fafc', minHeight: '100vh' },
    header: { display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' },
    addBtn: { backgroundColor: '#10b981', color: '#fff', padding: '10px 16px', border: 'none', borderRadius: '6px', cursor: 'pointer', fontWeight: 'bold' },
    toolbar: { display: 'flex', justifyContent: 'space-between', marginBottom: '20px', backgroundColor: '#fff', padding: '15px', borderRadius: '8px', boxShadow: '0 1px 3px rgba(0,0,0,0.1)' },
    searchInput: { width: '300px', padding: '8px 12px', border: '1px solid #cbd5e1', borderRadius: '6px' },
    filterGroup: { display: 'flex', alignItems: 'center', gap: '10px' },
    select: { padding: '8px 12px', border: '1px solid #cbd5e1', borderRadius: '6px' },
    table: { width: '100%', borderCollapse: 'collapse', backgroundColor: '#fff', borderRadius: '8px', overflow: 'hidden', boxShadow: '0 1px 3px rgba(0,0,0,0.1)' },
    th: { backgroundColor: '#f1f5f9', padding: '12px', textAlign: 'left', borderBottom: '1px solid #e2e8f0' },
    td: { padding: '12px', borderBottom: '1px solid #e2e8f0' },
    badgeAdmin: { backgroundColor: '#ef4444', color: '#fff', padding: '4px 8px', borderRadius: '4px', fontSize: '12px', fontWeight: 'bold' },
    badgeUser: { backgroundColor: '#3b82f6', color: '#fff', padding: '4px 8px', borderRadius: '4px', fontSize: '12px', fontWeight: 'bold' },
    editBtn: { backgroundColor: '#3b82f6', color: '#fff', border: 'none', padding: '6px 12px', borderRadius: '4px', cursor: 'pointer', marginRight: '6px' },
    deleteBtn: { backgroundColor: '#ef4444', color: '#fff', border: 'none', padding: '6px 12px', borderRadius: '4px', cursor: 'pointer' }
};