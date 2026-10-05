const DEFAULT_PROVIDER = {
    VBtn: { variant: 'tonal' },
    VTextField: { variant: 'outlined', density: 'compact' },
    VDataTableServer: { density: 'compact', }
}

const mapTinhTrangHangHoaCaBiet = {
    NHAP: {
        text: 'Mới nhập',
        color: 'grey'
    },
    // HUY_NHAP: {
    //     text: 'Huỷ nhập',
    //     color: 'red'
    // },
    // XUAT: {
    //     text: 'Đã xuất',
    //     color: 'blue'
    // },
    HUY_XUAT: {
        text: 'Huỷ xuất',
        color: 'orange'
    },
    DANG_SU_DUNG: {
        text: 'Đang sử dụng',
        color: 'green'
    },
    LUAN_CHUYEN: {
        text: 'Mới luân chuyển',
        color: 'purple'
    },
    // THANH_LY: {
    //     text: 'Đã thanh lý',
    //     color: 'brown'
    // },
    // BAO_TRI: {
    //     text: 'Đang bảo trì',
    //     color: 'amber'
    // },
    TIEP_NHAN: {
        text: 'Tiếp nhận',
        color: 'blue'
    },

    KIEM_TRA: {
        text: 'Kiểm tra',
        color: 'cyan'
    },

    DANG_SUA: {
        text: 'Đang sửa',
        color: 'warning'
    },

    DA_XONG: {
        text: 'Đã sửa xong',
        color: 'success'
    },

    HU: {
        text: 'Hư',
        color: 'error'
    },
}

const DSTinhTrangCaBiet = [
    {
        title: 'Mới nhập', value: 'NHAP'
    },
    // {
    //     title: 'Huỷ nhập', value: 'HUY_NHAP'
    // },
    // {
    //     title: 'Đã xuất', value: 'XUAT'
    // },
    {
        title: 'Huỷ xuất', value: 'HUY_XUAT'
    },
    {
        title: 'Đang sử dụng', value: 'DANG_SU_DUNG'
    },
    {
        title: 'Mới luân chuyển', value: 'LUAN_CHUYEN'
    },
    // {
    //     title: 'Đã thanh lý', value: 'THANH_LY'
    // },
    // {
    //     title: 'Đang bảo trì', value: 'BAO_TRI'
    // },
    {
        title: 'Tiếp nhận', value: 'TIEP_NHAN'
    },
    {
        title: 'Kiểm tra', value: 'KIEM_TRA'
    },
    {
        title: 'Đang sửa', value: 'DANG_SUA'
    },
    {
        title: 'Sửa xong', value: 'DA_XONG'
    },
    {
        title: 'Hư', value: 'HU'
    },
]

const mapTinhTrangPhieu = {
    'TAO_MOI': {
        text: 'Tạo mới',
        color: 'grey'
    },
    'LUU_TAM': {
        text: 'Lưu tạm',
        color: 'grey-lighten-1'
    },
    'CHO_DUYET': {
        text: 'Chờ duyệt',
        color: 'orange'
    },
    'CHO_HOA_DON': {
        text: 'Chờ hoá đơn',
        color: 'deep-purple'
    },
    'DANG_XU_LY': {
        text: 'Đang xử lý',
        color: 'blue'
    },
    'DAT_HANG': {
        text: 'Đặt hàng',
        color: 'indigo'
    },
    'HOAN_THANH': {
        text: 'Hoàn thành',
        color: 'green'
    },
    'HUY': {
        text: 'Huỷ',
        color: 'red'
    },
}

const mapDoUuTien = {
    KHAN_CAP: {
        text: "Khẩn cấp",
        color: "red"
    },
    UU_TIEN: {
        text: "Ưu tiên",
        color: "orange"
    },
    TRUNG_BINH: {
        text: "Trung bình",
        color: "primary"
    },
    BINH_THUONG: {
        text: "Bình thường",
        color: "green"
    }
}

