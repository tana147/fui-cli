/**
 * Tải file PDF từ URL và chuyển đổi thành chuỗi base64.
 * @param {string} url - Đường dẫn URL đến file PDF cần đọc.
 * @param {boolean} [includePrefix=true] - Có kèm tiền tố "data:application/pdf;base64," hay không.
 * @returns {Promise<string>} Trả về chuỗi base64 của file PDF.
 */
async function getPdfBase64FromUrl(url, includePrefix = true) {
    try {
        const response = await fetch(url);
        if (!response.ok) {
            throw new Error(`Không thể tải PDF: ${response.status} ${response.statusText}`);
        }

        const arrayBuffer = await response.arrayBuffer();
        let base64String = '';

        // Kiểm tra nếu đang chạy ở môi trường Node.js
        if (typeof window === 'undefined' && typeof Buffer !== 'undefined') {
            base64String = Buffer.from(arrayBuffer).toString('base64');
        } else {
            // Môi trường Trình duyệt (Browser)
            const bytes = new Uint8Array(arrayBuffer);
            let binary = '';
            const chunkSize = 0xffff; // Giới hạn kích thước chunk để tránh lỗi tràn stack
            for (let i = 0; i < bytes.byteLength; i += chunkSize) {
                const chunk = bytes.subarray(i, i + chunkSize);
                binary += String.fromCharCode.apply(null, chunk);
            }
            base64String = btoa(binary);
        }

        return includePrefix ? `data:application/pdf;base64,${base64String}` : base64String;
    } catch (error) {
        console.error('Lỗi khi chuyển đổi PDF sang Base64:', error);
        throw error;
    }
}

// Export module dựa trên môi trường chạy
if (typeof module !== 'undefined' && module.exports) {
    module.exports = { getPdfBase64FromUrl };
}
