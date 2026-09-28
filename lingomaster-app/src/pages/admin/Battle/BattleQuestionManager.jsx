import React, { useState, useEffect } from 'react';

const API_BASE = 'http://localhost:5208/api/admin/battle';

export default function BattleQuestionManager({ activeStage, onClose, onQuestionsUpdated }) {
    const [stageQuestions, setStageQuestions] = useState([]);
    const [qLoading, setQLoading] = useState(false);
    const [editingQId, setEditingQId] = useState(null);
    const [questionForm, setQuestionForm] = useState({
        questionText: '',
        options: ['', '', '', ''],
        correctAnswerIndex: 0,
    });
    
    // State quản lý thông báo thành công
    const [successMessage, setSuccessMessage] = useState('');

    // === PHẦN THÊM MỚI: Quản lý phân trang (5 câu / trang) ===
    const [currentPage, setCurrentPage] = useState(1);
    const pageSize = 5;

    const fetchStageQuestions = async (stageId) => {
        setQLoading(true);
        try {
            const res = await fetch(`${API_BASE}/${stageId}/questions`);
            if (!res.ok) throw new Error('Lỗi tải câu hỏi');
            const data = await res.json();
            setStageQuestions(data.data || []);
            setCurrentPage(1); // Reset về trang 1 khi tải lại danh sách
        } catch (err) {
            console.error(err.message);
        } finally {
            setQLoading(false);
        }
    };

    useEffect(() => {
        if (activeStage?.id) {
            fetchStageQuestions(activeStage.id);
            setEditingQId(null);
            setQuestionForm({ questionText: '', options: ['', '', '', ''], correctAnswerIndex: 0 });
        }
    }, [activeStage]);

    if (!activeStage) return null;

    const handleOptionChange = (idx, value) => {
        const newOpts = [...questionForm.options];
        newOpts[idx] = value;
        setQuestionForm({ ...questionForm, options: newOpts });
    };

    const showSuccessToast = (msg) => {
        setSuccessMessage(msg);
        setTimeout(() => {
            setSuccessMessage('');
        }, 1000);
    };

    const handleSaveQuestion = async (e) => {
        e.preventDefault();
        try {
            const isEditing = Boolean(editingQId);
            const url = isEditing
                ? `${API_BASE}/${activeStage.id}/questions/${editingQId}`
                : `${API_BASE}/${activeStage.id}/questions`;
            const method = isEditing ? 'PUT' : 'POST';

            const res = await fetch(url, {
                method,
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(questionForm),
            });
            
            const data = await res.json();
            if (!res.ok || data.success === false) {
                throw new Error(data.message || 'Lưu câu hỏi thất bại');
            }

            showSuccessToast(isEditing ? 'Cập nhật câu hỏi thành công!' : 'Thêm câu hỏi thành công!');

            setEditingQId(null);
            setQuestionForm({ questionText: '', options: ['', '', '', ''], correctAnswerIndex: 0 });
            await fetchStageQuestions(activeStage.id);
            if (onQuestionsUpdated) onQuestionsUpdated();
        } catch (err) {
            alert('Lỗi lưu câu hỏi: ' + err.message);
        }
    };

    const handleDeleteQuestion = async (qId) => {
        if (!window.confirm('Bạn có chắc chắn muốn xóa câu hỏi này?')) return;
        try {
            const res = await fetch(`${API_BASE}/${activeStage.id}/questions/${qId}`, { method: 'DELETE' });
            const data = await res.json().catch(() => ({}));
            
            if (!res.ok || data.success === false) {
                throw new Error(data.message || 'Xóa thất bại');
            }
            
            showSuccessToast('Xóa câu hỏi thành công!');
            
            // Tính toán lại trang nếu xóa hết câu hỏi của trang cuối
            const totalPagesAfterDelete = Math.ceil((stageQuestions.length - 1) / pageSize);
            if (currentPage > totalPagesAfterDelete && totalPagesAfterDelete > 0) {
                setCurrentPage(totalPagesAfterDelete);
            }

            await fetchStageQuestions(activeStage.id);
            if (onQuestionsUpdated) onQuestionsUpdated();
        } catch (err) {
            alert('Lỗi xóa: ' + err.message);
        }
    };

    const handleShuffleQuestions = async () => {
        try {
            const res = await fetch(`${API_BASE}/${activeStage.id}/questions/shuffle`, { method: 'POST' });
            if (!res.ok) throw new Error('Đảo câu thất bại');
            const data = await res.json();
            setStageQuestions(data.data || []);
            setCurrentPage(1); // Về trang 1 sau khi đảo câu
            showSuccessToast('Đảo câu hỏi thành công!');
            if (onQuestionsUpdated) onQuestionsUpdated();
        } catch (err) {
            alert('Lỗi đảo câu: ' + err.message);
        }
    };

    // === TÍNH TOÁN DỮ LIỆU PHÂN TRANG ===
    const totalPages = Math.ceil(stageQuestions.length / pageSize);
    const startIndex = (currentPage - 1) * pageSize;
    const currentQuestions = stageQuestions.slice(startIndex, startIndex + pageSize);

    return (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/50 backdrop-blur-xs p-4">
            <div className="bg-white rounded-2xl shadow-xl w-full max-w-5xl max-h-[90vh] flex flex-col overflow-hidden relative">
                
                {/* Thanh thông báo nổi (Toast Notification) */}
                {successMessage && (
                    <div className="absolute top-4 right-4 z-50 bg-emerald-600 text-white text-xs font-semibold px-4 py-2 rounded-xl shadow-lg transition-opacity duration-300 animate-fade-in">
                        ✨ {successMessage}
                    </div>
                )}

                {/* Modal Header */}
                <div className="px-6 py-4 border-b border-slate-200 flex items-center justify-between bg-slate-50">
                    <div>
                        <h3 className="text-base font-bold text-slate-900">
                            Quản lý câu hỏi: {activeStage.title}
                        </h3>
                        <p className="text-xs text-slate-500">Thêm, sửa, xóa, đảo vị trí câu hỏi kèm 4 đáp án.</p>
                    </div>
                    <div className="flex items-center gap-2">
                        <button
                            onClick={handleShuffleQuestions}
                            className="px-3 py-1.5 text-xs font-semibold bg-amber-50 text-amber-700 hover:bg-amber-100 border border-amber-200 rounded-lg transition"
                        >
                            🔀 Đảo câu hỏi
                        </button>
                        <button
                            onClick={onClose}
                            className="p-1.5 text-slate-400 hover:text-slate-600 rounded-lg"
                        >
                            ✕
                        </button>
                    </div>
                </div>

                {/* Modal Body */}
                <div className="flex-1 grid grid-cols-1 lg:grid-cols-2 overflow-hidden">
                    
                    {/* Left: Danh sách câu hỏi + Phân trang */}
                    <div className="border-r border-slate-200 flex flex-col justify-between overflow-y-auto p-4 bg-slate-50/50">
                        <div>
                            <div className="text-xs font-semibold text-slate-600 uppercase mb-3 flex justify-between items-center">
                                <span>Danh sách ({stageQuestions.length} câu)</span>
                                {totalPages > 1 && (
                                    <span className="text-slate-400 font-normal">Trang {currentPage}/{totalPages}</span>
                                )}
                            </div>

                            {qLoading ? (
                                <div className="text-center py-8 text-xs text-slate-500">Đang tải câu hỏi...</div>
                            ) : stageQuestions.length === 0 ? (
                                <div className="text-center py-8 text-xs text-slate-500">Chưa có câu hỏi nào.</div>
                            ) : (
                                <div className="space-y-3">
                                    {currentQuestions.map((q, index) => {
                                        const absoluteIndex = startIndex + index;
                                        return (
                                            <div
                                                key={q.id}
                                                className={`p-3.5 rounded-xl border bg-white transition ${
                                                    editingQId === q.id ? 'border-indigo-500 ring-1 ring-indigo-500' : 'border-slate-200'
                                                }`}
                                            >
                                                <div className="flex items-start justify-between gap-2">
                                                    <span className="font-semibold text-xs text-indigo-600">
                                                        Câu {q.questionIndex || (absoluteIndex + 1)}:
                                                    </span>
                                                    <div className="flex items-center gap-1.5">
                                                        <button
                                                            onClick={() => {
                                                                setEditingQId(q.id);
                                                                setQuestionForm({
                                                                    questionText: q.questionText || '',
                                                                    options: q.options?.length === 4 ? q.options : ['', '', '', ''],
                                                                    correctAnswerIndex: q.correctAnswerIndex ?? 0,
                                                                });
                                                            }}
                                                            className="px-2 py-1 text-xs bg-slate-100 hover:bg-slate-200 rounded text-slate-700 font-medium"
                                                        >
                                                            Sửa
                                                        </button>
                                                        <button
                                                            onClick={() => handleDeleteQuestion(q.id)}
                                                            className="px-2 py-1 text-xs bg-rose-50 hover:bg-rose-100 rounded text-rose-600 font-medium"
                                                        >
                                                            Xóa
                                                        </button>
                                                    </div>
                                                </div>
                                                <div className="text-xs text-slate-800 font-medium mt-1">
                                                    {q.questionText}
                                                </div>

                                                <div className="text-xs text-slate-600 space-y-1 mt-2.5">
                                                    <div className="font-semibold text-indigo-600">
                                                        Đáp án đúng: Lựa chọn #{q.correctAnswerIndex + 1} ({String.fromCharCode(65 + (q.correctAnswerIndex ?? 0))}) — {q.options?.[q.correctAnswerIndex] || 'Chưa rõ'}
                                                    </div>
                                                    <div className="flex flex-wrap gap-1.5 mt-1">
                                                        {q.options?.map((opt, idx) => (
                                                            <span 
                                                                key={idx} 
                                                                className={`px-2 py-1 rounded text-xs border ${
                                                                    idx === q.correctAnswerIndex 
                                                                        ? 'bg-emerald-100 border-emerald-400 text-emerald-800 font-bold' 
                                                                        : 'bg-slate-50 border-slate-200 text-slate-600'
                                                                }`}
                                                            >
                                                                {String.fromCharCode(65 + idx)}. {opt}
                                                            </span>
                                                        ))}
                                                    </div>
                                                </div>
                                            </div>
                                        );
                                    })}
                                </div>
                            )}
                        </div>

                        {/* Thanh chuyển trang (Pagination Controls) */}
                        {totalPages > 1 && (
                            <div className="flex items-center justify-between pt-4 mt-4 border-t border-slate-200">
                                <button
                                    onClick={() => setCurrentPage(prev => Math.max(prev - 1, 1))}
                                    disabled={currentPage === 1}
                                    className="px-3 py-1 text-xs font-medium bg-white border border-slate-300 rounded-lg disabled:opacity-40 hover:bg-slate-50"
                                >
                                    Trang trước
                                </button>
                                <span className="text-xs text-slate-600">
                                    Trang <strong>{currentPage}</strong> / {totalPages}
                                </span>
                                <button
                                    onClick={() => setCurrentPage(prev => Math.min(prev + 1, totalPages))}
                                    disabled={currentPage === totalPages}
                                    className="px-3 py-1 text-xs font-medium bg-white border border-slate-300 rounded-lg disabled:opacity-40 hover:bg-slate-50"
                                >
                                    Trang sau
                                </button>
                            </div>
                        )}
                    </div>

                    {/* Right: Form Thêm / Sửa câu hỏi + 4 đáp án */}
                    <div className="flex flex-col overflow-y-auto p-4 bg-white">
                        <div className="flex items-center justify-between mb-3">
                            <div className="text-xs font-semibold text-slate-600 uppercase">
                                {editingQId ? '✏️ Đang sửa câu hỏi' : '➕ Thêm câu hỏi mới'}
                            </div>
                            {editingQId && (
                                <button
                                    type="button"
                                    onClick={() => {
                                        setEditingQId(null);
                                        setQuestionForm({ questionText: '', options: ['', '', '', ''], correctAnswerIndex: 0 });
                                    }}
                                    className="text-xs text-slate-500 underline"
                                >
                                    Hủy chọn sửa
                                </button>
                            )}
                        </div>

                        <form onSubmit={handleSaveQuestion} className="space-y-3">
                            <div>
                                <label className="block text-xs font-semibold text-slate-600 mb-1">Nội dung câu hỏi</label>
                                <textarea
                                    rows={2}
                                    value={questionForm.questionText}
                                    onChange={(e) => setQuestionForm({ ...questionForm, questionText: e.target.value })}
                                    placeholder="Nhập nội dung câu hỏi..."
                                    className="w-full px-3 py-2 text-sm bg-slate-50 border border-slate-300 rounded-lg focus:bg-white focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500"
                                    required
                                />
                            </div>

                            <div className="space-y-2">
                                <label className="block text-xs font-semibold text-slate-600">4 Đáp án (chọn đáp án đúng bằng radio)</label>
                                {Array.from({ length: 4 }, (_, optIdx) => (
                                    <div key={optIdx} className="flex items-center gap-2">
                                        <input
                                            type="radio"
                                            name="correctAnswer"
                                            checked={questionForm.correctAnswerIndex === optIdx}
                                            onChange={() => setQuestionForm({ ...questionForm, correctAnswerIndex: optIdx })}
                                            title="Chọn là đáp án đúng"
                                            className="w-4 h-4 text-emerald-600 cursor-pointer"
                                        />
                                        <span className="text-xs font-bold text-slate-500 w-5">
                                            {String.fromCharCode(65 + optIdx)}.
                                        </span>
                                        <input
                                            type="text"
                                            value={questionForm.options[optIdx]}
                                            onChange={(e) => handleOptionChange(optIdx, e.target.value)}
                                            placeholder={`Nhập đáp án ${String.fromCharCode(65 + optIdx)}`}
                                            className="flex-1 px-3 py-1.5 text-sm bg-slate-50 border border-slate-300 rounded-lg focus:bg-white focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500"
                                            required
                                        />
                                    </div>
                                ))}
                            </div>

                            <div className="pt-2">
                                <button
                                    type="submit"
                                    className="w-full py-2.5 px-4 bg-indigo-600 hover:bg-indigo-700 text-white font-semibold text-sm rounded-lg shadow-sm transition"
                                >
                                    {editingQId ? '💾 Cập nhật câu hỏi' : '✨ Thêm câu hỏi vào màn'}
                                </button>
                            </div>
                        </form>
                    </div>
                </div>

                {/* Modal Footer */}
                <div className="px-6 py-3 border-t border-slate-200 bg-slate-50 flex justify-end">
                    <button
                        onClick={onClose}
                        className="px-4 py-2 text-sm font-medium text-slate-700 bg-white border border-slate-300 rounded-lg hover:bg-slate-50"
                    >
                        Đóng
                    </button>
                </div>
            </div>
        </div>
    );
}