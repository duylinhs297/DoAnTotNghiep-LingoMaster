import React, { useEffect, useState } from 'react';

const API_BASE = 'http://localhost:5208/api/CourseAdmin';

export default function VocabItemManager({ topic, onBack }) {
    const [items, setItems] = useState([]);
    const [loading, setLoading] = useState(false);
    
    // State cho Modal (Thêm/Sửa)
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [editingId, setEditingId] = useState(null);
    const [form, setForm] = useState({
        word: '',
        phonetic: '',
        meaning: '',
        example: ''
    });

    // State quản lý thông báo nổi mờ dần
    const [notification, setNotification] = useState({ message: '', type: 'success', visible: false });

    // === PHẦN THÊM MỚI: Quản lý phân trang (5 từ vựng / trang) ===
    const [currentPage, setCurrentPage] = useState(1);
    const pageSize = 5;

    // Hàm hiển thị thông báo tự ẩn sau 1 giây
    const showNotification = (message, type = 'success') => {
        setNotification({ message, type, visible: true });
        setTimeout(() => {
            setNotification(prev => ({ ...prev, visible: false }));
        }, 1000);
    };

    // 1. Tải danh sách từ vựng theo TopicId
    const fetchVocabItems = async () => {
        setLoading(true);
        try {
            const res = await fetch(`${API_BASE}/vocab-items?topicId=${topic.id}`);
            if (res.ok) {
                const data = await res.json();
                setItems(data);
                setCurrentPage(1); // Reset về trang 1 khi tải lại danh sách mới
            }
        } catch (error) {
            console.error("Lỗi lấy danh sách từ vựng:", error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        if (topic?.id) {
            fetchVocabItems();
        }
    }, [topic]);

    // Mở modal Thêm mới
    const handleOpenAdd = () => {
        setEditingId(null);
        setForm({ word: '', phonetic: '', meaning: '', example: '' });
        setIsModalOpen(true);
    };

    // Mở modal Chỉnh sửa
    const handleOpenEdit = (item) => {
        setEditingId(item.id);
        setForm({
            word: item.word || '',
            phonetic: item.phonetic || '',
            meaning: item.meaning || '',
            example: item.example || ''
        });
        setIsModalOpen(true);
    };

    // 2. Xử lý Thêm mới hoặc Cập nhật (POST / PUT)
    const handleSubmit = async (e) => {
        e.preventDefault();
        if (!form.word.trim() || !form.meaning.trim()) {
            showNotification("Vui lòng nhập Từ vựng và Nghĩa!", 'error');
            return;
        }

        const payload = {
            id: editingId || 0,
            topicId: topic.id,
            word: form.word.trim(),
            phonetic: form.phonetic.trim(),
            meaning: form.meaning.trim(),
            example: form.example.trim()
        };

        try {
            const url = editingId 
                ? `${API_BASE}/vocab-item/${editingId}`
                : `${API_BASE}/vocab-item`;
            const method = editingId ? 'PUT' : 'POST';

            const res = await fetch(url, {
                method: method,
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(payload)
            });

            if (res.ok) {
                showNotification(editingId ? "Cập nhật thành công!" : "Thêm từ vựng thành công!", 'success');
                setIsModalOpen(false);
                fetchVocabItems();
            } else {
                const err = await res.json();
                showNotification(`Lỗi: ${err.message || 'Không thể lưu dữ liệu'}`, 'error');
            }
        } catch (error) {
            console.error("Lỗi lưu từ vựng:", error);
            showNotification("Không thể kết nối đến máy chủ!", 'error');
        }
    };

    // 3. Xử lý Xóa từ vựng (DELETE)
    const handleDelete = async (id) => {
        if (!window.confirm("Bạn có chắc chắn muốn xóa từ vựng này?")) return;

        try {
            const res = await fetch(`${API_BASE}/vocab-item/${id}`, { method: 'DELETE' });
            if (res.ok) {
                showNotification("Đã xóa từ vựng thành công!", 'success');
                
                // Tính toán lại trang nếu xóa hết từ vựng của trang cuối
                const totalPagesAfterDelete = Math.ceil((items.length - 1) / pageSize);
                if (currentPage > totalPagesAfterDelete && totalPagesAfterDelete > 0) {
                    setCurrentPage(totalPagesAfterDelete);
                }

                fetchVocabItems();
            } else {
                showNotification("Xóa thất bại!", 'error');
            }
        } catch (error) {
            console.error("Lỗi xóa từ vựng:", error);
            showNotification("Không thể kết nối đến máy chủ!", 'error');
        }
    };

    // === TÍNH TOÁN DỮ LIỆU PHÂN TRANG ===
    const totalPages = Math.ceil(items.length / pageSize);
    const startIndex = (currentPage - 1) * pageSize;
    const currentItems = items.slice(startIndex, startIndex + pageSize);

    return (
        <div style={{ backgroundColor: '#fff', padding: '24px', borderRadius: '8px', boxShadow: '0 1px 3px rgba(0,0,0,0.1)', position: 'relative' }}>
            {/* Thanh thông báo nổi mờ dần */}
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

            {/* Header */}
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
                <div>
                    <button onClick={onBack} style={styles.backBtn}>← Quay lại danh sách chủ đề</button>
                    <h3 style={{ margin: '10px 0 0 0' }}>Quản Lý Từ Vựng: <span style={{ color: '#2563eb' }}>{topic.title}</span></h3>
                </div>
                <button onClick={handleOpenAdd} style={styles.addBtn}>+ Thêm Từ Vựng Mới</button>
            </div>

            {/* Bảng Danh Sách Từ Vựng */}
            {loading ? (
                <p>Đang tải dữ liệu...</p>
            ) : (
                <>
                    <table style={styles.table}>
                        <thead>
                            <tr>
                                <th style={styles.th}>STT</th>
                                <th style={styles.th}>Từ Vựng (Word)</th>
                                <th style={styles.th}>Phiên Âm (Phonetic)</th>
                                <th style={styles.th}>Nghĩa (Meaning)</th>
                                <th style={styles.th}>Ví Dụ (Example)</th>
                                <th style={styles.th}>Thao Tác</th>
                            </tr>
                        </thead>
                        <tbody>
                            {items.length === 0 ? (
                                <tr>
                                    <td colSpan="6" style={{ textAlign: 'center', padding: '24px', color: '#64748b' }}>
                                        Chưa có từ vựng nào trong chủ đề này. Bấm "+ Thêm Từ Vựng Mới" để thêm.
                                    </td>
                                </tr>
                            ) : (
                                currentItems.map((item, index) => {
                                    const absoluteIndex = startIndex + index;
                                    return (
                                        <tr key={item.id}>
                                            <td style={styles.td}>{absoluteIndex + 1}</td>
                                            <td style={{ ...styles.td, fontWeight: 'bold', color: '#1e293b' }}>{item.word}</td>
                                            <td style={{ ...styles.td, color: '#059669' }}>{item.phonetic}</td>
                                            <td style={{ ...styles.td, fontWeight: '500' }}>{item.meaning}</td>
                                            <td style={{ ...styles.td, fontStyle: 'italic', color: '#475569' }}>{item.example}</td>
                                            <td style={styles.td}>
                                                <button onClick={() => handleOpenEdit(item)} style={styles.editBtn}>Sửa</button>
                                                <button onClick={() => handleDelete(item.id)} style={styles.deleteBtn}>Xóa</button>
                                            </td>
                                        </tr>
                                    );
                                })
                            )}
                        </tbody>
                    </table>

                    {/* Thanh chuyển trang (Pagination Controls) */}
                    {totalPages > 1 && (
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: '16px', paddingTop: '16px', borderTop: '1px solid #e2e8f0' }}>
                            <button
                                onClick={() => setCurrentPage(prev => Math.max(prev - 1, 1))}
                                disabled={currentPage === 1}
                                style={{ ...styles.pageBtn, opacity: currentPage === 1 ? 0.5 : 1, cursor: currentPage === 1 ? 'not-allowed' : 'pointer' }}
                            >
                                Trang trước
                            </button>
                            <span style={{ fontSize: '14px', color: '#475569' }}>
                                Trang <strong>{currentPage}</strong> / {totalPages} (Tổng số: {items.length} từ)
                            </span>
                            <button
                                onClick={() => setCurrentPage(prev => Math.min(prev + 1, totalPages))}
                                disabled={currentPage === totalPages}
                                style={{ ...styles.pageBtn, opacity: currentPage === totalPages ? 0.5 : 1, cursor: currentPage === totalPages ? 'not-allowed' : 'pointer' }}
                            >
                                Trang sau
                            </button>
                        </div>
                    )}
                </>
            )}

            {/* Modal Thêm / Sửa Từ Vựng */}
            {isModalOpen && (
                <div style={styles.modalOverlay}>
                    <div style={styles.modalContent}>
                        <h4 style={{ marginTop: 0, marginBottom: '16px' }}>
                            {editingId ? `Chỉnh Sửa Từ Vựng #${editingId}` : 'Thêm Từ Vựng Mới'}
                        </h4>
                        <form onSubmit={handleSubmit}>
                            <div style={styles.field}>
                                <label style={styles.label}>Từ Vựng (Word): *</label>
                                <input
                                    type="text"
                                    required
                                    placeholder="VD: Hello, Family,..."
                                    value={form.word}
                                    onChange={(e) => setForm({ ...form, word: e.target.value })}
                                    style={styles.input}
                                    autoFocus
                                />
                            </div>

                            <div style={styles.field}>
                                <label style={styles.label}>Phiên Âm (Phonetic):</label>
                                <input
                                    type="text"
                                    placeholder="VD: /həˈloʊ/"
                                    value={form.phonetic}
                                    onChange={(e) => setForm({ ...form, phonetic: e.target.value })}
                                    style={styles.input}
                                />
                            </div>

                            <div style={styles.field}>
                                <label style={styles.label}>Nghĩa Của Từ (Meaning): *</label>
                                <input
                                    type="text"
                                    required
                                    placeholder="VD: Xin chào, Gia đình..."
                                    value={form.meaning}
                                    onChange={(e) => setForm({ ...form, meaning: e.target.value })}
                                    style={styles.input}
                                />
                            </div>

                            <div style={styles.field}>
                                <label style={styles.label}>Ví Dụ (Example):</label>
                                <textarea
                                    rows="3"
                                    placeholder="VD: Hello, nice to meet you!"
                                    value={form.example}
                                    onChange={(e) => setForm({ ...form, example: e.target.value })}
                                    style={{ ...styles.input, resize: 'vertical' }}
                                />
                            </div>

                            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px', marginTop: '20px' }}>
                                <button type="button" onClick={() => setIsModalOpen(false)} style={styles.cancelBtn}>
                                    Hủy
                                </button>
                                <button type="submit" style={styles.saveBtn}>
                                    {editingId ? 'Cập Nhật' : 'Thêm Mới'}
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            )}
        </div>
    );
}

