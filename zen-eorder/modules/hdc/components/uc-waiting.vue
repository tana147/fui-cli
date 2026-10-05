<template>
    <div class="order-tracking">
        <img style="max-height: 180px; width: 100%; object-fit: cover" src="/_cdn/zen-eorder/icon-waiting/banner.jpg" alt="Banner" />
        <div class="header-section">
            <h2>Theo Dõi Đơn Hàng ({{ vueData.SoCho }})</h2>
            <p class="mb-1">Order Tracking</p>
        </div>
        <div class="order-tracking-wrapper">
            <div class="section completed pt-0 mt-0">
                <div class="section-header">
                    <span class="title">Hoàn tất</span>
                    <span class="subtitle">Completed</span>
                </div>
                <div class="order-list">
                    <div v-for="item in DSHoaDon_HoanThanh" :key="item.HoaDonID" class="order-item" :class="{highlight: item.Is_SoCho === 1}">
                        <img :src="getOrderIcon(item, item.Is_SoCho === 1)" :class="[{'icon-tai-quan': item.LoaiDonHang === 1}]" class="order-icon" />
                        <span style="font-size: 24px">{{ item.SoCho }}</span>
                    </div>
                </div>
            </div>
            <div class="section processing">
                <div class="section-header">
                    <span class="title">Đang chuẩn bị</span>
                    <span class="subtitle">Processing</span>
                </div>
                <div class="order-list">
                    <div v-for="item in DSHoaDon_ChuanBi" :key="item.HoaDonID" class="order-item" :class="{highlight: item.Is_SoCho === 1}">
                        <img :src="getOrderIcon(item, item.Is_SoCho === 1)" :class="[{'icon-tai-quan': item.LoaiDonHang === 1}]" class="order-icon" />
                        <span style="font-size: 24px">{{ item.SoCho }}</span>
                    </div>
                </div>
            </div>
        </div>
        <div class="warning-section pt-2">
            <h4><u>Kính gửi Quý khách hàng,</u></h4>
            <p class="mb-1">
                ZEN luôn phục vụ theo thứ tự đơn hàng, nhưng đôi khi đơn sau có thể hoàn thành trước do thời gian chế biến mỗi món khác nhau hoặc đã được đặt trước. Quý khách có thể yên tâm rằng <br />
                <b>ZEN luôn giữ đúng thứ tự và nỗ lực hoàn thành sớm nhất có thể.</b> <br />
                <b>Mong quý khách thông cảm, ZEN chân thành cảm ơn!</b>
            </p>
        </div>
        <div class="footer">
            <div class="footer-item">
                <img src="/_cdn/zen-eorder/icon-waiting/dot.png" alt="Tại cửa hàng" class="footer-icon order-icon" />
                <span style="line-height: 1">Tại cửa hàng<br /><small>At store</small></span>
            </div>
            <div class="footer-item">
                <img src="/_cdn/zen-eorder/icon-waiting/take-away.png" alt="Mang đi" class="footer-icon order-icon" />
                <span style="line-height: 1">Mang đi<br /><small>Takeaway</small></span>
            </div>
            <div class="footer-item btn-bill" v-if="HoaDonID > 0">
                <span style="line-height: 1" @click="onRedirectToInvoice">Hoá đơn<br /><small>Check bill</small></span>
            </div>
        </div>
    </div>
</template>

<script>
export default {
    props: ["ds_hoadon"],
    data() {
        return {
            pageSize: 10,
            currentPage: {
                DSHoaDon_ChuanBi: 1,
                DSHoaDon_HoanThanh: 1,
            },
        }
    },
    computed: {
        // Gom trạng thái 1 và 5 vào 1 nhóm
        DSHoaDon_ChuanBi() {
            return this.ds_hoadon[0]?.filter((item) => item.TrangThai === 1 || item.TrangThai === 5)
        },
        // Hoàn tất chỉ lấy trạng thái 2
        DSHoaDon_HoanThanh() {
            return this.ds_hoadon[0]?.filter((item) => item.TrangThai === 2)
        },
        HoaDonID() {
            if (this.ds_hoadon[1]?.length > 0) {
                return this.ds_hoadon[1][0]?.HoaDonID ?? 0
            }
        },
        paginated_ChuanBi() {
            return this.paginate(this.DSHoaDon_ChuanBi, this.currentPage.DSHoaDon_ChuanBi)
        },
        paginated_HoanThanh() {
            return this.paginate(this.DSHoaDon_HoanThanh, this.currentPage.DSHoaDon_HoanThanh)
        },
    },
    methods: {
        paginate(data, page) {
            const start = (page - 1) * this.pageSize
            return data.slice(start, start + this.pageSize)
        },
        getOrderIcon(item, isHighlight) {
            // Map icon cho từng loại
            const icons = {
                1: {
                    normal: "/_cdn/zen-eorder/icon-waiting/store.png",
                    highlight: "/_cdn/zen-eorder/icon-waiting/store-active.png",
                },
                2: {
                    normal: "/_cdn/zen-eorder/icon-waiting/take-away.png",
                    highlight: "/_cdn/zen-eorder/icon-waiting/take-away-active.png",
                },
                3: {
                    normal: "/_cdn/zen-eorder/icon-waiting/store.png",
                    highlight: "/_cdn/zen-eorder/icon-waiting/take-away.png",
                },
            }
            const type = item.LoaiDonHang
            return isHighlight ? icons[type].highlight : icons[type].normal
        },
        onRedirectToInvoice() {
            window.location.href = `/hd?id=` + this.HoaDonID
        },
    },
    mounted() {},
}
</script>
