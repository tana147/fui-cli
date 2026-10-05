<template>
    <div :class="detail?.NhomLienKetChiTiet_ParentID === null ? 'break-detail' : ''" :style="detail?.SanPhamID > 0 ? 'width: 100%; background-color: #fff;padding: 5px 0;' : ''">
        <div v-if="detail?.SanPhamID > 0">
            <div :class="'tr-product ' + (detail?.TinhTrang_SanPham !== 0 ? 'muted-text' : '')">
                <div class="td-product-name pa-0 pl-2">+ {{ detail?.TenHienThi }}</div>
                <div class="td-product-price pa-0" v-if="detail?.SoLuong > 0">{{ ThanhTien?.toLocaleString("vi-vn") }}</div>
                <div class="td-product-price pa-0" style="color: #bdbdbd" v-if="detail?.SoLuong === 0">{{ detail?.GiaBan_CuaHang?.toLocaleString("vi-vn") }}</div>
                <div v-if="detail?.TinhTrang_SanPham === 0" class="td-product-qty-order pa-0">
                    <v-btn @click="onReduce()" :disabled="detail?.SoLuong === 0" fab class="bg-white pl-0 pr-0 btn-plus" x-small><v-icon class="text-green">mdi-minus</v-icon></v-btn>
                    <span class="px-2" style="font-size: 14px; font-weight: 500">{{ roundSoLuong(detail?.SoLuong) }}</span>
                    <v-btn @click="onIncrease()" :disabled="IsMaximum" fab class="bg-white pl-0 pr-0 btn-plus" x-small><v-icon class="text-green">mdi-plus</v-icon></v-btn>
                </div>
                <div v-if="detail?.TinhTrang_SanPham !== 0" class="td-product-qty-order pa-0">
                    <span class="px-2 error--text" style="font-size: 14px">Tạm hết</span>
                </div>
            </div>
        </div>
        <div v-if="detail?.SanPhamID === 0 || detail?.SanPhamID === null" class="bg-green-2">
            <div v-if="detail?.NhomLienKetChiTiet_ParentID !== null || detail?.NhomLienKetChiTiet_ParentID > 0" class="ml-3 py-1">
                <label @click="onCheck(!IsChecked)">
                    <v-icon class="text-green">{{ IsChecked ? "mdi-checkbox-marked" : "mdi-square-outline" }}</v-icon> {{ detail?.TenHienThi }}
                </label>
            </div>
        </div>
    </div>
</template>

<script>
export default {
    props: ["detail", "product"],
    computed: {
        ThanhTien: function () {
            return this.detail.SoLuong * this.detail.GiaBan_CuaHang
        },
        IsChecked: function () {
            return this.detail.SoLuong
        },
        IsMaximum: function () {
            const $this = this
            return $this.detail?.SoLuong >= $this.detail?.SoLuongToiDa * Math.ceil($this.product?.SoLuong)
        },
    },
    methods: {
        onIncrease() {
            const $this = this
            $this.detail.SoLuongThucTe += 1
            if ($this.detail.MaintainQuanlityRatio === 1) {
                $this.detail.SoLuong = $this.product.SoLuong
            } else {
                $this.detail.SoLuong = $this.detail.SoLuongThucTe * $this.product.SoLuong
            }
        },
        onReduce() {
            const $this = this
            $this.detail.SoLuongThucTe = $this.detail.SoLuongThucTe <= 0 ? 0 : $this.detail.SoLuongThucTe - 1
            if ($this.detail.MaintainQuanlityRatio === 1) {
                $this.detail.SoLuong = $this.detail.SoLuongThucTe * $this.product.SoLuong
            } else {
                $this.detail.SoLuong = $this.detail.SoLuongThucTe * $this.product.SoLuong
            }
        },
        onCheck(checked) {
            //const checked = event.target.checked
            const $this = this
            $this.detail.SoLuong = $this.detail.SoLuong === 1 ? 0 : 1
            //Lấy thông tin thiết lập nhóm cha
            const parentFilter = $this.product.ThuocTinh.filter((item) => item.NhomLienKetChiTietID === $this.detail.NhomLienKetChiTiet_ParentID)
            const parent = parentFilter[0]
            //Lấy tổng số lượng check
            let totalCheck = 0
            $this.product.ThuocTinh.forEach((item) => {
                if (item.NhomLienKetChiTiet_ParentID === parent.NhomLienKetChiTietID && item.SoLuong > 0) {
                    totalCheck += 1
                }
            })
            //Nếu Checked: Ràng buộc số lượng tối đa
            if (checked) {
                if (totalCheck > parent.SoLuongToiDa) {
                    //Chỉ hiển thị thông báo nếu số lượng tối đa > 1. Số lượng tối đa = 1 thì toggle check (Không thông báo)
                    if (parent.SoLuongToiDa > 1) {
                        Vue.$toast.warning(`Chỉ được chọn tối đa ${parent.SoLuongToiDa} ${parent.TenHienThi}`, {position: "top"})
                        $this.detail.SoLuong = 0
                    } else {
                        $this.product.ThuocTinh.map((item) => {
                            if (item.NhomLienKetChiTiet_ParentID === parent.NhomLienKetChiTietID) {
                                item.SoLuong = 0
                            }
                            return item
                        })
                        $this.detail.SoLuong = 1
                    }
                }
            } else {
                //Nếu UnChecked: Ràng buộc số lượng tối thiểu
                if (totalCheck < parent.SoLuongToiThieu) {
                    Vue.$toast.warning(`Phải chọn tối thiểu ${parent.SoLuongToiThieu} ${parent.TenHienThi}`, {position: "top"})
                    $this.detail.SoLuong = 1
                }
            }
        },
    },
}
</script>
