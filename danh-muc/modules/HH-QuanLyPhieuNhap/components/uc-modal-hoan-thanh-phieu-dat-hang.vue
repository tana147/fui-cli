<template>
	<v-dialog v-model="isShow" max-width="1200">
		<v-card rounded="lg">
			<v-toolbar>
				<v-toolbar-title class="text-primary">Hoàn thành phiếu đặt hàng</v-toolbar-title>
				<v-btn icon="mdi-close" @click="closeDialog"></v-btn>
			</v-toolbar>
			<v-divider></v-divider>
			<uc-stepper-dat-hang :DSNhanVien="DSNhanVien" :DSNhaCungCap="DSNhaCungCap" :DSDiaDiem="DSDiaDiem"
				:DSDonViTinh="DSDonViTinh" :closeDialog="closeDialog" :onReloadDSPhieuDatHang="onReloadDSPhieuDatHang"
				:selectedItem="selectedItem"></uc-stepper-dat-hang>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
    props: {
        isShow: Boolean,
        DSNhanVien: Array,
        DSNhaCungCap: Array,
        DSDiaDiem: Array,
        DSDonViTinh: Array,
        selectedItem: Object
    },
    data() {
        return {
        }
    },
    mounted() {
    },
    computed: {
    },
    watch: {},
    methods: {
        closeDialog() {
            this.$emit('update:isShow', false)
        },

        onReloadDSPhieuDatHang() {
            this.$emit('load-danh-sach-phieu-dat-hang')
        }

    },
}
</script>