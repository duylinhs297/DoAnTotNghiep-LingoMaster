import React, { useState, useEffect } from 'react';

export default function QuizItemManager({ topic, onBack, apiBaseUrl = '/api/CourseAdmin' }) {
    const [quizItems, setQuizItems] = useState([]);
    const [loading, setLoading] = useState(false);
    
    // Đồng hồ 50s đảo câu hỏi
    const [timeLeft, setTimeLeft] = useState(50);
    const [shuffleCount, setShuffleCount] = useState(0);

    // === PHẦN THÊM MỚI: Quản lý phân trang (5 câu hỏi / trang) ===
    const [currentPage, setCurrentPage] = useState(1);
    const pageSize = 5;

    // Form Modal Thêm/Sửa state
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [editingItem, setEditingItem] = useState(null);
    const [formData, setFormData] = useState({
        question: '',
        optionA: '',
        optionB: '',
        optionC: '',
        optionD: '',
        correctOption: 'A'
    });

    // Detail / Preview Modal state
    const [isDetailModalOpen, setIsDetailModalOpen] = useState(false);
    const [detailItem, setDetailItem] = useState(null);

    // State quản lý thông báo nổi mờ dần (Toast Notification)
    const [notification, setNotification] = useState({ message: '', type: 'success', visible: false });

    // Hàm hiển thị thông báo tự ẩn sau 1 giây
    const showNotification = (message, type = 'success') => {
        setNotification({ message, type, visible: true });
        setTimeout(() => {
            setNotification(prev => ({ ...prev, visible: false }));
        }, 1000);
    };

    // 1. Load danh sách câu hỏi
    const fetchQuizItems = async () => {
        if (!topic?.id) return;
        setLoading(true);
        try {
            const res = await fetch(`${apiBaseUrl}/quiz-items?topicId=${topic.id}`);
            const data = await res.json();
            setQuizItems(data || []);
            setCurrentPage(1); // Reset về trang 1 khi tải lại danh sách mới
        } catch (error) {
            console.error('Lỗi tải câu hỏi trắc nghiệm:', error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchQuizItems();
    }, [topic?.id]);

    // 2. Timer 50 giây đảo vị trí câu hỏi
    useEffect(() => {
        const timer = setInterval(() => {
            setTimeLeft((prev) => {
                if (prev <= 1) {
                    handleShuffleQuestions();
                    return 50; // reset lại mốc 50s tự động
                }
                return prev - 1;
            });
        }, 1000);
        return () => clearInterval(timer);
    }, [quizItems]);

    // Hàm đảo ngẫu nhiên mảng câu hỏi hiện tại + reset time về 50s
    const handleShuffleQuestions = () => {
        setQuizItems((prevList) => {
            const shuffled = [...prevList].sort(() => Math.random() - 0.5);
            return shuffled;
        });
        setShuffleCount((c) => c + 1);
        setTimeLeft(50); // Reset thời gian chạy lại từ đầu khi bấm đảo ngay
    };

    // 3. Mở modal Thêm/Sửa
    const handleOpenAdd = () => {
        setEditingItem(null);
        setFormData({ question: '', optionA: '', optionB: '', optionC: '', optionD: '', correctOption: 'A' });
        setIsModalOpen(true);
    };

    const handleOpenEdit = (item) => {
        setEditingItem(item);
        setFormData({
            question: item.question || '',
            optionA: item.optionA || '',
            optionB: item.optionB || '',
            optionC: item.optionC || '',
            optionD: item.optionD || '',
            correctOption: item.correctOption || 'A'
        });
        setIsModalOpen(true);
    };

    // 4. Mở modal Chi tiết/Preview (đảo đáp án A/B/C/D xem trước)
    const handleOpenPreview = (item) => {
        const shuffledOpts = [
            { key: 'A', text: item.optionA },
            { key: 'B', text: item.optionB },
            { key: 'C', text: item.optionC },
            { key: 'D', text: item.optionD },
        ].sort(() => Math.random() - 0.5);

        setDetailItem({
            ...item,
            shuffledOptions: shuffledOpts
        });
        setIsDetailModalOpen(true);
    };

    // 5. Lưu (Thêm / Sửa)
    const handleSave = async (e) => {
        e.preventDefault();
        if (!formData.question.trim()) {
            showNotification('Vui lòng nhập nội dung câu hỏi!', 'error');
            return;
        }

        try {
            if (editingItem) {
                const res = await fetch(`${apiBaseUrl}/quiz-item/${editingItem.id}`, {
                    method: 'PUT',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ ...formData, topicId: topic.id })
                });
                if (res.ok) {
                    showNotification('Cập nhật câu hỏi thành công!', 'success');
                } else {
                    showNotification('Cập nhật thất bại!', 'error');
                }
            } else {
                const res = await fetch(`${apiBaseUrl}/quiz-item`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ ...formData, topicId: topic.id })
                });
                if (res.ok) {
                    showNotification('Thêm câu hỏi mới thành công!', 'success');
                } else {
                    showNotification('Thêm thất bại!', 'error');
                }
            }
            setIsModalOpen(false);
            fetchQuizItems();
        } catch (error) {
            console.error('Lỗi lưu câu hỏi:', error);
            showNotification('Có lỗi xảy ra khi lưu!', 'error');
        }
    };

    // 6. Xóa câu hỏi
    const handleDelete = async (id) => {
        if (!window.confirm('Bạn có chắc muốn xóa câu hỏi này không?')) return;
        try {
            const res = await fetch(`${apiBaseUrl}/quiz-item/${id}`, { method: 'DELETE' });
            if (res.ok) {
                showNotification('Đã xóa câu hỏi thành công!', 'success');
                
                // Tính toán lại trang nếu xóa hết câu hỏi ở trang cuối
                const totalPagesAfterDelete = Math.ceil((quizItems.length - 1) / pageSize);
                if (currentPage > totalPagesAfterDelete && totalPagesAfterDelete > 0) {
                    setCurrentPage(totalPagesAfterDelete);
                }

                setQuizItems((prev) => prev.filter((i) => i.id !== id));
            } else {
                showNotification('Xóa thất bại!', 'error');
            }
        } catch (error) {
            console.error('Lỗi xóa câu hỏi:', error);
            showNotification('Không thể kết nối đến máy chủ!', 'error');
        }
    };

    // === TÍNH TOÁN DỮ LIỆU PHÂN TRANG ===
    const totalPages = Math.ceil(quizItems.length / pageSize);
    const startIndex = (currentPage - 1) * pageSize;
    const currentItems = quizItems.slice(startIndex, startIndex + pageSize);

    return (
        <div style={{ ...styles.container, position: 'relative' }}>
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

            {/* Header thông tin chủ đề & đồng hồ đảo câu 50s */}
            <div style={styles.headerBar}>
                <div>
                    <button style={styles.backBtn} onClick={onBack}>← Quay lại danh sách chủ đề</button>
                    <h2 style={{ margin: '8px 0 0 0' }}>Quản lý Trắc Nghiệm: {topic?.title}</h2>
                    <span style={{ fontSize: '13px', color: '#64748b' }}>
                        Giới hạn thời gian mỗi ô/câu: <b>{topic?.timeLimitSeconds || 20}s</b> | Đã đảo thứ tự: {shuffleCount} lần
                    </span>
                </div>
                
                <div style={styles.timerBadge}>
                    <span>🔄 Đảo câu sau:</span>
                    <strong style={{ fontSize: '18px', color: timeLeft <= 10 ? '#dc2626' : '#2563eb' }}>
                        {timeLeft}s
                    </strong>
                    <button style={styles.manualShuffleBtn} onClick={handleShuffleQuestions} title="Đảo ngẫu nhiên ngay và reset đồng hồ">
                        Đảo ngay
                    </button>
                </div>
            </div>

            {/* Action bar */}
            <div style={styles.actionBar}>
                <span>Tổng số câu hỏi: <strong>{quizItems.length}</strong></span>
                <button style={styles.addBtn} onClick={handleOpenAdd}>+ Thêm Câu Hỏi Mới</button>
            </div>

            {/* Bảng danh sách câu hỏi */}
            {loading ? (
                <p style={{ textAlign: 'center', padding: '20px' }}>Đang tải danh sách câu hỏi...</p>
            ) : (
                <>
                    <table style={styles.table}>
                        <thead>
                            <tr>
                                <th style={styles.th}>STT</th>
                                <th style={styles.th}>ID</th>
                                <th style={styles.th}>Câu Hỏi</th>
                                <th style={styles.th}>Đáp Án A</th>
                                <th style={styles.th}>Đáp Án B</th>
                                <th style={styles.th}>Đáp Án C</th>
                                <th style={styles.th}>Đáp Án D</th>
                                <th style={styles.th}>Đúng</th>
                                <th style={styles.th}>Thao Tác</th>
                            </tr>
                        </thead>
                        <tbody>
                            {quizItems.length === 0 ? (
                                <tr><td colSpan="9" style={{ textAlign: 'center', padding: '20px' }}>Chưa có câu hỏi trắc nghiệm nào.</td></tr>
                            ) : (
                                currentItems.map((item, index) => {
                                    const absoluteIndex = startIndex + index;
                                    return (
                                        <tr key={item.id}>
                                            <td style={styles.td}>{absoluteIndex + 1}</td>
                                            <td style={styles.td}>{item.id}</td>
                                            <td style={{ ...styles.td, fontWeight: 'bold' }}>{item.question}</td>
                                            <td style={styles.td}>{item.optionA}</td>
                                            <td style={styles.td}>{item.optionB}</td>
                                            <td style={styles.td}>{item.optionC}</td>
                                            <td style={styles.td}>{item.optionD}</td>
                                            <td style={{ ...styles.td, color: '#16a34a', fontWeight: 'bold', textAlign: 'center' }}>
                                                {item.correctOption}
                                            </td>
                                            <td style={styles.td}>
                                                <button onClick={() => handleOpenPreview(item)} style={styles.detailBtn}>Chi tiết</button>
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
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: '16px', paddingTop: '16px', borderTop: '1px solid #e2e8f0', background: '#fff', padding: '12px 16px', borderRadius: '8px' }}>
                            <button
                                onClick={() => setCurrentPage(prev => Math.max(prev - 1, 1))}
                                disabled={currentPage === 1}
                                style={{ ...styles.pageBtn, opacity: currentPage === 1 ? 0.5 : 1, cursor: currentPage === 1 ? 'not-allowed' : 'pointer' }}
                            >
                                Trang trước
                            </button>
                            <span style={{ fontSize: '14px', color: '#475569' }}>
                                Trang <strong>{currentPage}</strong> / {totalPages} (Tổng số: {quizItems.length} câu hỏi)
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

            {/* MODAL Thêm / Sửa câu hỏi */}
            {isModalOpen && (
                <div style={styles.modalOverlay}>
                    <div style={styles.modalContent}>
                        <h3 style={{ marginTop: 0 }}>{editingItem ? 'Sửa Câu Hỏi Trắc Nghiệm' : 'Thêm Câu Hỏi Trắc Nghiệm'}</h3>
                        <form onSubmit={handleSave}>
                            <label style={styles.label}>Nội dung câu hỏi:</label>
                            <textarea
                                value={formData.question}
                                onChange={(e) => setFormData({ ...formData, question: e.target.value })}
                                style={styles.textarea}
                                required
                            />

                            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '10px', marginTop: '10px' }}>
                                <div>
                                    <label style={styles.label}>Đáp án A:</label>
                                    <input type="text" value={formData.optionA} onChange={(e) => setFormData({ ...formData, optionA: e.target.value })} style={styles.input} required />
                                </div>
                                <div>
                                    <label style={styles.label}>Đáp án B:</label>
                                    <input type="text" value={formData.optionB} onChange={(e) => setFormData({ ...formData, optionB: e.target.value })} style={styles.input} required />
                                </div>
                                <div>
                                    <label style={styles.label}>Đáp án C:</label>
                                    <input type="text" value={formData.optionC} onChange={(e) => setFormData({ ...formData, optionC: e.target.value })} style={styles.input} required />
                                </div>
                                <div>
                                    <label style={styles.label}>Đáp án D:</label>
                                    <input type="text" value={formData.optionD} onChange={(e) => setFormData({ ...formData, optionD: e.target.value })} style={styles.input} required />
                                </div>
                            </div>

                            <label style={{ ...styles.label, marginTop: '12px' }}>Đáp án đúng:</label>
                            <select
                                value={formData.correctOption}
                                onChange={(e) => setFormData({ ...formData, correctOption: e.target.value })}
                                style={styles.select}
                            >
                                <option value="A">A</option>
                                <option value="B">B</option>
                                <option value="C">C</option>
                                <option value="D">D</option>
                            </select>

                            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px', marginTop: '20px' }}>
                                <button type="button" style={styles.cancelBtn} onClick={() => setIsModalOpen(false)}>Hủy</button>
                                <button type="submit" style={styles.addBtn}>Lưu Câu Hỏi</button>
                            </div>
                        </form>
                    </div>
                </div>
            )}

            {/* MODAL Chi tiết/Preview (Hiển thị câu hỏi + đảo đáp án) */}
            {isDetailModalOpen && detailItem && (
                <div style={styles.modalOverlay}>
                    <div style={{ ...styles.modalContent, width: '550px' }}>
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
                            <h3 style={{ margin: 0 }}>🔍 Xem Chi Tiết & Đảo Lựa Chọn</h3>
                            <button onClick={() => handleOpenPreview(detailItem)} style={styles.manualShuffleBtn}>🔄 Đảo lại đáp án này</button>
                        </div>
                        
                        <div style={{ background: '#f8fafc', padding: '16px', borderRadius: '8px', border: '1px solid #e2e8f0', marginBottom: '16px' }}>
                            <p style={{ fontWeight: 'bold', fontSize: '15px', marginTop: 0 }}>Q: {detailItem.question}</p>
                            <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
                                {detailItem.shuffledOptions.map((opt, idx) => (
                                    <div key={idx} style={{ 
                                        padding: '8px 12px', 
                                        background: '#fff', 
                                        borderRadius: '6px', 
                                        border: '1px solid #cbd5e1',
                                        display: 'flex',
                                        justifyContent: 'space-between'
                                    }}>
                                        <span><b>Lựa chọn hiển thị #{idx + 1}:</b> {opt.text}</span>
                                        <span style={{ fontSize: '12px', color: '#64748b' }}>(Gốc: {opt.key})</span>
                                    </div>
                                ))}
                            </div>
                            <div style={{ marginTop: '12px', fontSize: '13px', color: '#16a34a', fontWeight: 'bold' }}>
                                ✅ Đáp án đúng thực tế: {detailItem.correctOption}
                            </div>
                        </div>

                        <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px' }}>
                            <button type="button" style={styles.cancelBtn} onClick={() => setIsDetailModalOpen(false)}>Đóng</button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}

// Bảng style giao diện nội bộ gọn gàng
const styles = {
    container: { padding: '20px', background: '#f8fafc', minHeight: '100vh', fontFamily: 'sans-serif' },
    headerBar: { display: 'flex', justifyContent: 'space-between', alignItems: 'center', background: '#fff', padding: '16px', borderRadius: '12px', boxShadow: '0 1px 3px rgba(0,0,0,0.1)', marginBottom: '16px' },
    backBtn: { background: 'none', border: 'none', color: '#2563eb', cursor: 'pointer', fontWeight: 'bold', padding: 0 },
    timerBadge: { display: 'flex', alignItems: 'center', gap: '8px', background: '#eff6ff', padding: '8px 14px', borderRadius: '8px', border: '1px solid #bfdbfe' },
    manualShuffleBtn: { background: '#2563eb', color: '#fff', border: 'none', padding: '4px 8px', borderRadius: '4px', cursor: 'pointer', fontSize: '12px' },
    actionBar: { display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '14px' },
    addBtn: { background: '#16a34a', color: '#fff', border: 'none', padding: '8px 16px', borderRadius: '8px', cursor: 'pointer', fontWeight: 'bold' },
    table: { width: '100%', borderCollapse: 'collapse', background: '#fff', borderRadius: '8px', overflow: 'hidden', boxShadow: '0 1px 3px rgba(0,0,0,0.05)' },
    th: { background: '#f1f5f9', padding: '10px', textAlign: 'left', fontSize: '13px', color: '#475569', borderBottom: '1px solid #e2e8f0' },
    td: { padding: '10px', fontSize: '13px', borderBottom: '1px solid #f1f5f9' },
    detailBtn: { background: '#64748b', color: '#fff', border: 'none', padding: '4px 10px', borderRadius: '4px', cursor: 'pointer', marginRight: '6px' },
    editBtn: { background: '#3b82f6', color: '#fff', border: 'none', padding: '4px 10px', borderRadius: '4px', cursor: 'pointer', marginRight: '6px' },
    deleteBtn: { background: '#ef4444', color: '#fff', border: 'none', padding: '4px 10px', borderRadius: '4px', cursor: 'pointer' },
    pageBtn: { backgroundColor: '#f1f5f9', color: '#334155', border: '1px solid #cbd5e1', padding: '6px 14px', borderRadius: '6px', fontSize: '13px', fontWeight: '500' },
    modalOverlay: { position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, background: 'rgba(0,0,0,0.5)', display: 'flex', justifyContent: 'center', alignItems: 'center', zIndex: 1000 },
    modalContent: { background: '#fff', padding: '24px', borderRadius: '12px', width: '500px', maxWidth: '90%', boxShadow: '0 4px 6px rgba(0,0,0,0.1)' },
    label: { display: 'block', fontSize: '13px', color: '#475569', marginBottom: '4px', fontWeight: '500' },
    input: { width: '100%', padding: '8px', borderRadius: '6px', border: '1px solid #cbd5e1', boxSizing: 'border-box' },
    textarea: { width: '100%', padding: '8px', borderRadius: '6px', border: '1px solid #cbd5e1', minHeight: '60px', boxSizing: 'border-box' },
    select: { width: '100%', padding: '8px', borderRadius: '6px', border: '1px solid #cbd5e1', boxSizing: 'border-box' },
    cancelBtn: { background: '#e2e8f0', color: '#475569', border: 'none', padding: '8px 16px', borderRadius: '8px', cursor: 'pointer' }
};