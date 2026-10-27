/**
 * Helper dùng chung cho trường dữ liệu kiểu "Công thức" (computed).
 * Được host nạp global trên mọi trang giống wf-helpers-js.js.
 *
 *   WF_FORMULA.presets               -> danh sách công thức mẫu cho designer
 *   WF_FORMULA.evaluate(formula, v)  -> tính kết quả từ công thức + map giá trị
 *
 * Công thức tham chiếu trường bằng cú pháp [TenTruong], ví dụ: [SoLuong] * [DonGia].
 */
;(function (root) {
    if (root.WF_FORMULA) return // idempotent — nạp nhiều lần vẫn an toàn

    // Danh sách công thức mẫu — sửa ở đây là cập nhật mọi nơi dùng
    var presets = [
        { title: 'Thành tiền = Số lượng × Đơn giá', value: '[SoLuong] * [DonGia]' },
        { title: 'Tổng cộng (3 khoản)', value: '[Khoan1] + [Khoan2] + [Khoan3]' },
        { title: 'VAT 10%', value: '[ThanhTien] * 0.1' },
        { title: 'Tổng + VAT 10%', value: '[ThanhTien] * 1.1' },
        { title: 'Chiết khấu theo %', value: '[ThanhTien] * (1 - [PhanTramCK] / 100)' },
        { title: 'Trung bình 2 giá trị', value: '([GiaTri1] + [GiaTri2]) / 2' }
    ]

    function evaluate(formula, values) {
        if (!formula) return '0'
        var vals = values || {}
        var expr = String(formula).trim()

        // Thay [TenTruong] bằng giá trị số
        expr = expr.replace(/\[([^\]]+)\]/g, function (match, fieldName) {
            var val = Number(vals[fieldName.trim()])
            return Number.isFinite(val) ? String(val) : '0'
        })

        // Thay tên trường trần (không bọc []) bằng giá trị số
        Object.keys(vals).forEach(function (key) {
            var val = Number(vals[key])
            if (!Number.isFinite(val)) val = 0
            expr = expr.replace(new RegExp('\\b' + key + '\\b', 'g'), String(val))
        })

        try {
            // Chỉ giữ ký tự toán học an toàn trước khi eval
            var sanitized = expr.replace(/[^0-9+\-*/().\s]/g, '')
            if (!sanitized.trim()) return '0'
            var result = Function('"use strict"; return (' + sanitized + ')')()
            if (Number.isFinite(result)) {
                return result % 1 === 0 ? String(result) : result.toFixed(1)
            }
            return '0'
        } catch (e) {
            return '0'
        }
    }

    root.WF_FORMULA = { presets: presets, evaluate: evaluate }
})(typeof window !== 'undefined' ? window : this)

// Hỗ trợ môi trường Node.js (test)
if (typeof module !== 'undefined' && module.exports) {
    module.exports = (typeof window !== 'undefined' ? window : this).WF_FORMULA
}
