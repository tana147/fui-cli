<template>
    <v-dialog v-model="isDialog" width="640" persistent>
        <v-form ref="form" v-model="valid" @submit.prevent="onSave">
            <v-card>
                <v-toolbar dense flat>
                    <v-toolbar-title>
                        Chi tiết hủy món <span class="primary--text ml-2">({{ SanPham.TenSanPham }})</span>
                    </v-toolbar-title>
                    <v-spacer></v-spacer>
                    <v-btn icon @click="vueData.IsShowDialogKhuyenMai = false"><v-icon>mdi-close</v-icon></v-btn>
                </v-toolbar>
                <v-card-text>
                    <v-text-field v-model="SanPham.GhiChu" label="Nhập lý do hủy" outlined hide-details dense :rules="rulesNoiDungHuy"></v-text-field>
                </v-card-text>
                <v-card-actions>
                    <v-spacer></v-spacer>
                    <v-btn text @click="$emit('update:isDialog', false)">Đóng</v-btn>
                    <v-btn text @click="onSave" color="success">Xác nhận</v-btn>
                </v-card-actions>
            </v-card>
        </v-form>
    </v-dialog>
</template>

<script>
export default {
    props: ["isDialog", "SanPham", "value"],
    data() {
        return {
            valid: true,
            NoiDungHuy: "",
            rulesNoiDungHuy: [(v) => !!v || "Nội dung hủy không được bỏ trống"],
        }
    },
    methods: {
        onSave() {
            let validate = this.$refs.form.validate()
            if (validate) {
                const $this = this
                const params = {
                    HoaDonChiTietID: $this.SanPham.HoaDonChiTietID,
                    GhiChu: $this.SanPham.GhiChu,
                }
                ajaxCALL(
                    "/eorder/HoaDonChiTiet_Huy",
                    params,
                    (res) => {
                        const sanpham = res.data[0]
                        $this.SanPham.TenTrangThai = sanpham.TenTrangThai
                        $this.SanPham.TrangThai = sanpham.TrangThai
                        $this.SanPham.Is_KhuyenMai = 0
                        //Hủy cả thuộc tính của sản phẩm
                        $this.SanPham.ThuocTinh.forEach((item) => {
                            if (item.SoLuong > 0) {
                                item.TenTrangThai = sanpham.TenTrangThai
                                item.TrangThai = sanpham.TrangThai
                            }
                        })
                        $this.$emit("update:isDialog", false)
                        return Vue.$toast.success("Cập nhật hủy món thành công", {
                            position: "top",
                        })
                    },
                    (error) => {
                        $this.$emit("update:isDialog", false)
                        return Vue.$toast.error(error.responseJSON.Message ?? "", {
                            position: "top",
                        })
                    },
                )
            }
        },
    },
}
</script>
