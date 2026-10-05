<template>
	<div class="text-left">
		<v-btn @click="history.back()" elevation="0">
			<v-icon left>mdi-arrow-left</v-icon>Trở lại
		</v-btn>
		<v-btn class="ml-3" color="success" elevation="0" @click="vueData.IsShowDialogCloneProduct = true">
			<v-icon left>mdi-content-copy</v-icon>Sao chép
		</v-btn>
		<v-btn class="ml-3" color="success" elevation="0" @click="vueData.IsShowDialogSettingProduct = true">
			<v-icon left>mdi-cog</v-icon>Thiết lập nhiều cửa hàng
		</v-btn>
		<v-btn class="ml-3" color="error" elevation="0" @click="onDeleteProduct()">
			<v-icon left>mdi-trash-can</v-icon>Xóa sản phẩm
		</v-btn>
		<uc-modal-sao-chep :show_dialog="vueData.IsShowDialogCloneProduct" :ct_sanpham="ct_sanpham" />
		<uc-modal-thiet-lap-nang-cao :show_dialog="vueData.IsShowDialogSettingProduct" :ct_sanpham="ct_sanpham"
			:sp_ch="sp_ch" />
	</div>
</template>

<script>
	export default {
    props: ["ct_sanpham", "sp_ch"],
    methods: {
        onDeleteProduct() {
            const $this = this
            if ($this.ct_sanpham.SanPhamID > 0) {
                confirm({
                    title: "Xác nhận xóa sản phẩm",
                    content: `Bạn có chắc muốn xóa sản phẩm ${$this.ct_sanpham?.TenSanPham}. Sản phẩm sẽ được xóa vĩnh viễn ra khỏi tất cả hệ thống cửa hàng?`,
                    action: function () {
                        const params = {SanPhamID: $this.ct_sanpham.SanPhamID}
                        ajaxCALL("/eordertest/SanPham_Delete", params, (res) => {
                            window.location.href = "/san-pham"
                        })
                    },
                })
            } else {
                showToast({type: "red", title: "Không tìm thấy sản phẩm"})
            }
        },
    },
}
</script>