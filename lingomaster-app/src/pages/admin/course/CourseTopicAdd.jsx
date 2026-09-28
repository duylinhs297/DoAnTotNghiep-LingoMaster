import React, { useState } from 'react';

export default function CourseTopicAdd({ categoryId, isQuiz, onSave, onCancel }) {
    const [form, setForm] = useState({
        title: '',
        subtitle: '',
        categoryKey: '',
        itemCount: 10,
        timeLimitSeconds: 0
    });

    const handleSubmit = (e) => {
        e.preventDefault();
        
        if (!categoryId) {
            alert("Lỗi: Chưa chọn Danh mục (Category)!");
            return;
        }

        onSave({
            categoryId: parseInt(categoryId),
            ...form,
            itemCount: parseInt(form.itemCount) || 0,
            timeLimitSeconds: parseInt(form.timeLimitSeconds) || 0
        });
    };

    return (
        <div style={styles.card}>
            <h3 style={{ marginTop: 0, marginBottom: '20px', color: '#1e293b' }}>Thêm Chủ Đề Mới</h3>
            <form onSubmit={handleSubmit}>
                <div style={styles.field}>
                    <label style={styles.label}>Tên Chủ Đề (Title): *</label>
                    <input
                        type="text"
                        required
                        placeholder="Ví dụ: Động vật, Gia đình, Bài 1..."
                        value={form.title}
                        onChange={(e) => setForm({ ...form, title: e.target.value })}
                        style={styles.input}
                    />
                </div>

                <div style={styles.field}>
                    <label style={styles.label}>Mô Tả Nhanh (Subtitle):</label>
                    <input
                        type="text"
                        placeholder="Ví dụ: Học 20 từ vựng về chủ đề gia đình..."
                        value={form.subtitle}
                        onChange={(e) => setForm({ ...form, subtitle: e.target.value })}
                        style={styles.input}
                    />
                </div>

                <div style={styles.field}>
                    <label style={styles.label}>Category Key (Dùng cho Flutter): *</label>
                    <input
                        type="text"
                        required
                        placeholder="Ví dụ: topic_family, vocab_n5_01..."
                        value={form.categoryKey}
                        onChange={(e) => setForm({ ...form, categoryKey: e.target.value })}
                        style={styles.input}
                    />
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                    <div style={styles.field}>
                        <label style={styles.label}>Số Lượng Mục Dự Kiến:</label>
                        <input
                            type="number"
                            min="0"
                            value={form.itemCount}
                            onChange={(e) => setForm({ ...form, itemCount: e.target.value })}
                            style={styles.input}
                        />
                    </div>

                    <div style={styles.field}>
                        <label style={styles.label}>Thời Gian Đếm Ngược (giây):</label>
                        <input
                            type="number"
                            min="0"
                            value={form.timeLimitSeconds}
                            onChange={(e) => setForm({ ...form, timeLimitSeconds: e.target.value })}
                            style={styles.input}
                        />
                    </div>
                </div>

                <div style={styles.actions}>
                    <button type="button" onClick={onCancel} style={styles.cancelBtn}>Hủy</button>
                    <button type="submit" style={styles.saveBtn}>+ Tạo Chủ Đề</button>
                </div>
            </form>
        </div>
    );
}

const styles = {
    card: { backgroundColor: '#fff', padding: '24px', borderRadius: '8px', maxWidth: '520px', margin: '0 auto', boxShadow: '0 4px 6px -1px rgba(0,0,0,0.1)' },
    field: { marginBottom: '16px', display: 'flex', flexDirection: 'column', gap: '6px' },
    label: { fontWeight: '600', fontSize: '14px', color: '#334155' },
    input: { padding: '10px', border: '1px solid #cbd5e1', borderRadius: '6px', fontSize: '14px' },
    actions: { display: 'flex', justifyContent: 'flex-end', gap: '10px', marginTop: '24px' },
    saveBtn: { backgroundColor: '#10b981', color: '#fff', border: 'none', padding: '10px 20px', borderRadius: '6px', fontWeight: 'bold', cursor: 'pointer' },
    cancelBtn: { backgroundColor: '#64748b', color: '#fff', border: 'none', padding: '10px 20px', borderRadius: '6px', cursor: 'pointer' }
};