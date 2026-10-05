<template>
	<v-dialog v-model="isShow" :width="isMobile ? undefined : 400" :fullscreen="isMobile"
		:transition="isMobile ? 'dialog-bottom-transition' : 'dialog-transition'">
		<v-card>
			<v-toolbar density="compact" elevation="0" height="128">
				<div class="d-flex flex-column pl-6">
					<v-toolbar-title>
						Luân chuyển
					</v-toolbar-title>
					<div class="text-subtitle-2">
						Địa điểm hiện tại: {{ selectedItem.TenDiaDiem }}
					</div>
					<div class="text-subtitle-2">
						Khu vực hiện tại: {{ selectedItem.TenKhuVuc }}
					</div>
					<div class="text-subtitle-2">
						Tên hàng hoá: {{ selectedItem.TenHangHoa }}
					</div>
				</div>
				<v-spacer />
				<v-btn size="small" variant="text" icon="mdi-close" @click="closeDialog" />
			</v-toolbar>
			<v-divider></v-divider>
			<v-card-text class="pt-1">
				<v-form ref="form">
					<v-row dense>
						<v-col cols="12" class="mb-1">
							<v-autocomplete color="primary" v-model="selectedItem.KhuVucDen_Id" density="compact"
								:items="DSKhuVucFilter" item-value="KhuVuc_Id" item-title="TenKhuVuc" label="Khu vực">
							</v-autocomplete>
						</v-col>
						<v-col cols="12">
							<v-select class="mt-1" dense="compact" v-model="selectedItem.DonViChuyen_Id"
								:items="selectedItem.DSDonViTinh" item-title="TenDonViQuyDoi" item-value="DonViTinh_Id"
								label="Đơn vị tính" @update:model-value="handleSelectedDonViTinh(selectedItem)">
							</v-select>
						</v-col>
						<v-col cols="12" class="mb-1">
							<v-text-field class=" mt-1" v-model="selectedItem.SoLuongChuyen" type="number"
								label="Số lượng " :rules="[maxRule(selectedItem), rules.greaterThanZero]" step="0.01"
								@blur="selectedItem.SoLuongChuyen = format2(selectedItem.SoLuongChuyen)"
								:disabled="selectedItem.DonViTinh_Id === null">
								<template #append-inner>
									<span class="text-grey">
										{{ '/' + (selectedItem.TongSauQuyDoi ?? selectedItem.Tong) }}</span>
								</template>
							</v-text-field>
						</v-col>
					</v-row>
				</v-form>
			</v-card-text>
			<v-card-actions>
				<v-spacer></v-spacer>
				<v-btn color="primary" @click="onSubmit" variant="flat">
					Luân chuyển
				</v-btn>
			</v-card-actions>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
		props: {
			isShow: Boolean,
			selectedItem: Object,
			DSKhuVuc: Array,
		},
		emits: ['update:isShow', 'onReload'],
		data() {
			return {
				rules: {
					greaterThanZero: v => v > 0 || 'Giá trị phải lớn hơn 0',
				},
			}
		},
		computed: {
			DSKhuVucFilter() {
				let res = this.DSKhuVuc.filter((KhuVuc) => KhuVuc.DiaDiem_Id === this.selectedItem.DiaDiem_Id)
				return [
					{ KhuVuc_Id: 0, TenKhuVuc: 'Kho' },
					...res
				]
			},
			isMobile() {
				return this.$vuetify.display.smAndDown
			},
		},
		methods: {
			closeDialog() {
				this.$emit('update:isShow', false)
			},
	
			maxRule(item) {
				return v =>
					Number(v) > 0 &&
					Number(v) <= (item.TongSauQuyDoi ?? item.Tong) || `Tối đa ${item.TongSauQuyDoi}`
			},
	
			format2(v) {
				const n = parseFloat(v)
				if (isNaN(n)) return ''
				return (Math.round(n * 100) / 100).toFixed(2)
			},
	
			handleSelectedDonViTinh(item) {
				if (item.DonViChuyen_Id === item.Chuan_DonViTinh_Id) {
					item.TongSauQuyDoi = item.SoLuong
					return
				}
				const QuyDoi = item.DSDonViTinh.find((x) => x.DonViTinh_Id === item.DonViChuyen_Id)
				item.TongSauQuyDoi = Number((item.SoLuong / (QuyDoi.HeSo ?? 1)).toFixed(2))
			},
	
			async onSubmit() {
				const { valid } = await this.$refs.form.validate();
				if (!valid) {
					showToast.info('Thông tin chưa đầy đủ hoặc chưa chính xác')
					return
				}
	
				let tempArraySoLuong = []
	
				const tempItem = {
					HangHoa_Id: this.selectedItem.HangHoa_Id,
					DonViChuyen_Id: this.selectedItem.DonViChuyen_Id,
					SoLuong: this.selectedItem.SoLuongChuyen,
					KhuVucHienTai_Id: this.selectedItem.KhuVuc_Id,
					KhuVucDen_Id: this.selectedItem.KhuVucDen_Id
				}
				tempArraySoLuong.push(tempItem)
				showConfirm(
					`Việc luân chuyển này ảnh hưởng trực tiếp đến tồn kho tại <strong>${this.selectedItem.TenDiaDiem}</strong></br>Bạn có chắc chắn muốn tiếp tục?`,
					() => {
						const params = {
							DiaDiemHienTai_Id: this.selectedItem.DiaDiem_Id,
							DiaDiemDen_Id: this.selectedItem.DiaDiem_Id,
							JsonSoLuong: tempArraySoLuong?.length > 0 ? JSON.stringify(tempArraySoLuong) : null,
							JsonCaBiet: null,
						}
						apiCall("work/HH_Kho_LuanChuyen", params, (res) => {
							if (res) showToast.success("Thành công");
							this.closeDialog()
							this.$emit('onReload')
						})
					}
				)
			}
		},
	}
</script>