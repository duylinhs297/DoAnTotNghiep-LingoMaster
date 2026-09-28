import React, { useState, useEffect } from 'react';

export default function Home() {
    const [showButton, setShowButton] = useState(false);

    // Xử lý hiện/ẩn nút cuộn lên đầu dựa vào vị trí cuộn chuột
    useEffect(() => {
        const handleScroll = () => {
            if (window.pageYOffset > 300) {
                setShowButton(true);
            } else {
                setShowButton(false);
            }
        };

        window.addEventListener('scroll', handleScroll);
        return () => window.removeEventListener('scroll', handleScroll);
    }, []);

    // Hàm cuộn mượt tùy chỉnh tốc độ
    const scrollToTop = () => {
        const startPosition = window.pageYOffset;
        const targetPosition = 0;
        const distance = targetPosition - startPosition;
        const duration = 1000;
        let startTime = null;

        const easeInOutQuad = (t, b, c, d) => {
            t /= d / 2;
            if (t < 1) return c / 2 * t * t + b;
            t--;
            return -c / 2 * (t * (t - 2) - 1) + b;
        };

        const animation = (currentTime) => {
            if (startTime === null) startTime = currentTime;
            const timeElapsed = currentTime - startTime;
            const run = easeInOutQuad(timeElapsed, startPosition, distance, duration);
            window.scrollTo(0, run);
            if (timeElapsed < duration) {
                requestAnimationFrame(animation);
            }
        };

        requestAnimationFrame(animation);
    };

    // Hàm cuộn mượt khi bấm các mục menu
    const handleNavClick = (e, targetId) => {
        e.preventDefault();
        const targetElement = document.querySelector(targetId);
        if (targetElement) {
            const headerOffset = 80;
            const targetPosition = targetElement.getBoundingClientRect().top + window.pageYOffset - headerOffset;
            const startPosition = window.pageYOffset;
            const distance = targetPosition - startPosition;
            const duration = 1000;
            let startTime = null;

            const easeInOutQuad = (t, b, c, d) => {
                t /= d / 2;
                if (t < 1) return c / 2 * t * t + b;
                t--;
                return -c / 2 * (t * (t - 2) - 1) + b;
            };

            const animation = (currentTime) => {
                if (startTime === null) startTime = currentTime;
                const timeElapsed = currentTime - startTime;
                const run = easeInOutQuad(timeElapsed, startPosition, distance, duration);
                window.scrollTo(0, run);
                if (timeElapsed < duration) {
                    requestAnimationFrame(animation);
                }
            };

            requestAnimationFrame(animation);
        }
    };

    return (
        <div className="bg-slate-50 text-slate-800">
            {/* HEADER */}
            <header className="fixed top-0 left-0 right-0 z-50 bg-white/85 backdrop-blur-md border-b border-slate-100">
                <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-20 flex items-center justify-between">
                    <div className="flex items-center space-x-2">
                        <div className="w-10 h-10 rounded-xl bg-indigo-600 flex items-center justify-center text-white font-bold text-xl shadow-lg shadow-indigo-200">
                            L
                        </div>
                        <span className="text-2xl font-extrabold text-slate-900 tracking-tight">
                            Linhgo<span className="text-indigo-600">Master</span>
                        </span>
                    </div>
                    <nav className="hidden md:flex items-center space-x-8 font-medium text-slate-600">
                        <a href="#features" onClick={(e) => handleNavClick(e, '#features')} className="hover:text-indigo-600 transition">Tính năng</a>
                        <a href="#methods" onClick={(e) => handleNavClick(e, '#methods')} className="hover:text-indigo-600 transition">Phương pháp</a>
                        <a href="#testimonials" onClick={(e) => handleNavClick(e, '#testimonials')} className="hover:text-indigo-600 transition">Đánh giá</a>
                        <a href="#pricing" onClick={(e) => handleNavClick(e, '#pricing')} className="hover:text-indigo-600 transition">Bảng giá</a>
                    </nav>
                    <div className="flex items-center space-x-4">
                        <a href="#download" onClick={(e) => handleNavClick(e, '#download')} className="bg-indigo-600 hover:bg-indigo-700 text-white font-medium px-5 py-2.5 rounded-xl shadow-lg shadow-indigo-200 transition transform hover:-translate-y-0.5">
                            Tải ứng dụng ngay
                        </a>
                    </div>
                </div>
            </header>

            {/* HERO SECTION */}
            <section className="pt-32 pb-20 md:pt-40 md:pb-28 overflow-hidden bg-gradient-to-b from-indigo-50/50 to-white">
                <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-12 items-center">
                        <div className="space-y-6 text-center md:text-left">
                            <div className="inline-flex items-center space-x-2 bg-indigo-100/80 text-indigo-700 px-3.5 py-1.5 rounded-full text-sm font-semibold">
                                <i className="fa-solid fa-bolt"></i>
                                <span>Học tiếng Anh thông minh cùng AI</span>
                            </div>
                            <h1 className="text-4xl sm:text-5xl lg:text-6xl font-extrabold text-slate-900 tracking-tight leading-tight">
                                Chinh phục tiếng Anh <span className="text-transparent bg-clip-text bg-gradient-to-r from-indigo-600 to-violet-600">chỉ với 15 phút mỗi ngày</span>
                            </h1>
                            <p className="text-lg text-slate-600 max-w-xl mx-auto md:mx-0">
                                Ứng dụng tích hợp công nghệ AI nhận diện phát hiện lỗi sai, lộ trình cá nhân hóa giúp bạn tự tin giao tiếp thành thạo sau 3 tháng.
                            </p>
                            <div className="flex flex-col sm:flex-row justify-center md:justify-start space-y-3 sm:space-y-0 sm:space-x-4 pt-4">
                                <a href="#" className="flex items-center justify-center space-x-3 bg-slate-900 hover:bg-slate-800 text-white px-6 py-3.5 rounded-xl shadow-xl transition">
                                    <i className="fa-brands fa-apple text-2xl"></i>
                                    <div className="text-left">
                                        <div className="text-[10px] uppercase font-semibold text-slate-400">Tải về trên</div>
                                        <div className="text-sm font-bold">App Store</div>
                                    </div>
                                </a>
                                <a href="#" className="flex items-center justify-center space-x-3 bg-slate-900 hover:bg-slate-800 text-white px-6 py-3.5 rounded-xl shadow-xl transition">
                                    <i className="fa-brands fa-google-play text-xl"></i>
                                    <div className="text-left">
                                        <div className="text-[10px] uppercase font-semibold text-slate-400">Tải về trên</div>
                                        <div className="text-sm font-bold">Google Play</div>
                                    </div>
                                </a>
                            </div>
                        </div>
                        {/* Phone Mockup */}
                        <div className="relative flex justify-center">
                            <div className="absolute -top-10 -left-10 w-72 h-72 bg-purple-200 rounded-full mix-blend-multiply filter blur-2xl opacity-70 animate-pulse"></div>
                            <div className="absolute -bottom-10 -right-10 w-72 h-72 bg-indigo-200 rounded-full mix-blend-multiply filter blur-2xl opacity-70 animate-pulse"></div>
                            <div className="relative w-[280px] h-[570px] bg-slate-900 rounded-[45px] p-4 shadow-2xl border-4 border-slate-700">
                                <div className="w-full h-full bg-slate-900 rounded-[35px] overflow-hidden flex flex-col justify-between p-4 text-white relative">
                                    <div>
                                        <div className="flex justify-between items-center mb-6">
                                            <span className="text-xs text-slate-400 font-medium">LinhgoMaster AI</span>
                                            <div className="bg-indigo-600 px-2 py-0.5 rounded-md text-xs">Streak 🔥 5</div>
                                        </div>
                                        <div className="bg-slate-800/80 p-4 rounded-2xl mb-4">
                                            <span className="text-xs text-indigo-400 font-bold uppercase">Daily Goal</span>
                                            <h4 className="font-bold text-sm mt-1">Giao tiếp chủ đề Công sở</h4>
                                            <div className="w-full bg-slate-700 h-2 rounded-full mt-3 overflow-hidden">
                                                <div className="bg-indigo-500 h-full w-3/4"></div>
                                            </div>
                                        </div>
                                        <div className="space-y-2">
                                            <div className="p-3 bg-slate-800 rounded-xl text-xs flex items-center justify-between">
                                                <span>Từ vựng mới (12)</span>
                                                <i className="fa-solid fa-chevron-right text-slate-500"></i>
                                            </div>
                                            <div className="p-3 bg-slate-800 rounded-xl text-xs flex items-center justify-between">
                                                <span>Luyện phát âm AI</span>
                                                <i className="fa-solid fa-chevron-right text-slate-500"></i>
                                            </div>
                                        </div>
                                    </div>
                                    <div className="bg-gradient-to-r from-indigo-500 to-violet-500 p-3 rounded-xl text-center text-xs font-semibold cursor-pointer">
                                        Bắt đầu học ngay
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </section>

            {/* MARQUEE FLAGS */}
            <div className="bg-indigo-900 text-white py-4 overflow-hidden border-y border-indigo-800">
                <div className="relative w-full overflow-hidden flex">
                    <div className="animate-marquee flex items-center space-x-12 shrink-0 px-6">
                        <div className="flex items-center space-x-3 text-sm font-semibold tracking-wider uppercase"><img src="https://flagcdn.com/w40/us.png" alt="US" className="w-7 h-5 object-cover rounded shadow-sm" /> <span>Hoa Kỳ (US English)</span></div>
                        <div className="flex items-center space-x-3 text-sm font-semibold tracking-wider uppercase"><img src="https://flagcdn.com/w40/gb.png" alt="UK" className="w-7 h-5 object-cover rounded shadow-sm" /> <span>Anh Quốc (UK English)</span></div>
                        <div className="flex items-center space-x-3 text-sm font-semibold tracking-wider uppercase"><img src="https://flagcdn.com/w40/au.png" alt="AU" className="w-7 h-5 object-cover rounded shadow-sm" /> <span>Úc (Australian Accent)</span></div>
                        <div className="flex items-center space-x-3 text-sm font-semibold tracking-wider uppercase"><img src="https://flagcdn.com/w40/ca.png" alt="CA" className="w-7 h-5 object-cover rounded shadow-sm" /> <span>Canada</span></div>
                        <div className="flex items-center space-x-3 text-sm font-semibold tracking-wider uppercase"><img src="https://flagcdn.com/w40/sg.png" alt="SG" className="w-7 h-5 object-cover rounded shadow-sm" /> <span>Singapore</span></div>
                    </div>
                    <div className="animate-marquee flex items-center space-x-12 shrink-0 px-6" aria-hidden="true">
                        <div className="flex items-center space-x-3 text-sm font-semibold tracking-wider uppercase"><img src="https://flagcdn.com/w40/us.png" alt="US" className="w-7 h-5 object-cover rounded shadow-sm" /> <span>Hoa Kỳ (US English)</span></div>
                        <div className="flex items-center space-x-3 text-sm font-semibold tracking-wider uppercase"><img src="https://flagcdn.com/w40/gb.png" alt="UK" className="w-7 h-5 object-cover rounded shadow-sm" /> <span>Anh Quốc (UK English)</span></div>
                        <div className="flex items-center space-x-3 text-sm font-semibold tracking-wider uppercase"><img src="https://flagcdn.com/w40/au.png" alt="AU" className="w-7 h-5 object-cover rounded shadow-sm" /> <span>Úc (Australian Accent)</span></div>
                        <div className="flex items-center space-x-3 text-sm font-semibold tracking-wider uppercase"><img src="https://flagcdn.com/w40/ca.png" alt="CA" className="w-7 h-5 object-cover rounded shadow-sm" /> <span>Canada</span></div>
                        <div className="flex items-center space-x-3 text-sm font-semibold tracking-wider uppercase"><img src="https://flagcdn.com/w40/sg.png" alt="SG" className="w-7 h-5 object-cover rounded shadow-sm" /> <span>Singapore</span></div>
                    </div>
                </div>
            </div>

            {/* FEATURES SECTION */}
            <section id="features" className="py-20 bg-white">
                <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                    <div className="text-center max-w-2xl mx-auto mb-16">
                        <h2 className="text-base font-semibold text-indigo-600 uppercase tracking-wider">Tính năng vượt trội</h2>
                        <p className="text-3xl font-extrabold text-slate-900 mt-2">Mọi thứ bạn cần để giỏi tiếng Anh trong một ứng dụng</p>
                    </div>
                    <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
                        <div className="p-8 rounded-2xl bg-slate-50 hover:bg-indigo-50/50 transition border border-slate-100 group">
                            <div className="w-14 h-14 bg-indigo-100 text-indigo-600 rounded-2xl flex items-center justify-center text-2xl font-bold mb-6 group-hover:bg-indigo-600 group-hover:text-white transition">
                                <i className="fa-solid fa-microphone-lines"></i>
                            </div>
                            <h3 className="text-xl font-bold text-slate-900 mb-2">Chấm điểm phát âm AI</h3>
                            <p className="text-slate-600">Phân tích chi tiết từng âm tiết, chỉ ra lỗi sai phát âm cụ thể và hướng dẫn khẩu hình miệng chuẩn bản xứ.</p>
                        </div>
                        <div className="p-8 rounded-2xl bg-slate-50 hover:bg-indigo-50/50 transition border border-slate-100 group">
                            <div className="w-14 h-14 bg-indigo-100 text-indigo-600 rounded-2xl flex items-center justify-center text-2xl font-bold mb-6 group-hover:bg-indigo-600 group-hover:text-white transition">
                                <i className="fa-solid fa-brain"></i>
                            </div>
                            <h3 className="text-xl font-bold text-slate-900 mb-2">Lộ trình cá nhân hóa</h3>
                            <p className="text-slate-600">Hệ thống AI đánh giá năng lực đầu vào và thiết kế riêng một lộ trình học tập tối ưu hóa dành riêng cho bạn.</p>
                        </div>
                        <div className="p-8 rounded-2xl bg-slate-50 hover:bg-indigo-50/50 transition border border-slate-100 group">
                            <div className="w-14 h-14 bg-indigo-100 text-indigo-600 rounded-2xl flex items-center justify-center text-2xl font-bold mb-6 group-hover:bg-indigo-600 group-hover:text-white transition">
                                <i className="fa-solid fa-gamepad"></i>
                            </div>
                            <h3 className="text-xl font-bold text-slate-900 mb-2">Học mà chơi qua Gamification</h3>
                            <p className="text-slate-600">Biến việc học từ vựng và ngữ pháp thành các trò chơi đối kháng thú vị, không còn cảm giác nhàm chán.</p>
                        </div>
                    </div>
                </div>
            </section>

            {/* METHODS SECTION */}
            <section id="methods" className="py-20 bg-slate-50 border-t border-slate-100">
                <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                    <div className="text-center max-w-2xl mx-auto mb-16">
                        <h2 className="text-base font-semibold text-indigo-600 uppercase tracking-wider">Phương pháp độc quyền</h2>
                        <p className="text-3xl font-extrabold text-slate-900 mt-2">Học tự nhiên như tiếng mẹ đẻ với mô hình 3 bước</p>
                    </div>
                    <div className="grid grid-cols-1 md:grid-cols-3 gap-8 relative">
                        <div className="bg-white p-8 rounded-2xl shadow-sm border border-slate-100 relative">
                            <div className="absolute -top-4 left-8 bg-indigo-600 text-white w-8 h-8 rounded-full flex items-center justify-center font-bold text-sm shadow-md">01</div>
                            <h3 className="text-xl font-bold text-slate-900 mt-3 mb-3">Lắng nghe chủ động</h3>
                            <p className="text-slate-600 text-sm leading-relaxed">Tiếp xúc với ngữ cảnh thực tế thông qua các đoạn hội thoại ngắn, video ngắn và podcast chuẩn bản xứ.</p>
                        </div>
                        <div className="bg-white p-8 rounded-2xl shadow-sm border border-slate-100 relative">
                            <div className="absolute -top-4 left-8 bg-indigo-600 text-white w-8 h-8 rounded-full flex items-center justify-center font-bold text-sm shadow-md">02</div>
                            <h3 className="text-xl font-bold text-slate-900 mt-3 mb-3">Thực hành cùng AI</h3>
                            <p className="text-slate-600 text-sm leading-relaxed">Nhập vai vào các tình huống thực tế và trò chuyện trực tiếp với trợ lý AI không giới hạn.</p>
                        </div>
                        <div className="bg-white p-8 rounded-2xl shadow-sm border border-slate-100 relative">
                            <div className="absolute -top-4 left-8 bg-indigo-600 text-white w-8 h-8 rounded-full flex items-center justify-center font-bold text-sm shadow-md">03</div>
                            <h3 className="text-xl font-bold text-slate-900 mt-3 mb-3">Ghi nhớ ngắt quãng</h3>
                            <p className="text-slate-600 text-sm leading-relaxed">Hệ thống tự động nhắc nhở ôn tập vào đúng thời điểm não bộ chuẩn bị quên kiến thức.</p>
                        </div>
                    </div>
                </div>
            </section>
            <section id="testimonials" class="py-20 bg-white overflow-hidden border-t border-slate-100">
                <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 mb-12">
                    <div class="text-center max-w-2xl mx-auto">
                        <h2 class="text-base font-semibold text-indigo-600 uppercase tracking-wider">Đánh giá từ học viên</h2>
                        <p class="text-3xl font-extrabold text-slate-900 mt-2">Hàng triệu người đã thay đổi khả năng tiếng Anh
                        </p>
                    </div>
                </div>

                <div class="relative w-full overflow-hidden flex">
                    <div class="animate-marquee flex space-x-6 shrink-0 px-3">
                        <div class="bg-slate-50 p-6 rounded-2xl shadow-sm border border-slate-100 w-[380px] shrink-0">
                            <div class="flex items-center space-x-4 mb-3">
                                <div
                                    class="w-10 h-10 bg-indigo-500 rounded-full flex items-center justify-center text-white font-bold text-sm">
                                    HN</div>
                                <div>
                                    <h4 class="font-bold text-slate-900 text-sm">Hoàng Nam</h4>
                                    <span class="text-xs text-slate-500">Software Engineer</span>
                                </div>
                            </div>
                            <p class="text-slate-600 text-sm italic">"Nhờ tính năng luyện phản xạ giao tiếp với AI của
                                LinhgoMaster, mình đã tự tin phỏng vấn thành công công ty đa quốc gia chỉ sau 2 tháng."</p>
                            <div class="flex text-amber-400 mt-3 text-xs">
                                <i class="fa-solid fa-star"></i><i class="fa-solid fa-star"></i><i
                                    class="fa-solid fa-star"></i><i class="fa-solid fa-star"></i><i
                                        class="fa-solid fa-star"></i>
                            </div>
                        </div>
                        <div class="bg-slate-50 p-6 rounded-2xl shadow-sm border border-slate-100 w-[380px] shrink-0">
                            <div class="flex items-center space-x-4 mb-3">
                                <div
                                    class="w-10 h-10 bg-purple-500 rounded-full flex items-center justify-center text-white font-bold text-sm">
                                    TL</div>
                                <div>
                                    <h4 class="font-bold text-slate-900 text-sm">Thanh Lan</h4>
                                    <span class="text-xs text-slate-500">Sinh viên ĐH Ngoại Thương</span>
                                </div>
                            </div>
                            <p class="text-slate-600 text-sm italic">"Giao diện cực kỳ bắt mắt và dễ sử dụng. Từ vựng được lặp
                                lại ngắt quãng thông minh giúp mình nhớ rất lâu mà không bị quên."</p>
                            <div class="flex text-amber-400 mt-3 text-xs">
                                <i class="fa-solid fa-star"></i><i class="fa-solid fa-star"></i><i
                                    class="fa-solid fa-star"></i><i class="fa-solid fa-star"></i><i
                                        class="fa-solid fa-star"></i>
                            </div>
                        </div>
                        <div class="bg-slate-50 p-6 rounded-2xl shadow-sm border border-slate-100 w-[380px] shrink-0">
                            <div class="flex items-center space-x-4 mb-3">
                                <div
                                    class="w-10 h-10 bg-emerald-500 rounded-full flex items-center justify-center text-white font-bold text-sm">
                                    QM</div>
                                <div>
                                    <h4 class="font-bold text-slate-900 text-sm">Quốc Minh</h4>
                                    <span class="text-xs text-slate-500">Digital Marketer</span>
                                </div>
                            </div>
                            <p class="text-slate-600 text-sm italic">"Phần chấm điểm phát âm AI chuẩn xác đến từng âm tiết nhỏ.
                                Luyện tập mỗi ngày giúp phát âm của mình cải thiện rõ rệt."</p>
                            <div class="flex text-amber-400 mt-3 text-xs">
                                <i class="fa-solid fa-star"></i><i class="fa-solid fa-star"></i><i
                                    class="fa-solid fa-star"></i><i class="fa-solid fa-star"></i><i
                                        class="fa-solid fa-star"></i>
                            </div>
                        </div>
                    </div>

                    <div class="animate-marquee flex space-x-6 shrink-0 px-3" aria-hidden="true">
                        <div class="bg-slate-50 p-6 rounded-2xl shadow-sm border border-slate-100 w-[380px] shrink-0">
                            <div class="flex items-center space-x-4 mb-3">
                                <div
                                    class="w-10 h-10 bg-indigo-500 rounded-full flex items-center justify-center text-white font-bold text-sm">
                                    HN</div>
                                <div>
                                    <h4 class="font-bold text-slate-900 text-sm">Hoàng Nam</h4>
                                    <span class="text-xs text-slate-500">Software Engineer</span>
                                </div>
                            </div>
                            <p class="text-slate-600 text-sm italic">"Nhờ tính năng luyện phản xạ giao tiếp với AI của
                                LinhgoMaster, mình đã tự tin phỏng vấn thành công công ty đa quốc gia chỉ sau 2 tháng."</p>
                            <div class="flex text-amber-400 mt-3 text-xs">
                                <i class="fa-solid fa-star"></i><i class="fa-solid fa-star"></i><i
                                    class="fa-solid fa-star"></i><i class="fa-solid fa-star"></i><i
                                        class="fa-solid fa-star"></i>
                            </div>
                        </div>
                        <div class="bg-slate-50 p-6 rounded-2xl shadow-sm border border-slate-100 w-[380px] shrink-0">
                            <div class="flex items-center space-x-4 mb-3">
                                <div
                                    class="w-10 h-10 bg-purple-500 rounded-full flex items-center justify-center text-white font-bold text-sm">
                                    TL</div>
                                <div>
                                    <h4 class="font-bold text-slate-900 text-sm">Thanh Lan</h4>
                                    <span class="text-xs text-slate-500">Sinh viên ĐH Ngoại Thương</span>
                                </div>
                            </div>
                            <p class="text-slate-600 text-sm italic">"Giao diện cực kỳ bắt mắt và dễ sử dụng. Từ vựng được lặp
                                lại ngắt quãng thông minh giúp mình nhớ rất lâu mà không bị quên."</p>
                            <div class="flex text-amber-400 mt-3 text-xs">
                                <i class="fa-solid fa-star"></i><i class="fa-solid fa-star"></i><i
                                    class="fa-solid fa-star"></i><i class="fa-solid fa-star"></i><i
                                        class="fa-solid fa-star"></i>
                            </div>
                        </div>
                        <div class="bg-slate-50 p-6 rounded-2xl shadow-sm border border-slate-100 w-[380px] shrink-0">
                            <div class="flex items-center space-x-4 mb-3">
                                <div
                                    class="w-10 h-10 bg-emerald-500 rounded-full flex items-center justify-center text-white font-bold text-sm">
                                    QM</div>
                                <div>
                                    <h4 class="font-bold text-slate-900 text-sm">Quốc Minh</h4>
                                    <span class="text-xs text-slate-500">Digital Marketer</span>
                                </div>
                            </div>
                            <p class="text-slate-600 text-sm italic">"Phần chấm điểm phát âm AI chuẩn xác đến từng âm tiết nhỏ.
                                Luyện tập mỗi ngày giúp phát âm của mình cải thiện rõ rệt."</p>
                            <div class="flex text-amber-400 mt-3 text-xs">
                                <i class="fa-solid fa-star"></i><i class="fa-solid fa-star"></i><i
                                    class="fa-solid fa-star"></i><i class="fa-solid fa-star"></i><i
                                        class="fa-solid fa-star"></i>
                            </div>
                        </div>
                    </div>
                </div>
            </section>
            {/* PRICING SECTION */}
            <section id="pricing" className="py-20 bg-slate-50 border-t border-slate-100">
                <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                    <div className="text-center max-w-2xl mx-auto mb-16">
                        <h2 className="text-base font-semibold text-indigo-600 uppercase tracking-wider">Bảng giá linh hoạt</h2>
                        <p className="text-3xl font-extrabold text-slate-900 mt-2">Đầu tư thông minh cho tương lai của bạn</p>
                    </div>
                    <div className="grid grid-cols-1 md:grid-cols-3 gap-8 items-stretch">
                        <div className="bg-white p-8 rounded-2xl shadow-sm border border-slate-200 flex flex-col justify-between">
                            <div>
                                <h3 className="text-xl font-bold text-slate-900 mb-2">Gói Cơ Bản</h3>
                                <div className="mb-6"><span className="text-4xl font-extrabold text-slate-900">0đ</span><span className="text-slate-500 text-sm">/ mãi mãi</span></div>
                                <ul className="space-y-3 text-sm text-slate-600 mb-8">
                                    <li className="flex items-center"><i className="fa-solid fa-check text-emerald-500 mr-2"></i> Học 15 phút mỗi ngày</li>
                                    <li className="flex items-center"><i className="fa-solid fa-check text-emerald-500 mr-2"></i> Kho từ vựng cơ bản</li>
                                </ul>
                            </div>
                            <a href="#download" onClick={(e) => handleNavClick(e, '#download')} className="block text-center bg-slate-100 hover:bg-slate-200 text-slate-800 font-semibold py-3 rounded-xl transition">Đăng ký miễn phí</a>
                        </div>

                        <div className="bg-indigo-600 text-white p-8 rounded-2xl shadow-xl border border-indigo-500 flex flex-col justify-between relative transform md:-translate-y-2">
                            <div className="absolute -top-3 left-1/2 transform -translate-x-1/2 bg-amber-400 text-slate-900 text-xs font-extrabold px-3 py-1 rounded-full uppercase tracking-wider shadow">Phổ biến nhất 🔥</div>
                            <div>
                                <h3 className="text-xl font-bold mb-2">Gói Pro 3 Tháng</h3>
                                <div className="mb-6"><span className="text-4xl font-extrabold">299.000đ</span><span className="text-indigo-200 text-sm">/ 3 tháng</span></div>
                                <ul className="space-y-3 text-sm text-indigo-100 mb-8">
                                    <li className="flex items-center"><i className="fa-solid fa-check text-amber-300 mr-2"></i> Mở khóa toàn bộ kho bài học</li>
                                    <li className="flex items-center"><i className="fa-solid fa-check text-amber-300 mr-2"></i> Chấm điểm phát âm AI chuẩn xác</li>
                                </ul>
                            </div>
                            <a href="#download" onClick={(e) => handleNavClick(e, '#download')} className="block text-center bg-white hover:bg-indigo-50 text-indigo-700 font-semibold py-3 rounded-xl transition shadow">Bắt đầu ngay</a>
                        </div>

                        <div className="bg-white p-8 rounded-2xl shadow-sm border border-slate-200 flex flex-col justify-between">
                            <div>
                                <h3 className="text-xl font-bold text-slate-900 mb-2">Gói VIP 1 Năm</h3>
                                <div className="mb-6"><span className="text-4xl font-extrabold text-slate-900">799.000đ</span><span className="text-slate-500 text-sm">/ năm</span></div>
                                <ul className="space-y-3 text-sm text-slate-600 mb-8">
                                    <li className="flex items-center"><i className="fa-solid fa-check text-emerald-500 mr-2"></i> Toàn bộ quyền lợi gói Pro</li>
                                    <li className="flex items-center"><i className="fa-solid fa-check text-emerald-500 mr-2"></i> Tiết kiệm hơn 50% chi phí</li>
                                </ul>
                            </div>
                            <a href="#download" onClick={(e) => handleNavClick(e, '#download')} className="block text-center bg-indigo-50 hover:bg-indigo-100 text-indigo-700 font-semibold py-3 rounded-xl transition">Chọn gói VIP</a>
                        </div>
                    </div>
                </div>
            </section>

            {/* DOWNLOAD SECTION */}
            <section id="download" className="py-20 bg-indigo-600 text-white">
                <div className="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
                    <h2 className="text-3xl sm:text-4xl font-extrabold tracking-tight mb-4">Bắt đầu hành trình chinh phục tiếng Anh của bạn hôm nay</h2>
                    <p className="text-indigo-100 max-w-xl mx-auto mb-8 text-lg">Tải ứng dụng miễn phí trên iOS và Android để trải nghiệm ngay.</p>
                    <div className="flex flex-col sm:flex-row justify-center space-y-3 sm:space-y-0 sm:space-x-4">
                        <a href="#" className="flex items-center justify-center space-x-3 bg-slate-900 hover:bg-slate-800 text-white px-8 py-4 rounded-xl shadow-xl transition font-medium">
                            <i className="fa-brands fa-apple text-2xl"></i>
                            <span>Tải trên App Store</span>
                        </a>
                        <a href="#" className="flex items-center justify-center space-x-3 bg-slate-900 hover:bg-slate-800 text-white px-8 py-4 rounded-xl shadow-xl transition font-medium">
                            <i className="fa-brands fa-google-play text-xl"></i>
                            <span>Tải trên Google Play</span>
                        </a>
                    </div>
                </div>
            </section>

            {/* NÚT LÊN ĐẦU TRANG */}
            <button
                id="backToTop"
                onClick={scrollToTop}
                className={`fixed bottom-6 right-6 z-50 bg-indigo-600 hover:bg-indigo-700 text-white w-12 h-12 rounded-full shadow-lg flex items-center justify-center transition-all transform hover:scale-110 ${showButton ? 'show' : ''}`}
            >
                <i className="fa-solid fa-arrow-up text-lg"></i>
            </button>

            {/* FOOTER */}
            <footer className="bg-slate-900 text-slate-400 py-12 border-t border-slate-800">
                <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 flex flex-col md:flex-row justify-between items-center space-y-6 md:space-y-0">
                    <div className="flex items-center space-x-2">
                        <div className="w-8 h-8 rounded-lg bg-indigo-600 flex items-center justify-center text-white font-bold text-sm">L</div>
                        <span className="text-xl font-bold text-white tracking-tight">LinhgoMaster</span>
                    </div>
                    <div className="text-sm text-slate-500">&copy; 2026 LinhgoMaster Inc. All rights reserved.</div>
                    <div className="flex space-x-6 text-xl">
                        <a href="#" className="hover:text-white transition"><i className="fa-brands fa-facebook"></i></a>
                        <a href="#" className="hover:text-white transition"><i className="fa-brands fa-instagram"></i></a>
                        <a href="#" className="hover:text-white transition"><i className="fa-brands fa-tiktok"></i></a>
                    </div>
                </div>
            </footer>
        </div>
    );
}