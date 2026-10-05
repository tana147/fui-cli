<template>
	<v-dialog v-model="dialog" width="1200" persistent>
		<v-card>
			<v-toolbar density="compact" elevation="0">
				<v-toolbar-title>Tạo phiếu đặt hàng</v-toolbar-title>
				<v-spacer />
				<v-btn size="small" variant="text" icon="mdi-close" @click="close" />
			</v-toolbar>
			<v-card-text class="pt-0">
				<v-form ref="form">
					<v-data-table class="table-dat-hang" :items="items" :headers="headers" height="500"
						density="compact" hide-default-footer :items-per-page="-1">
						<template #item.TenNhaCungCap="{ item }">
							<v-autocomplete color="primary" v-model="item.NhaCungCap_Id" density="compact"
								:items="DSNhaCungCap" item-value="NhaCungCap_Id" item-title="TenNhaCungCap"
								variant="underlined" :rules="[v => !!v || 'Bắt buộc']" />
						</template>
						<template #item.DiaDiemNhan="{ item }">
							<v-autocomplete color="primary" v-model="item.DiaDiemNhan_Id" density="compact"
								:items="DSDiaDiem" item-value="DiaDiem_Id" item-title="TenDiaDiem" variant="underlined"
								:rules="[v => !!v || 'Bắt buộc']" />
						</template>
					</v-data-table>
				</v-form>
			</v-card-text>
			<v-card-actions>
				<v-spacer />
				<v-btn variant="text" @click="close">Hủy</v-btn>
				<v-btn color="primary" variant="flat" prepend-icon="mdi-check-circle-outline" :loading="saving"
					@click="onSubmit">Xác nhận đặt hàng</v-btn>
			</v-card-actions>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
	props: {
		modelValue: Boolean,
		items: { type: Array, default: function () { return [] } },
		DSNhaCungCap: { type: Array, default: function () { return [] } },
		DSDiaDiem: { type: Array, default: function () { return [] } },
	},
	emits: ['update:modelValue', 'onReload'],
	data() {
		return {
			saving: false,
			headers: [
				{ title: 'Tên hàng hoá', key: 'TenHangHoa', align: 'start' },
				{ title: 'SL', key: 'SoLuong', align: 'end', width: 80 },
				{ title: 'ĐVT', key: 'TenDonVi', align: 'start', width: 80 },
				{ title: 'Địa điểm đề xuất', key: 'TenDiaDiem', align: 'start' },
				{ title: 'Nhà cung cấp', key: 'TenNhaCungCap', align: 'start', width: 250 },
				{ title: 'Địa điểm nhận', key: 'DiaDiemNhan', align: 'start', width: 250 },
			],
		}
	},
	computed: {
		dialog: {
			get() { return this.modelValue },
			set(val) { this.$emit('update:modelValue', val) }
		}
	},
	methods: {
		close() {
			this.dialog = false
		},
		async onSubmit() {
			const { valid } = await this.$refs.form.validate()
			if (!valid) return showToast.info('Thông tin chưa đúng, vui lòng kiểm tra lại')

			showConfirm('Xác nhận đặt hàng?', async () => {
				this.saving = true
				const payload = this.items.map(function (item) {
					return {
						DeXuat_MuaHang_ChiTiet_Id: item.DeXuat_MuaHang_ChiTiet_Id,
						HangHoa_Id: item.HangHoa_Id,
						SoLuong: item.SoLuong,
						NhaCungCap_Id: item.NhaCungCap_Id,
						DiaDiemNhan_Id: item.DiaDiemNhan_Id,
						DonViDat_Id: item.Chuan_DonViTinh_Id,
					}
				})
				await apiCallPromise('/work/HH_DeXuat_MuaHang_DatHang', {
					DataJSON: JSON.stringify(payload)
				})
				showToast.success('Đặt hàng thành công')
				this.$emit('onReload')
				this.close()
				this.saving = false
			})
		},
	},
}
</script>