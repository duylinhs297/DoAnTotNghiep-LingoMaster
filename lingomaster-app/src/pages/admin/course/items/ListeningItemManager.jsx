import React, { useEffect, useState } from 'react';

const API_BASE = 'http://localhost:5208/api/CourseAdmin';

const styles = {
    backBtn: { backgroundColor: '#e2e8f0', color: '#334155', border: 'none', padding: '6px 12px', borderRadius: '6px', cursor: 'pointer', fontSize: '13px' },
    addBtn: { backgroundColor: '#10b981', color: '#fff', border: 'none', padding: '8px 16px', borderRadius: '6px', fontWeight: 'bold', cursor: 'pointer' },
    table: { width: '100%', borderCollapse: 'collapse', marginTop: '10px' },
    th: { backgroundColor: '#f8fafc', padding: '12px', textAlign: 'left', borderBottom: '2px solid #e2e8f0', color: '#475569', fontSize: '14px' },
    td: { padding: '12px', borderBottom: '1px solid #e2e8f0', fontSize: '14px' },
    editBtn: { backgroundColor: '#3b82f6', color: '#fff', border: 'none', padding: '5px 10px', borderRadius: '4px', cursor: 'pointer', marginRight: '6px' },
    deleteBtn: { backgroundColor: '#ef4444', color: '#fff', border: 'none', padding: '5px 10px', borderRadius: '4px', cursor: 'pointer' },
    modalOverlay: { position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, backgroundColor: 'rgba(0,0,0,0.5)', display: 'flex', justifyContent: 'center', alignItems: 'center', zIndex: 1000 },
    modalContent: { backgroundColor: '#fff', padding: '24px', borderRadius: '8px', width: '450px', maxWidth: '90%', boxShadow: '0 4px 12px rgba(0,0,0,0.15)' },
    field: { marginBottom: '14px', display: 'flex', flexDirection: 'column', gap: '4px' },
    label: { fontSize: '13px', fontWeight: 'bold', color: '#334155' },
    input: { padding: '8px 12px', border: '1px solid #cbd5e1', borderRadius: '6px', fontSize: '14px' },
    textarea: { padding: '8px 12px', border: '1px solid #cbd5e1', borderRadius: '6px', fontSize: '14px', minHeight: '80px', fontFamily: 'inherit' },
    cancelBtn: { backgroundColor: '#64748b', color: '#fff', border: 'none', padding: '8px 16px', borderRadius: '6px', cursor: 'pointer' },
    saveBtn: { backgroundColor: '#2563eb', color: '#fff', border: 'none', padding: '8px 16px', borderRadius: '6px', fontWeight: 'bold', cursor: 'pointer' }
};

