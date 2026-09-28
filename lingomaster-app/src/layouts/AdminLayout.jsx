import React, { useState } from 'react';
import { Outlet, Link, useNavigate } from 'react-router-dom';
import AdminAssetLoader from './../components/AdminAssetLoader';
export default function AdminLayout() {
    const [openQuickLinks, setOpenQuickLinks] = useState(false);
    const [openUserMenu, setOpenUserMenu] = useState(false);
    const navigate = useNavigate();
    // 1. Lấy user từ localStorage
    const storedUser = JSON.parse(localStorage.getItem('user'));
    const userName = storedUser?.name || storedUser?.email || 'Tài khoản';

    // 2. Hàm xử lý Đăng xuất
    const handleLogout = (e) => {
        e.preventDefault();
        localStorage.removeItem('token');
        localStorage.removeItem('user');
        navigate('/admin/auth');
    };

    return (
        <div className="wrapper" >
            <AdminAssetLoader />
            {/* SIDEBAR */}
            <nav id="sidebar">
                <div className="sidebar-header">
                    <img src="/assets/img/bootstraper-logo.png" alt="bootstrapper logo" className="app-logo" />
                </div>
                <ul className="list-unstyled components text-secondary">
                    <li>
                        <Link to="/admin"><i className="fas fa-home"></i> Trang chủ</Link>
                    </li>
                    <li>
                        <Link to="/admin/users"><i className="fas fa-file-alt"></i> Quản lí Tài Khoản</Link>
                    </li>
                    <li>
                        <Link to="/admin/courses"><i className="fas fa-table"></i> Quản lí Nội Dung</Link>
                    </li>
                    <li>
                        <Link to="/admin/battles"><i className="fas fa-chart-bar"></i> Quản lí Trận Đấu</Link>
                    </li>  
                </ul>
            </nav>

            {/* BODY WRAPPER */}
            <div id="body">
                {/* NAVBAR */}
                <nav className="navbar navbar-expand-lg navbar-white bg-white px-4 justify-content-end">
                    {/* Thêm style hoặc class để dịch chuyển vị trí */}
                    <div className="navbar-collapse" id="navbarSupportedContent" style={{ display: 'flex', justifyContent: 'flex-end', width: '100%' }}>
                        <ul className="nav navbar-nav" style={{ marginRight: '20px' }}> {/* Thay đổi số pixel ở đây để dịch chuyển */}

                            {/* Quick Links Dropdown */}
                            <li className={`nav-item dropdown ${openQuickLinks ? 'show' : ''}`}>
                                <div className="nav-dropdown">
                                    <a
                                        href="#"
                                        className="nav-item nav-link dropdown-toggle text-secondary"
                                        onClick={(e) => {
                                            e.preventDefault();
                                            setOpenQuickLinks(!openQuickLinks);
                                            setOpenUserMenu(false);
                                        }}
                                    >
                                        <i className="fas fa-link"></i> <span>Quick Links</span> <i style={{ fontSize: '.8em' }} className="fas fa-caret-down"></i>
                                    </a>
                                    <div className={`dropdown-menu dropdown-menu-end nav-link-menu ${openQuickLinks ? 'show' : ''}`}>
                                        <ul className="nav-list list-unstyled">
                                            <li><a href="#" className="dropdown-item"><i className="fas fa-list"></i> Access Logs</a></li>
                                            <div className="dropdown-divider"></div>
                                            <li><a href="#" className="dropdown-item"><i className="fas fa-database"></i> Back ups</a></li>
                                            <div className="dropdown-divider"></div>
                                            <li><a href="#" className="dropdown-item"><i className="fas fa-cloud-download-alt"></i> Updates</a></li>
                                            <div className="dropdown-divider"></div>
                                            <li><a href="#" className="dropdown-item"><i className="fas fa-user-shield"></i> Roles</a></li>
                                        </ul>
                                    </div>
                                </div>
                            </li>

                            {/* John Doe Dropdown */}
                            <li className={`nav-item dropdown ${openUserMenu ? 'show' : ''}`}>
                                <div className="nav-dropdown">
                                    <a
                                        href="#"
                                        id="nav2"
                                        className="nav-item nav-link dropdown-toggle text-secondary"
                                        onClick={(e) => {
                                            e.preventDefault();
                                            setOpenUserMenu(!openUserMenu);
                                            setOpenQuickLinks(false);
                                        }}
                                    >
                                        <i className="fas fa-user"></i> <span>{userName}</span> <i style={{ fontSize: '.8em' }} className="fas fa-caret-down"></i>
                                    </a>
                                    <div className={`dropdown-menu dropdown-menu-end nav-link-menu ${openUserMenu ? 'show' : ''}`}>
                                        <ul className="nav-list list-unstyled">
                                            <li><a href="#" className="dropdown-item"><i className="fas fa-address-card"></i> Profile</a></li>
                                            <li><a href="#" className="dropdown-item"><i className="fas fa-envelope"></i> Messages</a></li>
                                            <li><a href="#" className="dropdown-item"><i className="fas fa-cog"></i> Settings</a></li>
                                            <div className="dropdown-divider"></div>
                                            <li>
                                                <a href="#" className="dropdown-item" onClick={handleLogout}>
                                                    <i className="fas fa-sign-out-alt"></i> Logout
                                                </a>
                                            </li>
                                        </ul>
                                    </div>
                                </div>
                            </li>

                        </ul>
                    </div>
                </nav>

                {/* NƠI CÁC TRANG CON ĐƯỢC RENDER VÀO */}
                <div className="content">
                    <Outlet />
                </div>
            </div>
        </div>
    );
}