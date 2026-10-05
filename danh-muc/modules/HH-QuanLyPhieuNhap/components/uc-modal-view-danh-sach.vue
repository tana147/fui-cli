<template>
	<v-dialog v-model="isShow" width="600">
		<v-card>
			<v-toolbar density="comfortable" :elevation="0" class="border-b">
				<v-toolbar-title class="font-weight-bold">Xem chi tiết</v-toolbar-title>
				<v-spacer></v-spacer>
				<v-btn icon="mdi-close" variant="text" size="small" @click="closeDialog" />
			</v-toolbar>
			<v-card-text class="pt-3">
				<v-data-table height="500" :headers="headers" :items="DanhSach" :search="search" density="compact"
					fixed-header :items-per-page="-1" hide-default-footer>

					<template v-slot:top>
						<div class="d-flex align-center justify-space-between flex-wrap ga-3 mb-2">
							<div class="text-body-2">
								Danh sách hàng hoá
								<span class="font-weight-bold">
									{{ TinhTrang === 'KHONG_CO_HOA_DON'
									? 'không có hoá đơn'
									: 'có hoá đơn'
									}}
								</span>
							</div>
							<v-text-field v-model="search" density="compact" variant="underlined"
								prepend-inner-icon="mdi-magnify" label="Tìm kiếm" hide-details clearable
								style="max-width:220px" />
						</div>
					</template>

					<template v-slot:no-data>
						<uc-empty text="Chưa có dữ liệu"></uc-empty>
					</template>

				</v-data-table>
			</v-card-text>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
    props: {
        isShow: Boolean,
        DanhSach: Array,
        TinhTrang: String,
    },
    emits: ['update:isShow'],
    data() {
        return {
            headers: [
                { title: 'Nhà cung cấp', key: 'TenNhaCungCap' },
                { title: 'Tên hàng hoá', key: 'TenHangHoa' },
            ],
            search: null,
        }
    },
    methods: {
        closeDialog() {
            this.$emit('update:isShow', false)
        },
    },
}
</script>