export default function ListeningItemManager({ topic, onBack }) {
    const [items, setItems] = useState([]);
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [editingItem, setEditingItem] = useState(null);

    const [form, setForm] = useState({
        audioUrl: 'tts_engine',
        transcript: ''
    });

    // State quản lý thông báo nổi mờ dần (Toast Notification)
    const [notification, setNotification] = useState({ message: '', type: 'success', visible: false });

    // Hàm hiển thị thông báo tự ẩn sau 1 giây
    const showNotification = (message, type = 'success') => {
        setNotification({ message, type, visible: true });
        setTimeout(() => {
            setNotification(prev => ({ ...prev, visible: false }));
        }, 1000);
    };

    const fetchItems = async () => {
        try {
            const res = await fetch(`${API_BASE}/listening-items?topicId=${topic.id}`);
            if (res.ok) {
                const data = await res.json();
                setItems(data);
            }
        } catch (error) {
            console.error('Lỗi tải danh sách bài nghe:', error);
        }
    };

    useEffect(() => {
        if (topic?.id) fetchItems();
    }, [topic]);

    const handleOpenAdd = () => {
        setEditingItem(null);
        setForm({ audioUrl: 'tts_engine', transcript: '' });
        setIsModalOpen(true);
    };

    const handleOpenEdit = (item) => {
        setEditingItem(item);
        setForm({
            audioUrl: item.audioUrl || 'tts_engine',
            transcript: item.transcript || ''
        });
        setIsModalOpen(true);
    };

    const handleSave = async (e) => {
        e.preventDefault();
        if (!form.transcript.trim()) {
            showNotification('Vui lòng nhập nội dung Transcript!', 'error');
            return;
        }

        try {
            const url = editingItem
                ? `${API_BASE}/listening-item/${editingItem.id}`
                : `${API_BASE}/listening-item`;
            const method = editingItem ? 'PUT' : 'POST';

            const payload = {
                topicId: topic.id,
                audioUrl: form.audioUrl.trim() || 'tts_engine',
                transcript: form.transcript.trim()
            };

            if (editingItem) payload.id = editingItem.id;

            const res = await fetch(url, {
                method,
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(payload)
            });

            if (res.ok) {
                showNotification(editingItem ? 'Cập nhật bài nghe thành công!' : 'Thêm bài nghe thành công!', 'success');
                setIsModalOpen(false);
                fetchItems();
            } else {
                const err = await res.json();
                showNotification(`Lưu thất bại: ${JSON.stringify(err)}`, 'error');
            }
        } catch (error) {
            console.error('Lỗi khi lưu bài nghe:', error);
            showNotification('Không thể kết nối đến server!', 'error');
        }
    };

    const handleDelete = async (id) => {
        if (!window.confirm('Xác nhận xóa bài nghe này?')) return;
        try {
            const res = await fetch(`${API_BASE}/listening-item/${id}`, { method: 'DELETE' });
            if (res.ok) {
                showNotification('Xóa bài nghe thành công!', 'success');
                fetchItems();
            } else {
                showNotification('Xóa thất bại!', 'error');
            }
        } catch (error) {
            console.error('Lỗi xóa bài nghe:', error);
            showNotification('Không thể kết nối đến server!', 'error');
        }
    };

    return (
        <div style={{ backgroundColor: '#fff', padding: '20px', borderRadius: '12px', boxShadow: '0 1px 3px rgba(0,0,0,0.1)', position: 'relative' }}>
            {/* Thanh thông báo nổi mờ dần (Toast Notification) */}
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

            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                    <button style={styles.backBtn} onClick={onBack}>← Quay lại</button>
                    <h3 style={{ margin: 0, fontSize: '18px', color: '#1e293b' }}>
                        Quản lý Bài nghe: <span style={{ color: '#2563eb' }}>{topic?.title}</span> (Cách 1 - TTS)
                    </h3>
                </div>
                <button style={styles.addBtn} onClick={handleOpenAdd}>+ Thêm bài nghe</button>
            </div>

            <table style={styles.table}>
                <thead>
                    <tr>
                        <th style={styles.th}>ID</th>
                        <th style={styles.th}>Audio Config / Source</th>
                        <th style={styles.th}>Transcript (Nội dung TTS)</th>
                        <th style={{ ...styles.th, textAlign: 'right' }}>Thao tác</th>
                    </tr>
                </thead>
                <tbody>
                    {items.length === 0 ? (
                        <tr>
                            <td colSpan="4" style={{ ...styles.td, textAlign: 'center', color: '#64748b' }}>
                                Chưa có bài nghe nào trong chủ đề này.
                            </td>
                        </tr>
                    ) : (
                        items.map((item) => (
                            <tr key={item.id}>
                                <td style={styles.td}>#{item.id}</td>
                                <td style={styles.td}>
                                    <span style={{ backgroundColor: '#f1f5f9', padding: '4px 8px', borderRadius: '4px', fontSize: '12px', fontFamily: 'monospace' }}>
                                        {item.audioUrl}
                                    </span>
                                </td>
                                <td style={{ ...styles.td, maxWidth: '400px' }}>{item.transcript}</td>
                                <td style={{ ...styles.td, textAlign: 'right' }}>
                                    <button style={styles.editBtn} onClick={() => handleOpenEdit(item)}>Sửa</button>
                                    <button style={styles.deleteBtn} onClick={() => handleDelete(item.id)}>Xóa</button>
                                </td>
                            </tr>
                        ))
                    )}
                </tbody>
            </table>

            {isModalOpen && (
                <div style={styles.modalOverlay}>
                    <div style={styles.modalContent}>
                        <h3 style={{ marginTop: 0, color: '#1e293b' }}>
                            {editingItem ? 'Sửa bài nghe' : 'Thêm bài nghe mới'}
                        </h3>
                        <form onSubmit={handleSave}>
                            <div style={styles.field}>
                                <label style={styles.label}>Audio Config / Mode (mặc định tts_engine)</label>
                                <input
                                    style={styles.input}
                                    value={form.audioUrl}
                                    onChange={(e) => setForm({ ...form, audioUrl: e.target.value })}
                                    placeholder="tts_engine"
                                />
                            </div>
                            <div style={styles.field}>
                                <label style={styles.label}>Transcript (Nội dung tiếng Anh cho Flutter đọc TTS)</label>
                                <textarea
                                    style={styles.textarea}
                                    value={form.transcript}
                                    onChange={(e) => setForm({ ...form, transcript: e.target.value })}
                                    placeholder="Good morning, welcome to our office. Please sign in here."
                                    required
                                />
                            </div>
                            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px', marginTop: '20px' }}>
                                <button type="button" style={styles.cancelBtn} onClick={() => setIsModalOpen(false)}>
                                    Hủy
                                </button>
                                <button type="submit" style={styles.saveBtn}>
                                    Lưu
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            )}
        </div>
    );
}