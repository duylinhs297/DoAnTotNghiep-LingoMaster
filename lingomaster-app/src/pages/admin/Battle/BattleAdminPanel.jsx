import React, { useState, useEffect } from 'react';
import BattleQuestionManager from './BattleQuestionManager';

const API_BASE = 'http://localhost:5208/api/admin/battle';

export default function BattleAdminPanel() {
    const [stages, setStages] = useState([]);
    const [loading, setLoading] = useState(false);
    const [formData, setFormData] = useState({
        id: '',
        title: '',
        subtitle: '',
        questionsCount: 40,
        timeLimit: '15 phút',
        colorHex: '#3B82F6',
    });
    const [editingId, setEditingId] = useState(null);
    const [activeStage, setActiveStage] = useState(null);

    // State quản lý Modal Bảng xếp hạng
    const [activeLeaderboardStage, setActiveLeaderboardStage] = useState(null);
    const [leaderboardData, setLeaderboardData] = useState([]);
    const [leaderboardLoading, setLeaderboardLoading] = useState(false);

    // State quản lý thông báo mờ dần
    const [notification, setNotification] = useState({ message: '', type: 'success', visible: false });

    // Hàm hiển thị thông báo tự ẩn sau 1 giây
    const showNotification = (message, type = 'success') => {
        setNotification({ message, type, visible: true });
        setTimeout(() => {
            setNotification(prev => ({ ...prev, visible: false }));
        }, 1000);
    };

    const fetchStages = async () => {
    setLoading(true);
    try {
        const res = await fetch(API_BASE);
        if (!res.ok) throw new Error(`HTTP status ${res.status}`);
        const data = await res.json();

        // Sắp xếp lại danh sách: Màn tạo trước (ví dụ theo tiêu đề hoặc ID) lên trước
        const sortedStages = (data.data || []).sort((a, b) => {
            // Nếu ID hoặc tên có dạng "Màn 1", "Màn 2", bạn có thể so sánh chuỗi hoặc số:
            return a.id.localeCompare(b.id, undefined, { numeric: true });
        });

        setStages(sortedStages);
    } catch (err) {
        console.error('Không tải được danh sách màn chơi:', err.message);
    } finally {
        setLoading(false);
    }
};

    useEffect(() => {
        fetchStages();
    }, []);

    // Lấy dữ liệu bảng xếp hạng khi mở modal
    useEffect(() => {
        if (!activeLeaderboardStage) {
            setLeaderboardData([]);
            return;
        }

        const fetchLeaderboard = async () => {
            setLeaderboardLoading(true);
            try {
                const res = await fetch(`${API_BASE}/${activeLeaderboardStage.id}/leaderboard`);
                if (!res.ok) throw new Error('Không thể tải bảng xếp hạng');
                const data = await res.json();
                setLeaderboardData(data.data || []);
            } catch (err) {
                console.error(err);
                setLeaderboardData([]);
            } finally {
                setLeaderboardLoading(false);
            }
        };

        fetchLeaderboard();
    }, [activeLeaderboardStage]);

    const handleSave = async (e) => {
        e.preventDefault();
        try {
            const isEditing = Boolean(editingId);
            const url = isEditing ? `${API_BASE}/${editingId}` : API_BASE;
            const method = isEditing ? 'PUT' : 'POST';

            const res = await fetch(url, {
                method,
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(formData),
            });
            if (!res.ok) throw new Error('Lưu thất bại');

            setEditingId(null);
            setFormData({ id: '', title: '', subtitle: '', questionsCount: 40, timeLimit: '15 phút', colorHex: '#3B82F6' });
            fetchStages();
            
            // Hiển thị thông báo thành công
            showNotification(isEditing ? 'Cập nhật màn chơi thành công!' : 'Thêm màn chơi mới thành công!', 'success');
        } catch (err) {
            showNotification('Lỗi lưu dữ liệu: ' + err.message, 'error');
        }
    };

    const handleDelete = async (id) => {
        if (!window.confirm('Bạn có chắc muốn xóa màn này?')) return;
        try {
            const res = await fetch(`${API_BASE}/${id}`, { method: 'DELETE' });
            const data = await res.json();

            if (!res.ok) {
                throw new Error(data.message || 'Xóa thất bại');
            }

            fetchStages();
            showNotification(data.message || 'Đã xóa màn chơi thành công!', 'success');
        } catch (err) {
            showNotification(err.message, 'error');
        }
    };

    const handleDeleteLeaderboardItem = async (resultId) => {
        if (!window.confirm('Bạn có chắc muốn xóa kết quả này khỏi bảng xếp hạng?')) return;
        try {
            const res = await fetch(`${API_BASE}/${activeLeaderboardStage.id}/leaderboard/${resultId}`, { method: 'DELETE' });
            if (!res.ok) throw new Error('Xóa thất bại');

            setLeaderboardData(prev => prev.filter(item => item.id !== resultId));
            showNotification('Đã xóa kết quả khỏi bảng xếp hạng!', 'success');
        } catch (err) {
            showNotification('Lỗi xóa: ' + err.message, 'error');
        }
    };

    const handleCancelEdit = () => {
        setEditingId(null);
        setFormData({ id: '', title: '', subtitle: '', questionsCount: 40, timeLimit: '15 phút', colorHex: '#3B82F6' });
    };

    return (
        <div className="p-8 max-w-7xl mx-auto bg-slate-50 min-h-screen relative">
            {/* Thanh thông báo nổi mờ dần */}
            <div
                className={`fixed top-5 right-5 z-50 px-4 py-3 rounded-xl shadow-lg text-sm font-semibold text-white transition-all duration-500 transform ${
                    notification.visible ? 'opacity-100 translate-y-0' : 'opacity-0 -translate-y-2 pointer-events-none'
                } ${notification.type === 'error' ? 'bg-rose-600' : 'bg-emerald-600'}`}
            >
                {notification.message}
            </div>

            {/* Header */}
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-8">
                <div>
                    <h1 className="text-2xl font-extrabold text-slate-900 tracking-tight">Quản trị Màn Chơi Thi Đấu</h1>
                    <p className="text-sm text-slate-500 mt-1">Cấu hình danh sách màn chơi, thời gian và số lượng câu hỏi.</p>
                </div>
                <button
                    onClick={fetchStages}
                    className="inline-flex items-center gap-1.5 px-4 py-2 text-sm font-medium text-slate-700 bg-white border border-slate-300 rounded-lg shadow-sm hover:bg-slate-50 transition"
                >
                    🔄 Làm mới
                </button>
            </div>

            {/* Form Card */}
            <div className="bg-white rounded-2xl shadow-sm border border-slate-200 p-6 mb-8">
                <div className="flex items-center justify-between mb-4 pb-3 border-b border-slate-100">
                    <h2 className="text-base font-bold text-slate-800">
                        {editingId ? `Chỉnh sửa màn chơi: ${editingId}` : '➕ Thêm màn chơi mới'}
                    </h2>
                    {editingId && (
                        <button
                            type="button"
                            onClick={handleCancelEdit}
                            className="text-xs font-semibold text-slate-500 hover:text-slate-800 underline"
                        >
                            Hủy sửa
                        </button>
                    )}
                </div>

                <form onSubmit={handleSave} className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
                    <div className="sm:col-span-2">
                        <label className="block text-xs font-semibold text-slate-600 uppercase tracking-wider mb-1.5">Tiêu đề màn</label>
                        <input
                            type="text"
                            placeholder="VD: Màn 1: Từ vựng căn bản"
                            value={formData.title}
                            onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                            className="w-full px-3.5 py-2.5 text-sm bg-slate-50 border border-slate-300 rounded-lg focus:bg-white focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500 transition"
                            required
                        />
                    </div>

                    <div className="sm:col-span-2">
                        <label className="block text-xs font-semibold text-slate-600 uppercase tracking-wider mb-1.5">Mô tả phụ</label>
                        <input
                            type="text"
                            placeholder="VD: 40 câu hỏi trắc nghiệm nhanh"
                            value={formData.subtitle}
                            onChange={(e) => setFormData({ ...formData, subtitle: e.target.value })}
                            className="w-full px-3.5 py-2.5 text-sm bg-slate-50 border border-slate-300 rounded-lg focus:bg-white focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500 transition"
                        />
                    </div>

                    <div>
                        <label className="block text-xs font-semibold text-slate-600 uppercase tracking-wider mb-1.5">Số câu hỏi</label>
                        <input
                            type="number"
                            min="0"
                            readOnly
                            value={formData.questionsCount}
                            className="w-full px-3.5 py-2.5 text-sm bg-slate-100 border border-slate-300 rounded-lg text-slate-500"
                        />
                    </div>

                    <div>
                        <label className="block text-xs font-semibold text-slate-600 uppercase tracking-wider mb-1.5">Thời gian</label>
                        <input
                            type="text"
                            placeholder="VD: 15 phút"
                            value={formData.timeLimit}
                            onChange={(e) => setFormData({ ...formData, timeLimit: e.target.value })}
                            className="w-full px-3.5 py-2.5 text-sm bg-slate-50 border border-slate-300 rounded-lg focus:bg-white focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500 transition"
                            required
                        />
                    </div>

                    <div>
                        <label className="block text-xs font-semibold text-slate-600 uppercase tracking-wider mb-1.5">Màu nhận diện</label>
                        <div className="flex items-center gap-2">
                            <input
                                type="color"
                                value={formData.colorHex}
                                onChange={(e) => setFormData({ ...formData, colorHex: e.target.value })}
                                className="w-10 h-10 p-0 border border-slate-300 rounded-lg cursor-pointer bg-transparent"
                            />
                            <input
                                type="text"
                                value={formData.colorHex}
                                onChange={(e) => setFormData({ ...formData, colorHex: e.target.value })}
                                className="flex-1 px-3.5 py-2.5 text-sm bg-slate-50 border border-slate-300 rounded-lg font-mono focus:bg-white focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500 transition"
                            />
                        </div>
                    </div>

                    <div className="flex items-end">
                        <button
                            type="submit"
                            className="w-full py-2.5 px-4 bg-indigo-600 hover:bg-indigo-700 text-white font-semibold text-sm rounded-lg shadow-sm transition active:scale-[0.99]"
                        >
                            {editingId ? '💾 Lưu thay đổi' : '✨ Thêm màn chơi'}
                        </button>
                    </div>
                </form>
            </div>

            {/* Table Card */}
            <div className="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">
                <div className="px-6 py-4 border-b border-slate-100 flex items-center justify-between">
                    <h3 className="text-sm font-bold text-slate-800">Danh sách màn chơi ({stages.length})</h3>
                </div>

                {loading ? (
                    <div className="p-12 text-center text-sm text-slate-500">Đang tải danh sách...</div>
                ) : stages.length === 0 ? (
                    <div className="p-12 text-center text-sm text-slate-500">Chưa có màn chơi nào được cấu hình.</div>
                ) : (
                    <div className="overflow-x-auto">
                        <table className="w-full text-left border-collapse">
                            <thead>
                                <tr className="bg-slate-50/80 border-b border-slate-200 text-xs font-semibold text-slate-500 uppercase tracking-wider">
                                    <th className="py-3.5 px-6">Màu</th>
                                    <th className="py-3.5 px-6">ID</th>
                                    <th className="py-3.5 px-6">Tiêu đề & Mô tả</th>
                                    <th className="py-3.5 px-6">Số câu</th>
                                    <th className="py-3.5 px-6">Thời gian</th>
                                    <th className="py-3.5 px-6 text-right">Thao tác</th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-slate-100 text-sm">
                                {stages.map((st) => (
                                    <tr key={st.id} className="hover:bg-slate-50/60 transition">
                                        <td className="py-4 px-6 w-16">
                                            <span
                                                className="inline-block w-6 h-6 rounded-full border border-slate-200 shadow-xs"
                                                style={{ backgroundColor: st.colorHex || '#3B82F6' }}
                                            />
                                        </td>
                                        <td className="py-4 px-6 font-mono text-xs text-slate-500">{st.id}</td>
                                        <td className="py-4 px-6">
                                            <div className="font-semibold text-slate-900">{st.title}</div>
                                            {st.subtitle && <div className="text-xs text-slate-500 mt-0.5">{st.subtitle}</div>}
                                        </td>
                                        <td className="py-4 px-6 font-medium text-slate-700">{st.questions?.length ?? st.questionsCount} câu</td>
                                        <td className="py-4 px-6 font-medium text-slate-700">{st.timeLimit}</td>
                                        <td className="py-4 px-6 text-right space-x-2">
                                            <button
                                                onClick={() => setActiveLeaderboardStage(st)}
                                                className="inline-flex items-center px-3 py-1.5 text-xs font-semibold text-amber-700 bg-amber-50 hover:bg-amber-100 rounded-lg transition"
                                            >
                                                🏆 Xếp hạng
                                            </button>
                                            <button
                                                onClick={() => setActiveStage(st)}
                                                className="inline-flex items-center px-3 py-1.5 text-xs font-semibold text-emerald-700 bg-emerald-50 hover:bg-emerald-100 rounded-lg transition"
                                            >
                                                📝 Câu hỏi
                                            </button>
                                            <button
                                                onClick={() => {
                                                    setEditingId(st.id);
                                                    setFormData({
                                                        id: st.id,
                                                        title: st.title || '',
                                                        subtitle: st.subtitle || '',
                                                        questionsCount: st.questions?.length ?? 40,
                                                        timeLimit: st.timeLimit || '15 phút',
                                                        colorHex: st.colorHex || '#3B82F6',
                                                    });
                                                }}
                                                className="inline-flex items-center px-3 py-1.5 text-xs font-semibold text-indigo-600 bg-indigo-50 hover:bg-indigo-100 rounded-lg transition"
                                            >
                                                Sửa
                                            </button>
                                            <button
                                                onClick={() => handleDelete(st.id)}
                                                className="inline-flex items-center px-3 py-1.5 text-xs font-semibold text-rose-600 bg-rose-50 hover:bg-rose-100 rounded-lg transition"
                                            >
                                                Xóa
                                            </button>
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                )}
            </div>

            {/* Modal Quản lý câu hỏi tách rời */}
            <BattleQuestionManager
                activeStage={activeStage}
                onClose={() => setActiveStage(null)}
                onQuestionsUpdated={fetchStages}
            />

            {/* Modal Hiển thị Bảng xếp hạng */}
            {activeLeaderboardStage && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
                    <div className="bg-white rounded-2xl shadow-xl w-full max-w-3xl overflow-hidden flex flex-col max-h-[85vh]">
                        <div className="px-6 py-4 border-b border-slate-100 flex items-center justify-between bg-slate-50">
                            <div>
                                <h3 className="text-base font-bold text-slate-800">
                                    🏆 Bảng xếp hạng: {activeLeaderboardStage.title}
                                </h3>
                                <p className="text-xs text-slate-500">Danh sách kết quả thi đấu của người chơi</p>
                            </div>
                            <button
                                onClick={() => setActiveLeaderboardStage(null)}
                                className="text-slate-400 hover:text-slate-600 font-bold text-lg px-2"
                            >
                                ✕
                            </button>
                        </div>

                        <div className="p-6 overflow-y-auto flex-1">
                            {leaderboardLoading ? (
                                <div className="text-center py-12 text-sm text-slate-500">Đang tải bảng xếp hạng...</div>
                            ) : leaderboardData.length === 0 ? (
                                <div className="text-center py-12 text-sm text-slate-500">Chưa có dữ liệu xếp hạng cho màn chơi này.</div>
                            ) : (
                                <table className="w-full text-left border-collapse">
                                    <thead>
                                        <tr className="border-b border-slate-200 text-xs font-semibold text-slate-500 uppercase">
                                            <th className="py-3 px-4">Thứ hạng</th>
                                            <th className="py-3 px-4">Người chơi</th>
                                            <th className="py-3 px-4">Điểm số</th>
                                            <th className="py-3 px-4">Thời gian</th>
                                            <th className="py-3 px-4 text-right">Thao tác</th>
                                        </tr>
                                    </thead>
                                    <tbody className="divide-y divide-slate-100 text-sm">
                                        {leaderboardData.map((item, index) => (
                                            <tr key={item.id || index} className="hover:bg-slate-50">
                                                <td className="py-3 px-4 font-bold text-slate-700">
                                                    {index === 0 ? '🥇 1' : index === 1 ? '🥈 2' : index === 2 ? '🥉 3' : index + 1}
                                                </td>
                                                <td className="py-3 px-4 font-medium text-slate-900">{item.userName || item.studentName || 'Ẩn danh'}</td>
                                                <td className="py-3 px-4 text-indigo-600 font-semibold">{item.score} điểm</td>
                                                <td className="py-3 px-4 text-slate-600">{item.timeSpent || item.time || 'N/A'}</td>
                                                <td className="py-3 px-4 text-right">
                                                    <button
                                                        onClick={() => handleDeleteLeaderboardItem(item.id)}
                                                        className="px-2.5 py-1 text-xs font-semibold text-rose-600 bg-rose-50 hover:bg-rose-100 rounded transition"
                                                    >
                                                        Xóa
                                                    </button>
                                                </td>
                                            </tr>
                                        ))}
                                    </tbody>
                                </table>
                            )}
                        </div>

                        <div className="px-6 py-3 border-t border-slate-100 bg-slate-50 text-right">
                            <button
                                onClick={() => setActiveLeaderboardStage(null)}
                                className="px-4 py-2 bg-slate-200 hover:bg-slate-300 text-slate-700 font-semibold text-sm rounded-lg transition"
                            >
                                Đóng
                            </button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}