const styles = {
    backBtn: { backgroundColor: '#e2e8f0', color: '#334155', border: 'none', padding: '6px 12px', borderRadius: '6px', cursor: 'pointer', fontSize: '13px' },
    addBtn: { backgroundColor: '#10b981', color: '#fff', border: 'none', padding: '8px 16px', borderRadius: '6px', fontWeight: 'bold', cursor: 'pointer' },
    table: { width: '100%', borderCollapse: 'collapse', marginTop: '10px' },
    th: { backgroundColor: '#f8fafc', padding: '12px', textAlign: 'left', borderBottom: '2px solid #e2e8f0', color: '#475569', fontSize: '14px' },
    td: { padding: '12px', borderBottom: '1px solid #e2e8f0', fontSize: '14px' },
    editBtn: { backgroundColor: '#3b82f6', color: '#fff', border: 'none', padding: '5px 10px', borderRadius: '4px', cursor: 'pointer', marginRight: '6px' },
    deleteBtn: { backgroundColor: '#ef4444', color: '#fff', border: 'none', padding: '5px 10px', borderRadius: '4px', cursor: 'pointer' },
    pageBtn: { backgroundColor: '#f1f5f9', color: '#334155', border: '1px solid #cbd5e1', padding: '6px 14px', borderRadius: '6px', fontSize: '13px', fontWeight: '500' },
    modalOverlay: { position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, backgroundColor: 'rgba(0,0,0,0.5)', display: 'flex', justifyContent: 'center', alignItems: 'center', zIndex: 1000 },
    modalContent: { backgroundColor: '#fff', padding: '24px', borderRadius: '8px', width: '450px', maxWidth: '90%', boxShadow: '0 4px 12px rgba(0,0,0,0.15)' },
    field: { marginBottom: '14px', display: 'flex', flexDirection: 'column', gap: '4px' },
    label: { fontSize: '13px', fontWeight: 'bold', color: '#334155' },
    input: { padding: '8px 12px', border: '1px solid #cbd5e1', borderRadius: '6px', fontSize: '14px' },
    cancelBtn: { backgroundColor: '#64748b', color: '#fff', border: 'none', padding: '8px 16px', borderRadius: '6px', cursor: 'pointer' },
    saveBtn: { backgroundColor: '#2563eb', color: '#fff', border: 'none', padding: '8px 16px', borderRadius: '6px', fontWeight: 'bold', cursor: 'pointer' }
};