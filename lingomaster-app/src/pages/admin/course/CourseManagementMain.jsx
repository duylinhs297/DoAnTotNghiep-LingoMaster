import React, { useEffect, useState } from 'react';
import CourseTopicList from './CourseTopicList';
import CourseTopicAdd from './CourseTopicAdd';
import CourseTopicEdit from './CourseTopicEdit';
import VocabItemManager from './items/VocabItemManager';
import SpeakingItemManager from './items/SpeakingItemManager';
import FlashcardItemManager from './items/FlashcardItemManager';
import QuizItemManager from './items/QuizItemManager';
import ListeningItemManager from './items/ListeningItemManager';

const API_BASE = 'http://localhost:5208/api/CourseAdmin';

export default function CourseManagementMain() {
    const [viewMode, setViewMode] = useState('LIST'); // LIST, ADD, EDIT, ITEMS

    const [levels, setLevels] = useState([]);
    const [selectedLevel, setSelectedLevel] = useState('');
    const [selectedSkill, setSelectedSkill] = useState('VOCAB');
    const [categories, setCategories] = useState([]);
    const [selectedCategoryId, setSelectedCategoryId] = useState('');
    const [topics, setTopics] = useState([]);

    const [editingTopic, setEditingTopic] = useState(null);
    const [managingTopic, setManagingTopic] = useState(null);

    // State quản lý thông báo mờ dần
    const [notification, setNotification] = useState({ message: '', type: 'success', visible: false });

    // Hàm hiển thị thông báo tự ẩn sau 1 giây
    const showNotification = (message, type = 'success') => {
        setNotification({ message, type, visible: true });
        setTimeout(() => {
            setNotification(prev => ({ ...prev, visible: false }));
        }, 1000);
    };

    const fetchLevels = async () => {
        try {
            const res = await fetch(`${API_BASE}/levels`);
            const data = await res.json();
            setLevels(data);
            if (data.length > 0 && !selectedLevel) {
                setSelectedLevel(data[0].id);
            }
        } catch (error) {
            console.error("Lỗi lấy danh sách cấp độ:", error);
        }
    };

    useEffect(() => {
        fetchLevels();
    }, []);

    const handleAddLevel = async (levelName) => {
        try {
            const res = await fetch(`${API_BASE}/level`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    name: levelName,
                    order: levels.length + 1
                })
            });

            if (res.ok) {
                const result = await res.json();
                showNotification(result.message || 'Thêm cấp độ thành công!', 'success');
                const updatedRes = await fetch(`${API_BASE}/levels`);
                const updatedData = await updatedRes.json();
                setLevels(updatedData);
                if (updatedData.length === 1) {
                    setSelectedLevel(updatedData[0].id);
                }
            } else {
                const errorData = await res.json();
                showNotification(`Lưu thất bại: ${JSON.stringify(errorData)}`, 'error');
            }
        } catch (error) {
            console.error("Lỗi thêm cấp độ:", error);
            showNotification("Không thể kết nối tới server!", 'error');
        }
    };

    const handleEditLevel = async (levelId, newName) => {
        try {
            const res = await fetch(`${API_BASE}/level/${levelId}`, {
                method: 'PUT',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ name: newName, order: 1 })
            });
            const result = await res.json();
            if (res.ok) {
                showNotification(result.message || 'Cập nhật cấp độ thành công!', 'success');
                fetchLevels();
            } else {
                showNotification(`Thất bại: ${result.message || JSON.stringify(result)}`, 'error');
            }
        } catch (e) {
            console.error(e);
            showNotification('Không thể kết nối tới server!', 'error');
        }
    };

    const handleDeleteLevel = async (levelId) => {
        if (!window.confirm('Xác nhận xóa cấp độ này?')) return;
        try {
            const res = await fetch(`${API_BASE}/level/${levelId}`, { method: 'DELETE' });
            const result = await res.json();
            if (res.ok) {
                showNotification(result.message || 'Đã xóa cấp độ thành công!', 'success');
                fetchLevels();
            } else {
                showNotification(result.message || 'Xóa cấp độ thất bại!', 'error');
            }
        } catch (e) {
            console.error(e);
            showNotification('Không thể kết nối tới server!', 'error');
        }
    };

    const fetchCategories = async () => {
        if (!selectedLevel) return;
        try {
            const res = await fetch(`${API_BASE}/categories?levelId=${selectedLevel}&skillType=${selectedSkill}`);
            const data = await res.json();
            setCategories(data);
            if (data.length > 0) {
                setSelectedCategoryId(data[0].id);
            } else {
                setSelectedCategoryId('');
                setTopics([]);
            }
        } catch (error) {
            console.error("Lỗi lấy danh mục:", error);
        }
    };

    const handleEditCategory = async (catId, updatedData) => {
        try {
            const res = await fetch(`${API_BASE}/category/${catId}`, {
                method: 'PUT',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(updatedData)
            });
            const result = await res.json();
            if (res.ok) {
                showNotification(result.message || 'Cập nhật danh mục thành công!', 'success');
                fetchCategories();
            } else {
                showNotification(`Thất bại: ${result.message || JSON.stringify(result)}`, 'error');
            }
        } catch (e) {
            console.error(e);
            showNotification('Không thể kết nối tới server!', 'error');
        }
    };

    const handleDeleteCategory = async (catId) => {
        if (!window.confirm('Xác nhận xóa danh mục này?')) return;
        try {
            const res = await fetch(`${API_BASE}/category/${catId}`, { method: 'DELETE' });
            const result = await res.json();
            if (res.ok) {
                showNotification(result.message || 'Đã xóa danh mục thành công!', 'success');
                fetchCategories();
            } else {
                showNotification(result.message || 'Xóa danh mục thất bại!', 'error');
            }
        } catch (e) {
            console.error(e);
            showNotification('Không thể kết nối tới server!', 'error');
        }
    };

    useEffect(() => {
        fetchCategories();
    }, [selectedLevel, selectedSkill]);

    const handleAddCategory = async (categoryData) => {
        if (!selectedLevel) {
            showNotification("Vui lòng chọn Cấp Độ Học trước!", 'error');
            return;
        }

        try {
            const res = await fetch(`${API_BASE}/category`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    levelId: parseInt(selectedLevel),
                    skillType: selectedSkill,
                    name: categoryData.name,
                    description: categoryData.description || ''
                })
            });

            if (res.ok) {
                const result = await res.json();
                showNotification(result.message || 'Thêm danh mục thành công!', 'success');
                await fetchCategories();
            } else {
                const errorData = await res.json();
                showNotification(`Lưu danh mục thất bại: ${JSON.stringify(errorData)}`, 'error');
            }
        } catch (error) {
            console.error("Lỗi thêm danh mục:", error);
            showNotification("Không thể kết nối tới server!", 'error');
        }
    };

    const loadTopics = async () => {
        if (!selectedCategoryId) return;
        try {
            const res = await fetch(`${API_BASE}/topics?categoryId=${selectedCategoryId}`);
            const data = await res.json();
            setTopics(data);
        } catch (error) {
            console.error("Lỗi tải danh sách chủ đề:", error);
        }
    };

    useEffect(() => {
        loadTopics();
    }, [selectedCategoryId]);

    const handleSaveAdd = async (newTopic) => {
        try {
            const res = await fetch(`${API_BASE}/topic`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(newTopic)
            });
            const result = await res.json();
            if (res.ok) {
                showNotification(result.message || 'Thêm chủ đề thành công!', 'success');
                setViewMode('LIST');
                loadTopics();
            } else {
                showNotification(result.message || 'Thêm chủ đề thất bại!', 'error');
            }
        } catch (e) {
            showNotification('Không thể kết nối tới server!', 'error');
        }
    };

    const handleSaveEdit = async (id, updatedTopic) => {
        try {
            const res = await fetch(`${API_BASE}/topic/${id}`, {
                method: 'PUT',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(updatedTopic)
            });
            const result = await res.json();
            if (res.ok) {
                showNotification(result.message || 'Cập nhật chủ đề thành công!', 'success');
                setViewMode('LIST');
                loadTopics();
            } else {
                showNotification(result.message || 'Cập nhật chủ đề thất bại!', 'error');
            }
        } catch (e) {
            showNotification('Không thể kết nối tới server!', 'error');
        }
    };

    const handleDelete = async (id) => {
        if (!window.confirm('Xác nhận xóa chủ đề này?')) return;
        try {
            const res = await fetch(`${API_BASE}/topic/${id}`, { method: 'DELETE' });
            const result = await res.json();

            if (res.ok) {
                showNotification(result.message || '✅ Đã xóa chủ đề thành công!', 'success');
                loadTopics();
            } else {
                showNotification(result.message || '⚠️ Không thể xóa chủ đề này.', 'error');
            }
        } catch (error) {
            console.error("Lỗi khi xóa chủ đề:", error);
            showNotification('Không thể kết nối tới server!', 'error');
        }
    };

    const handleManageItems = (topic) => {
        setManagingTopic(topic);
        setViewMode('ITEMS');
    };

    const renderSkillItemManager = () => {
        if (!managingTopic) return null;

        const commonProps = {
            topic: managingTopic,
            onBack: () => {
                setViewMode('LIST');
                loadTopics();
            }
        };

        switch (selectedSkill) {
            case 'VOCAB':
                return <VocabItemManager {...commonProps} />;
            case 'REVIEW':
            case 'FLASHCARD':
                return <FlashcardItemManager {...commonProps} />;
            case 'SPEAKING':
                return <SpeakingItemManager {...commonProps} />;
            case 'QUIZ':
                return <QuizItemManager {...commonProps} apiBaseUrl={API_BASE} />;
            case 'LISTENING':
                return <ListeningItemManager {...commonProps} />;
            default:
                return (
                    <div>
                        <button onClick={() => setViewMode('LIST')} style={{ marginBottom: '16px' }}>← Quay lại</button>
                        <p>Chưa hỗ trợ quản lý item cho kỹ năng: {selectedSkill}</p>
                    </div>
                );
        }
    };

    return (
        <div style={{ padding: '30px', backgroundColor: '#f8fafc', minHeight: '100vh', position: 'relative' }}>
            {/* Thanh thông báo nổi mờ dần */}
            <div
                style={{
                    position: 'fixed',
                    top: '20px',
                    right: '20px',
                    zIndex: 50,
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

            <h2>Hệ Thống Quản Lý Nội Dung Đa Tầng</h2>

            {viewMode === 'LIST' && (
                <CourseTopicList
                    levels={levels}
                    selectedLevel={selectedLevel}
                    setSelectedLevel={setSelectedLevel}
                    selectedSkill={selectedSkill}
                    setSelectedSkill={setSelectedSkill}
                    categories={categories}
                    selectedCategoryId={selectedCategoryId}
                    setSelectedCategoryId={setSelectedCategoryId}
                    topics={topics}
                    onAddLevel={handleAddLevel}
                    onEditLevel={handleEditLevel}
                    onDeleteLevel={handleDeleteLevel}
                    onAddCategory={handleAddCategory}
                    onEditCategory={handleEditCategory}
                    onDeleteCategory={handleDeleteCategory}
                    onOpenAdd={() => setViewMode('ADD')}
                    onOpenEdit={(topic) => { setEditingTopic(topic); setViewMode('EDIT'); }}
                    onDelete={handleDelete}
                    onManageItems={handleManageItems}
                />
            )}

            {viewMode === 'ADD' && (
                <CourseTopicAdd
                    categoryId={selectedCategoryId}
                    isQuiz={selectedSkill === 'QUIZ'}
                    onSave={handleSaveAdd}
                    onCancel={() => setViewMode('LIST')}
                />
            )}

            {viewMode === 'EDIT' && (
                <CourseTopicEdit
                    topicData={editingTopic}
                    onSave={handleSaveEdit}
                    onCancel={() => setViewMode('LIST')}
                />
            )}

            {viewMode === 'ITEMS' && managingTopic && (
                <div style={{ marginTop: '20px' }}>
                    {renderSkillItemManager()}
                </div>
            )}
        </div>
    );
}