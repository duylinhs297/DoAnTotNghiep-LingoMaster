import { useEffect } from 'react';

export default function AdminAssetLoader() {
    useEffect(() => {
        const cssFiles = [
            '/assets/vendor/fontawesome/css/fontawesome.min.css',
            '/assets/vendor/fontawesome/css/solid.min.css',
            '/assets/vendor/fontawesome/css/brands.min.css',
            '/assets/vendor/bootstrap/css/bootstrap.min.css',
            '/assets/css/master.css',
            '/assets/vendor/flagiconcss/css/flag-icon.min.css'
        ];

        const jsFiles = [
            '/assets/vendor/jquery/jquery.min.js',
            '/assets/vendor/bootstrap/js/bootstrap.bundle.min.js',
            '/assets/vendor/chartsjs/Chart.min.js',
            '/assets/js/dashboard-charts.js',
            '/assets/js/script.js'
        ];

        const addedLinks = [];
        const addedScripts = [];

        cssFiles.forEach((href) => {
            if (!document.querySelector(`link[href="${href}"]`)) {
                const link = document.createElement('link');
                link.rel = 'stylesheet';
                link.href = href;
                document.head.appendChild(link);
                addedLinks.push(link);
            }
        });

        jsFiles.forEach((src) => {
            if (!document.querySelector(`script[src="${src}"]`)) {
                const script = document.createElement('script');
                script.src = src;
                script.async = false;
                script.onload = () => {
                    // Ép khởi tạo lại các dropdown của Bootstrap ngay khi script load xong
                    if (window.bootstrap) {
                        const dropdowns = document.querySelectorAll('[data-bs-toggle="dropdown"]');
                        dropdowns.forEach(el => new window.bootstrap.Dropdown(el));
                    }
                };
                document.body.appendChild(script);
                addedScripts.push(script);
            }
        });

        return () => {
            addedLinks.forEach((link) => link.remove());
            addedScripts.forEach((script) => script.remove());
        };
    }, []);

    return null;
}