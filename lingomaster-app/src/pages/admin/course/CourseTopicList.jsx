import React, { useState } from 'react';

export default function CourseTopicList({
    levels = [],
    selectedLevel,
    setSelectedLevel,
    selectedSkill,
    setSelectedSkill,
    categories = [],
    selectedCategoryId,
    setSelectedCategoryId,
    topics = [],
    onOpenAdd,
    onOpenEdit,
    onDelete,
    onManageItems,
    onAddLevel,
    onEditLevel,       // BỔ SUNG: Sửa cấp độ
    onDeleteLevel,     // BỔ SUNG: Xóa cấp độ
    onAddCategory,
    onEditCategory,    // BỔ SUNG: Sửa danh mục
    onDeleteCategory   // BỔ SUNG: Xóa danh mục
}) {
    const [isLevelModalOpen, setIsLevelModalOpen] = useState(false);
    const [editingLevel, setEditingLevel] = useState(null); // Lưu cấp độ đang sửa
    const [newLevelName, setNewLevelName] = useState('');

    const [isCategoryModalOpen, setIsCategoryModalOpen] = useState(false);
    const [editingCategory, setEditingCategory] = useState(null); // Lưu danh mục đang sửa
    const [categoryForm, setCategoryForm] = useState({ name: '', description: '' });

    // --- XỬ LÝ CẤP ĐỘ ---
    const handleOpenAddLevel = () => {
        setEditingLevel(null);
        setNewLevelName('');
        setIsLevelModalOpen(true);
    };

    const handleOpenEditLevel = (lvl, e) => {
        e.stopPropagation(); // Ngăn việc bấm nút Sửa mà đổi luôn cấp độ đang chọn
        setEditingLevel(lvl);
        setNewLevelName(lvl.name);
        setIsLevelModalOpen(true);
    };

    const handleConfirmSaveLevel = () => {
        if (!newLevelName.trim()) {
            alert("Vui lòng nhập tên cấp độ!");
            return;
        }
        if (editingLevel) {
            if (onEditLevel) onEditLevel(editingLevel.id, newLevelName.trim());
        } else {
            if (onAddLevel) onAddLevel(newLevelName.trim());
        }
        setNewLevelName('');
        setEditingLevel(null);
        setIsLevelModalOpen(false);
    };

    // --- XỬ LÝ DANH MỤC ---
    const handleOpenAddCategory = () => {
        setEditingCategory(null);
        setCategoryForm({ name: '', description: '' });
        setIsCategoryModalOpen(true);
    };

    const handleOpenEditCategory = () => {
        // Cải tiến: Tìm theo ID nhưng hỗ trợ ép kiểu lỏng lẻo (==) để tránh lệch kiểu dữ liệu String/Number
        // Hoặc lấy trực tiếp phần tử đầu tiên nếu categories có dữ liệu mà selectedCategoryId chưa kịp khớp
        let currentCat = categories.find(c => String(c.id) === String(selectedCategoryId));

        // Fallback an toàn nếu vẫn chưa tìm thấy nhưng dropdown đang có giá trị
        if (!currentCat && categories.length > 0) {
            currentCat = categories[0];
        }

        if (!currentCat) {
            alert("Vui lòng chọn một danh mục để sửa!");
            return;
        }

        // Đồng bộ lại selectedCategoryId nếu nó bị lệch kiểu
        if (selectedCategoryId !== currentCat.id) {
            setSelectedCategoryId(currentCat.id);
        }

        setEditingCategory(currentCat);
        setCategoryForm({ name: currentCat.name, description: currentCat.description || '' });
        setIsCategoryModalOpen(true);
    };
    const handleConfirmSaveCategory = () => {
        if (!categoryForm.name.trim()) {
            alert("Vui lòng nhập tên danh mục!");
            return;
        }
        if (!selectedLevel) {
            alert("Vui lòng chọn Cấp Độ Học trước!");
            return;
        }
        if (editingCategory) {
            if (onEditCategory) {
                onEditCategory(editingCategory.id, {
                    name: categoryForm.name.trim(),
                    description: categoryForm.description.trim(),
                    levelId: selectedLevel,
                    skillType: selectedSkill
                });
            }
        } else {
            if (onAddCategory) {
                onAddCategory({
                    name: categoryForm.name.trim(),
                    description: categoryForm.description.trim(),
                    levelId: selectedLevel,
                    skillType: selectedSkill || 'VOCAB'
                });
            }
        }
        setCategoryForm({ name: '', description: '' });
        setEditingCategory(null);
        setIsCategoryModalOpen(false);
    };

    return (
        <div>
            {/* 1. Lọc Cấp Độ */}
            <div style={styles.card}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '8px' }}>
                    <label style={styles.label}>1. Cấp Độ Học (CourseLevel):</label>
                    <button
                        style={{ ...styles.addBtn, padding: '6px 12px', fontSize: '13px' }}
                        onClick={handleOpenAddLevel}
                    >
                        + Thêm Cấp Độ
                    </button>
                </div>

                <div style={styles.btnGroup}>
                    {levels.length === 0 ? (
                        <span style={{ color: '#64748b', fontSize: '14px' }}>Chưa có cấp độ nào. Vui lòng bấm "+ Thêm Cấp Độ" để tạo mới.</span>
                    ) : (
                        levels.map(lvl => {
                            const isSelected = selectedLevel === lvl.id;
                            return (
                                <div
                                    key={lvl.id}
                                    style={{
                                        display: 'inline-flex',
                                        alignItems: 'center', // Đã sửa từ alignItem thành alignItems
                                        backgroundColor: isSelected ? '#2563eb' : '#e2e8f0',
                                        borderRadius: '6px',
                                        overflow: 'hidden',
                                        border: isSelected ? '2px solid #1d4ed8' : '1px solid #cbd5e1'
                                    }}
                                >
                                    <button
                                        style={{
                                            backgroundColor: 'transparent',
                                            color: isSelected ? '#fff' : '#334155',
                                            border: 'none',
                                            padding: '8px 12px',
                                            fontWeight: isSelected ? 'bold' : 'normal',
                                            cursor: 'pointer'
                                        }}
                                        onClick={() => setSelectedLevel(lvl.id)}
                                    >
                                        {lvl.name}
                                    </button>
                                    {/* Nút Sửa/Xóa nhỏ gắn liền với mỗi cấp độ */}
                                    <button
                                        style={{ ...styles.subActionBtn, color: isSelected ? '#ffedd5' : '#3b82f6' }}
                                        title="Sửa cấp độ"
                                        onClick={(e) => handleOpenEditLevel(lvl, e)}
                                    >
                                        ✏️
                                    </button>
                                    <button
                                        style={{ ...styles.subActionBtn, color: isSelected ? '#fee2e2' : '#ef4444', borderLeft: '1px solid rgba(0,0,0,0.1)' }}
                                        title="Xóa cấp độ"
                                        onClick={(e) => {
                                            e.stopPropagation();
                                            if (onDeleteLevel) onDeleteLevel(lvl.id);
                                        }}
                                    >
                                        🗑️
                                    </button>
                                </div>
                            );
                        })
                    )}
                </div>
            </div>

            {/* 2. Lọc Kỹ Năng */}
            <div style={styles.card}>
                <label style={styles.label}>2. Loại Bài Học (SkillType):</label>
                <div style={styles.btnGroup}>
                    {[
                        { key: 'VOCAB', label: '📚 Từ Vựng' },
                        { key: 'SPEAKING', label: '🎙️ Luyện Phát Âm' },
                        { key: 'REVIEW', label: '🧠 Ôn Tập Flashcard' },
                        { key: 'QUIZ', label: '📝 Trắc Nghiệm' },
                        { key: 'LISTENING', label: '🎧 Luyện Nghe' }
                    ].map(item => (
                        <button
                            key={item.key}
                            style={selectedSkill === item.key ? styles.activeSkillBtn : styles.inactiveBtn}
                            onClick={() => setSelectedSkill(item.key)}
                        >
                            {item.label}
                        </button>
                    ))}
                </div>
            </div>

            {/* 3. Chọn Kho Danh Mục */}
            <div style={styles.card}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '8px' }}>
                    <label style={styles.label}>3. Kho Danh Mục (CourseCategory):</label>
                    <div style={{ display: 'flex', gap: '8px' }}>
                        {selectedCategoryId && (
                            <>
                                <button
                                    style={{ ...styles.editBtn, padding: '6px 10px', fontSize: '13px', margin: 0 }}
                                    onClick={handleOpenEditCategory}
                                    title="Sửa danh mục đang chọn"
                                >
                                    ✏️ Sửa Danh Mục
                                </button>
                                <button
                                    style={{ ...styles.deleteBtn, padding: '6px 10px', fontSize: '13px', margin: 0 }}
                                    onClick={() => onDeleteCategory && onDeleteCategory(selectedCategoryId)}
                                    title="Xóa danh mục đang chọn"
                                >
                                    🗑️ Xóa Danh Mục
                                </button>
                            </>
                        )}
                        <button
                            disabled={!selectedLevel}
                            style={selectedLevel ? { ...styles.addBtn, padding: '6px 12px', fontSize: '13px' } : styles.disabledBtn}
                            onClick={handleOpenAddCategory}
                        >
                            + Thêm Danh Mục
                        </button>
                    </div>
                </div>

                <select
                    value={selectedCategoryId || ''}
                    onChange={(e) => setSelectedCategoryId(e.target.value)}
                    style={styles.select}
                >
                    {categories.length === 0 ? (
                        <option value="">-- Chưa có danh mục nào (Bấm "+ Thêm Danh Mục" để tạo) --</option>
                    ) : (
                        categories.map(c => <option key={c.id} value={c.id}>{c.name}</option>)
                    )}
                </select>
            </div>

            {/* Bảng Danh Sách Chủ Đề */}
            <div style={{ marginTop: '20px' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '15px' }}>
                    <h3>Chủ Đề Trong Kho ({topics.length})</h3>
                    <button
                        disabled={!selectedCategoryId}
                        style={selectedCategoryId ? styles.addBtn : styles.disabledBtn}
                        onClick={onOpenAdd}
                    >
                        + Thêm Chủ Đề Mới
                    </button>
                </div>

                <table style={styles.table}>
                    <thead>
                        <tr>
                            <th style={styles.th}>ID</th>
                            <th style={styles.th}>Tên Chủ Đề</th>
                            <th style={styles.th}>Mô Tả Nhanh</th>
                            <th style={styles.th}>Key</th>
                            <th style={styles.th}>Số Lượng</th>
                            <th style={styles.th}>Thời Gian</th>
                            <th style={styles.th}>Thao Tác</th>
                        </tr>
                    </thead>
                    <tbody>
                        {topics.length === 0 ? (
                            <tr><td colSpan="7" style={{ textAlign: 'center', padding: '20px' }}>Chưa có dữ liệu chủ đề.</td></tr>
                        ) : (
                            topics.map(t => (
                                <tr key={t.id}>
                                    <td style={styles.td}>{t.id}</td>
                                    <td style={{ ...styles.td, fontWeight: 'bold' }}>{t.title}</td>
                                    <td style={styles.td}>{t.subtitle}</td>
                                    <td style={styles.td}><code>{t.categoryKey}</code></td>
                                    <td style={styles.td}>{t.itemCount} câu</td>
                                    <td style={styles.td}>
                                        <span style={t.timeLimitSeconds > 0 ? styles.badgeTimer : styles.badgeNoTimer}>
                                            {t.timeLimitSeconds > 0 ? `${t.timeLimitSeconds}s` : 'Không'}
                                        </span>
                                    </td>
                                    <td style={styles.td}>
                                        <button
                                            onClick={() => onManageItems && onManageItems(t)}
                                            style={styles.detailBtn}
                                            title="Nhập/Sửa từ vựng, câu hỏi, audio..."
                                        >
                                            📄 Nội dung
                                        </button>
                                        <button onClick={() => onOpenEdit(t)} style={styles.editBtn}>Sửa</button>
                                        <button onClick={() => onDelete(t.id)} style={styles.deleteBtn}>Xóa</button>
                                    </td>
                                </tr>
                            ))
                        )}
                    </tbody>
                </table>
            </div>

            {/* MODAL: THÊM / SỬA CẤP ĐỘ HỌC */}
            {isLevelModalOpen && (
                <div style={styles.modalOverlay}>
                    <div style={styles.modalContent}>
                        <h4 style={{ marginTop: 0, marginBottom: '15px' }}>
                            {editingLevel ? 'Chỉnh Sửa Cấp Độ Học' : 'Thêm Cấp Độ Học Mới'}
                        </h4>
                        <input
                            type="text"
                            placeholder="Nhập tên cấp độ (VD: N5, N4, A1, B1)..."
                            value={newLevelName}
                            onChange={(e) => setNewLevelName(e.target.value)}
                            style={styles.input}
                            autoFocus
                            onKeyDown={(e) => e.key === 'Enter' && handleConfirmSaveLevel()}
                        />
                        <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px', marginTop: '20px' }}>
                            <button
                                style={styles.cancelBtn}
                                onClick={() => {
                                    setIsLevelModalOpen(false);
                                    setNewLevelName('');
                                    setEditingLevel(null);
                                }}
                            >
                                Hủy
                            </button>
                            <button style={styles.addBtn} onClick={handleConfirmSaveLevel}>
                                {editingLevel ? 'Cập Nhật' : 'Lưu Cấp Độ'}
                            </button>
                        </div>
                    </div>
                </div>
            )}

            {/* MODAL: THÊM / SỬA KHO DANH MỤC */}
            {isCategoryModalOpen && (
                <div style={styles.modalOverlay}>
                    <div style={styles.modalContent}>
                        <h4 style={{ marginTop: 0, marginBottom: '15px' }}>
                            {editingCategory ? 'Chỉnh Sửa Kho Danh Mục' : 'Thêm Kho Danh Mục Mới'}
                        </h4>

                        <label style={{ fontSize: '13px', color: '#475569', marginBottom: '4px', display: 'block' }}>Tên Danh Mục:</label>
                        <input
                            type="text"
                            placeholder="VD: Từ vựng gia đình, Từ vựng đời sống..."
                            value={categoryForm.name}
                            onChange={(e) => setCategoryForm({ ...categoryForm, name: e.target.value })}
                            style={styles.input}
                            autoFocus
                        />

                        <label style={{ fontSize: '13px', color: '#475569', marginTop: '12px', marginBottom: '4px', display: 'block' }}>Mô Tả (Không bắt buộc):</label>
                        <input
                            type="text"
                            placeholder="Mô tả ngắn về danh mục..."
                            value={categoryForm.description}
                            onChange={(e) => setCategoryForm({ ...categoryForm, description: e.target.value })}
                            style={styles.input}
                        />

                        <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px', marginTop: '20px' }}>
                            <button
                                style={styles.cancelBtn}
                                onClick={() => {
                                    setIsCategoryModalOpen(false);
                                    setCategoryForm({ name: '', description: '' });
                                    setEditingCategory(null);
                                }}
                            >
                                Hủy
                            </button>
                            <button style={styles.addBtn} onClick={handleConfirmSaveCategory}>
                                {editingCategory ? 'Cập Nhật' : 'Lưu Danh Mục'}
                            </button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}

const styles = {
    card: { backgroundColor: '#fff', padding: '16px', borderRadius: '8px', marginBottom: '15px', boxShadow: '0 1px 3px rgba(0,0,0,0.1)' },
    label: { fontWeight: 'bold', display: 'block', marginBottom: '8px' },
    btnGroup: { display: 'flex', gap: '10px', flexWrap: 'wrap' },
    inactiveBtn: { backgroundColor: '#e2e8f0', color: '#334155', border: 'none', padding: '8px 16px', borderRadius: '6px', cursor: 'pointer' },
    activeSkillBtn: { backgroundColor: '#7c3aed', color: '#fff', border: 'none', padding: '8px 16px', borderRadius: '6px', fontWeight: 'bold', cursor: 'pointer' },
    subActionBtn: { background: 'none', border: 'none', padding: '0 8px', cursor: 'pointer', fontSize: '12px' },
    select: { width: '100%', padding: '10px', border: '1px solid #cbd5e1', borderRadius: '6px' },
    addBtn: { backgroundColor: '#10b981', color: '#fff', border: 'none', padding: '8px 16px', borderRadius: '6px', fontWeight: 'bold', cursor: 'pointer' },
    cancelBtn: { backgroundColor: '#64748b', color: '#fff', border: 'none', padding: '8px 16px', borderRadius: '6px', cursor: 'pointer' },
    disabledBtn: { backgroundColor: '#9ca3af', color: '#fff', border: 'none', padding: '6px 12px', borderRadius: '6px', cursor: 'not-allowed', opacity: 0.7 },
    table: { width: '100%', borderCollapse: 'collapse', backgroundColor: '#fff', borderRadius: '8px', overflow: 'hidden' },
    th: { backgroundColor: '#f1f5f9', padding: '12px', textAlign: 'left', borderBottom: '1px solid #e2e8f0' },
    td: { padding: '12px', borderBottom: '1px solid #e2e8f0' },
    badgeTimer: { backgroundColor: '#f59e0b', color: '#fff', padding: '4px 8px', borderRadius: '4px', fontSize: '12px', fontWeight: 'bold' },
    badgeNoTimer: { backgroundColor: '#94a3b8', color: '#fff', padding: '4px 8px', borderRadius: '4px', fontSize: '12px' },
    detailBtn: { backgroundColor: '#8b5cf6', color: '#fff', border: 'none', padding: '6px 10px', borderRadius: '4px', cursor: 'pointer', marginRight: '6px', fontSize: '13px' },
    editBtn: { backgroundColor: '#3b82f6', color: '#fff', border: 'none', padding: '6px 12px', borderRadius: '4px', cursor: 'pointer', marginRight: '6px' },
    deleteBtn: { backgroundColor: '#ef4444', color: '#fff', border: 'none', padding: '6px 12px', borderRadius: '4px', cursor: 'pointer' },
    modalOverlay: { position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, backgroundColor: 'rgba(0, 0, 0, 0.5)', display: 'flex', justifyContent: 'center', alignItems: 'center', zIndex: 1000 },
    modalContent: { backgroundColor: '#fff', padding: '24px', borderRadius: '8px', width: '400px', maxWidth: '90%', boxShadow: '0 4px 12px rgba(0, 0, 0, 0.15)' },
    input: { width: '100%', padding: '10px', border: '1px solid #cbd5e1', borderRadius: '6px', boxSizing: 'border-box' }
};