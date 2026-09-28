import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';

const API_BASE_URL = 'http://localhost:5208/api/Auth';

export default function AuthPage() {
    const navigate = useNavigate();

    const [isLogin, setIsLogin] = useState(true);
    const [formData, setFormData] = useState({
        name: '',
        email: '',
        password: '',
        phone: ''
    });
    const [message, setMessage] = useState('');
    const [loading, setLoading] = useState(false);

    const handleChange = (e) => {
        setFormData({ ...formData, [e.target.name]: e.target.value });
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setLoading(true);
        setMessage('');

        if (!isLogin && formData.password.length < 6) {
            setMessage('Mật khẩu phải có ít nhất 6 ký tự!');
            setLoading(false);
            return;
        }

        const endpoint = isLogin ? `${API_BASE_URL}/login` : `${API_BASE_URL}/register`;
        const payload = isLogin
            ? { 
                email: formData.email.trim(), 
                password: formData.password 
              }
            : { 
                name: formData.name.trim(), 
                email: formData.email.trim(), 
                password: formData.password, 
                phone: formData.phone.trim() 
              };

        try {
            const response = await fetch(endpoint, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json'
                },
                body: JSON.stringify(payload)
            });

            const data = await response.json();

            if (response.ok) {
                if (isLogin) {
                    setMessage(`Đăng nhập thành công! Vai trò: ${data.user.role}`);
                    
                    // 1. Lưu token xác thực
                    localStorage.setItem('token', data.token);
                    // 2. QUAN TRỌNG: Lưu role để AdminRoute ở App.jsx nhận diện quyền Admin
                    localStorage.setItem('role', data.user.role); 
                    // 3. Lưu toàn bộ đối tượng user (nếu cần hiển thị thông tin)
                    localStorage.setItem('user', JSON.stringify(data.user));

                    // Kiểm tra nếu là Admin thì đẩy vào /admin, nếu không thì về trang chủ /
                    if (data.user.role === 'Admin') {
                        navigate('/admin');
                    } else {
                        navigate('/');
                    }
                } else {
                    setMessage(data.message || 'Đăng ký thành công!');
                    setIsLogin(true); // Chuyển về form đăng nhập sau khi đăng ký thành công
                }
            } else {
                if (data.errors) {
                    const errorMessages = Object.values(data.errors).flat().join(' | ');
                    setMessage(`Lỗi nhập liệu: ${errorMessages}`);
                } else {
                    setMessage(data.message || 'Yêu cầu không hợp lệ (400)');
                }
            }
        } catch (err) {
            setMessage('Không thể kết nối tới server API.');
        } finally {
            setLoading(false);
        }
    };

    return (
        <div style={styles.container}>
            <div style={styles.card}>
                <h2>{isLogin ? 'Đăng Nhập Quản Trị' : 'Đăng Ký Tài Khoản'}</h2>

                {message && <div style={styles.alert}>{message}</div>}

                <form onSubmit={handleSubmit}>
                    {!isLogin && (
                        <div style={styles.group}>
                            <label>Họ và tên</label>
                            <input
                                type="text"
                                name="name"
                                value={formData.name}
                                onChange={handleChange}
                                required
                                style={styles.input}
                            />
                        </div>
                    )}

                    <div style={styles.group}>
                        <label>Email</label>
                        <input
                            type="email"
                            name="email"
                            value={formData.email}
                            onChange={handleChange}
                            required
                            style={styles.input}
                        />
                    </div>

                    <div style={styles.group}>
                        <label>Mật khẩu</label>
                        <input
                            type="password"
                            name="password"
                            value={formData.password}
                            onChange={handleChange}
                            required
                            style={styles.input}
                        />
                    </div>

                    {!isLogin && (
                        <div style={styles.group}>
                            <label>Số điện thoại</label>
                            <input
                                type="text"
                                name="phone"
                                value={formData.phone}
                                onChange={handleChange}
                                style={styles.input}
                            />
                        </div>
                    )}

                    <button type="submit" disabled={loading} style={styles.button}>
                        {loading ? 'Đang xử lý...' : isLogin ? 'Đăng Nhập' : 'Đăng Ký'}
                    </button>
                </form>

                <p style={styles.toggleText} onClick={() => setIsLogin(!isLogin)}>
                    {isLogin ? 'Chưa có tài khoản? Đăng ký ngay' : 'Đã có tài khoản? Đăng nhập'}
                </p>
            </div>
        </div>
    );
}

const styles = {
    container: { display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: '100vh', backgroundColor: '#f1f5f9' },
    card: { width: '360px', padding: '30px', borderRadius: '12px', backgroundColor: '#fff', boxShadow: '0 4px 12px rgba(0,0,0,0.1)' },
    group: { marginBottom: '15px', display: 'flex', flexDirection: 'column', gap: '5px' },
    input: { padding: '10px', borderRadius: '6px', border: '1px solid #cbd5e1', fontSize: '14px' },
    button: { width: '100%', padding: '12px', backgroundColor: '#4f46e5', color: '#fff', border: 'none', borderRadius: '6px', cursor: 'pointer', fontWeight: 'bold' },
    alert: { padding: '10px', marginBottom: '15px', borderRadius: '6px', backgroundColor: '#e0e7ff', color: '#3730a3', fontSize: '13px' },
    toggleText: { marginTop: '15px', textAlign: 'center', color: '#4f46e5', cursor: 'pointer', fontSize: '14px' }
};