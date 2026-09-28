import React, { useEffect, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';

const API_USERS_URL = 'http://localhost:5208/api/Users';

export default function UserEdit() {
    const { id } = useParams();
    const navigate = useNavigate();

    const [formData, setFormData] = useState({
        name: '',
        email: '',
        password: '',
        phone: '',
        role: 'User',
        currentLevel: 'Sơ cấp',
        accountType: 'Tiêu chuẩn (Free)',
        isPro: false
    });
    const [message, setMessage] = useState('');
    const [loading, setLoading] = useState(true);

    const isSuperAdmin = Number(id) === 1;

    useEffect(() => {
        const fetchUserDetail = async () => {
            try {
                const res = await fetch(`${API_USERS_URL}/${id}`);
                if (res.ok) {
                    const data = await res.json();
                    setFormData({
                        name: data.name,
                        email: data.email,
                        password: '',
                        phone: data.phone || '',
                        role: data.role,
                        currentLevel: data.currentLevel || 'Sơ cấp',
                        accountType: data.accountType || 'Tiêu chuẩn (Free)',
                        isPro: data.isPro || false
                    });
                } else {
                    setMessage('Không tìm thấy tài khoản.');
                }
            } catch (err) {
                setMessage('Lỗi kết nối API.');
            } finally {
                setLoading(false);
            }
        };

        fetchUserDetail();
    }, [id]);

    const handleChange = (e) => {
        const { name, value, type, checked } = e.target;
        setFormData({ ...formData, [name]: type === 'checkbox' ? checked : value });
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setMessage('');

        const dataToSubmit = isSuperAdmin ? { ...formData, role: 'Admin' } : formData;

        try {
            const res = await fetch(`${API_USERS_URL}/${id}`, {
                method: 'PUT',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(dataToSubmit)
            });

            if (res.ok) {
                // Chuyển hướng về trang danh sách kèm theo state thông báo thành công
                navigate('/admin/users', { 
                    state: { notification: { message: 'Cập nhật tài khoản thành công!', type: 'success' } } 
                });
            } else {
                const data = await res.json();
                setMessage(data.message || 'Cập nhật thất bại.');
            }
        } catch (err) {
            setMessage('Lỗi kết nối API.');
        }
    };

    if (loading) return <div style={{ padding: '40px', textAlign: 'center' }}>Đang tải dữ liệu tài khoản...</div>;

    return (
        <div style={styles.container}>
            <div style={styles.card}>
                <h2>Chỉnh Sửa Tài Khoản #{id} {isSuperAdmin && <span style={{fontSize: '14px', color: '#6366f1'}}>(Admin Tối Cao)</span>}</h2>
                {message && <div style={styles.alert}>{message}</div>}

                <form onSubmit={handleSubmit}>
                    <div style={styles.group}>
                        <label>Họ và tên</label>
                        <input type="text" name="name" required value={formData.name} onChange={handleChange} style={styles.input} />
                    </div>

                    <div style={styles.group}>
                        <label>Email</label>
                        <input type="email" name="email" required value={formData.email} onChange={handleChange} style={styles.input} />
                    </div>

                    <div style={styles.group}>
                        <label>Mật khẩu mới (Để trống nếu giữ nguyên)</label>
                        <input type="password" name="password" value={formData.password} onChange={handleChange} style={styles.input} />
                    </div>

                    <div style={styles.group}>
                        <label>Số điện thoại</label>
                        <input type="text" name="phone" value={formData.phone} onChange={handleChange} style={styles.input} />
                    </div>

                    <div style={styles.group}>
                        <label>
                            Vai trò (Role) 
                            {isSuperAdmin && <span style={{ color: '#ef4444', fontSize: '12px' }}> (Không được thay đổi Admin tối cao)</span>}
                        </label>
                        <select 
                            name="role" 
                            value={formData.role} 
                            onChange={handleChange} 
                            disabled={isSuperAdmin}
                            style={{
                                ...styles.input, 
                                backgroundColor: isSuperAdmin ? '#f1f5f9' : '#fff',
                                cursor: isSuperAdmin ? 'not-allowed' : 'pointer'
                            }}
                        >
                            <option value="User">User</option>
                            <option value="Admin">Admin</option>
                        </select>
                    </div>

                    <div style={styles.group}>
                        <label>Trình độ</label>
                        <select name="currentLevel" value={formData.currentLevel} onChange={handleChange} style={styles.input}>
                            <option value="Sơ cấp">Sơ cấp</option>
                            <option value="Trung cấp">Trung cấp</option>
                            <option value="Cao cấp">Cao cấp</option>
                        </select>
                    </div>

                    <div style={styles.btnGroup}>
                        <button type="submit" style={styles.saveBtn}>Lưu Cập Nhật</button>
                        <button type="button" onClick={() => navigate('/admin/users')} style={styles.backBtn}>Hủy / Quay lại</button>
                    </div>
                </form>
            </div>
        </div>
    );
}

const styles = {
    container: { display: 'flex', justifyContent: 'center', padding: '40px 0', backgroundColor: '#f1f5f9', minHeight: '100vh' },
    card: { width: '450px', padding: '30px', backgroundColor: '#fff', borderRadius: '10px', boxShadow: '0 4px 10px rgba(0,0,0,0.1)' },
    group: { marginBottom: '15px', display: 'flex', flexDirection: 'column', gap: '5px' },
    input: { padding: '10px', borderRadius: '6px', border: '1px solid #cbd5e1' },
    btnGroup: { display: 'flex', gap: '10px', marginTop: '20px' },
    saveBtn: { flex: 1, padding: '12px', backgroundColor: '#3b82f6', color: '#fff', border: 'none', borderRadius: '6px', cursor: 'pointer', fontWeight: 'bold' },
    backBtn: { flex: 1, padding: '12px', backgroundColor: '#64748b', color: '#fff', border: 'none', borderRadius: '6px', cursor: 'pointer' },
    alert: { padding: '10px', backgroundColor: '#fee2e2', color: '#991b1b', borderRadius: '6px', marginBottom: '15px' }
};