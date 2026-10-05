<template>
    <div class="text-start">
        <b class="font-weight-bold">
            Chương trình: <span class="success--text">{{ ct_khuyenmai?.MaChuongTrinh }} - {{ ct_khuyenmai?.TenChuongTrinh }}</span>
        </b>
        <v-chip class="ml-3" :color="ct_khuyenmai.TrangThai === 1 ? 'success' : 'error'" small> {{ ct_khuyenmai.TrangThai === 1 ? "Đang diễn ra" : "Đã kết thúc" }} </v-chip>
        <br />
        Thời gian: <span>{{ ct_khuyenmai.TuNgay_Display }} → {{ ct_khuyenmai.DenNgay_Display }}</span> (Trị giá: {{ct_khuyenmai.TriGia?.toLocaleString('vi-vn')}}) <br />
        Điều kiện: <b class="red--text">{{ renderDieuKien(ct_khuyenmai) }}</b> <br />
        Khuyến mãi: <b class="blue--text">{{ renderKhuyenMai(ct_khuyenmai) }}</b>
    </div>
</template>

<script>
export default {
    props: ["ct_khuyenmai"],
}
</script>
