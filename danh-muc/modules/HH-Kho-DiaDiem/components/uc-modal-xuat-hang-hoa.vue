<template>
	<v-dialog v-model="isShow" :width="isMobile ? undefined : 800" :fullscreen="isMobile"
		:transition="isMobile ? 'dialog-bottom-transition' : 'dialog-transition'">
		<v-card>
			<v-toolbar density="compact" elevation="0" height="144">
				<div class="d-flex flex-column pl-6">
					<v-toolbar-title>
						Xuất huỷ
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
					<!-- desktop -->
					<template v-if="!isMobile">
						<v-data-table v-if="selectedItem?.arraySoLuong?.length > 0" :headers="headerArraySoLuong"
							:items="selectedItem?.arraySoLuong" density="compact" hide-default-footer>
							<template v-slot:item.DonViTinh="{ item }">
								<v-select dense="compact" v-model="item.DonViXuat_Id" :items="item.DSDonViTinh"
									item-title="TenDonViQuyDoi" item-value="DonViTinh_Id" variant="underlined"
									@update:model-value="handleSelectedDonViTinh(item)">
								</v-select>
							</template>

							<template v-slot:item.SoLuongXuat="{ item }">
								<v-text-field v-model="item.SoLuongXuat" variant="underlined" type="number" reverse
									:rules="[maxRule(item), rules.greaterThanZero]"
									:disabled="item.DonViXuat_Id === null" step="0.01"
									@blur="item.SoLuongXuat = format2(item.SoLuongXuat)">
								</v-text-field>
							</template>
							<template v-slot:item.Tong="{ item }">
								{{ '/' + (item.TongSauQuyDoi ?? item.Tong) }}
							</template>
						</v-data-table>

						<v-data-table v-if="selectedItem?.arrayCaBiet?.length > 0" :headers="headerArrayCaBiet"
							:items="selectedItem?.arrayCaBiet" density="compact" hide-default-footer>

							<template v-slot:item.Tong="{ item }">
								{{ '/' + item.Tong }}
							</template>
						</v-data-table>
						<v-textarea v-model="GhiChu" rows="2" auto-grow label="Ghi chú" class="mt-2"></v-textarea>
					</template>
					<!-- mobile -->
					<template v-else>
						<!-- Hàng hoá số lượng -->
						<v-list v-if="selectedItem?.arraySoLuong?.length > 0" lines="one">
							<v-list-item v-for="(ItemHangHoa, childIndex) in selectedItem.arraySoLuong"
								:key="childIndex" lines="false">
								<v-list-item-subtitle>
									<v-row dense class="mt-2">
										<v-col cols="6">
											<v-select class="mobile-input mt-1" dense="compact"
												v-model="ItemHangHoa.DonViXuat_Id" :items="ItemHangHoa.DSDonViTinh"
												item-title="TenDonViQuyDoi" item-value="DonViTinh_Id"
												variant="underlined" label="Đơn vị tính"
												@update:model-value="handleSelectedDonViTinh(ItemHangHoa)">
											</v-select>
										</v-col>
										<v-col cols="6">
											<v-text-field class="mobile-input mt-1" v-model="ItemHangHoa.SoLuongXuat"
												variant="underlined" type="number" label="Số lượng "
												:rules="[maxRule(ItemHangHoa), rules.greaterThanZero]" step="0.01"
												@blur="ItemHangHoa.SoLuongXuat = format2(ItemHangHoa.SoLuongXuat)"
												:disabled="ItemHangHoa.DonViXuat_Id === null">
												<template #append-inner>
													<span class="text-grey">
														{{ '/' + (ItemHangHoa.TongSauQuyDoi ?? ItemHangHoa.Tong)
														}}</span>
												</template>
											</v-text-field>
										</v-col>
										<v-col cols='12'>
											<v-textarea v-model="GhiChu" rows="2" auto-grow label="Ghi chú"
												class="mt-2"></v-textarea>
										</v-col>
									</v-row>
								</v-list-item-subtitle>
							</v-list-item>
						</v-list>
						<!-- Hàng hoá cá biệt -->
						<v-list v-if="selectedItem?.arrayCaBiet?.length > 0" lines="one">
							<v-list-item v-for="(CaBiet, childIndex) in selectedItem.arrayCaBiet" :key="childIndex"
								lines="false">
								<v-list-item-title class="text-body-2 font-weight-medium">
									{{ CaBiet.SoSeries }}
								</v-list-item-title>
								<v-list-item-subtitle>
									<v-row dense class="mt-2">
										<v-col cols="6">
											<div class="text-caption text-medium-emphasis">Đơn vị tính</div>
											<div class="text-body-2 font-weight-medium">
												{{ CaBiet.TenDonVi }}
											</div>
										</v-col>

										<v-col cols="6">
											<div class="text-caption text-medium-emphasis">Số lượng</div>
											<div class="text-body-2 font-weight-medium ">
												{{ CaBiet.SoLuong }}
											</div>
										</v-col>
										<v-col cols='12'>
											<v-textarea v-model="GhiChu" rows="2" auto-grow label="Ghi chú"
												class="mt-2"></v-textarea>
										</v-col>
									</v-row>
								</v-list-item-subtitle>
							</v-list-item>
						</v-list>
					</template>
				</v-form>
			</v-card-text>

			<v-card-actions>
				<v-spacer></v-spacer>
				<v-btn color="primary" variant="tonal" @click="onSubmit">Xuất huỷ</v-btn>
			</v-card-actions>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
		props: {
			isShow: Boolean,
			selectedItem: Object,
		},
		emits: ['update:isShow', 'onReload'],
		data() {
			return {
				DSTinhTrangCaBiet,
				rules: {
					required: v => !!v || 'Trường này không được để trống',
					greaterThanZero: v => v > 0 || 'Giá trị phải lớn hơn 0',
				},
				headerArraySoLuong: [
					{ title: "Tên hàng hoá", key: "TenHangHoa", width: '300px' },
					{ title: "Tên khu vực", key: "TenKhuVuc", width: '150px' },
					{ title: "Đơn vị tính", key: "DonViTinh", width: '300px' },
					{ title: "Số lượng", key: "SoLuongXuat", width: '100px' },
					{ title: "Tổng", key: "Tong", },
				],
				headerArrayCaBiet: [
					{ title: "SoSeries", key: "SoSeries", width: '300px' },
					{ title: "Tên khu vực", key: "TenKhuVuc", width: '150px' },
					{ title: "Đơn vị tính", key: "DonViTinh", width: '300px' },
					{ title: "Số lượng", key: "SoLuong", width: '100px', align: 'end' },
					{ title: "Tổng", key: "Tong", },
				],
				GhiChu: null
			}
		},
		computed: {
			isMobile() {
				return this.$vuetify.display.smAndDown
			},
		},
		methods: {
			closeDialog() {
				this.$refs.form?.reset()
				this.$refs.form?.resetValidation()
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
				if (item.DonViXuat_Id === item.Chuan_DonViTinh_Id) {
					item.TongSauQuyDoi = item.SoLuong
					return
				}
				const QuyDoi = item.DSDonViTinh.find((x) => x.DonViTinh_Id === item.DonViXuat_Id)
				const HeSo = QuyDoi?.HeSo ?? 1
				item.TongSauQuyDoi = Number((item.SoLuong / HeSo).toFixed(2))
			},
	
			async onSubmit() {
				const { valid } = await this.$refs.form.validate();
				if (!valid) {
					showToast.info('Vui lòng nhập đầy đủ thông tin cần thiết')
					return
				}
				let tempArraySoLuong = []
				this.selectedItem.arraySoLuong.forEach((item) => {
					const tempItem = {
						HangHoa_Id: item.HangHoa_Id,
						DonViXuat_Id: item.DonViXuat_Id,
						SoLuong: item.SoLuongXuat,
						KhuVuc_Id: item.KhuVuc_Id
					}
					tempArraySoLuong.push(tempItem)
				})
				let tempArrayCaBiet = []
				this.selectedItem.arrayCaBiet.forEach((item) => {
					const tempItem = {
						CaBiet_Id: item.CaBiet_Id,
						DonViXuat_Id: item.DonViXuat_Id,
						KhuVuc_Id: item.KhuVuc_Id,
					}
					tempArrayCaBiet.push(tempItem)
				})
	
				showConfirm(
					`Việc lập phiếu xuất này ảnh hưởng trực tiếp đến tồn kho tại <strong>${this.selectedItem.TenDiaDiem}</strong></br>Bạn có chắc chắn muốn tiếp tục?`,
					() => {
						const params = {
							DiaDiem_Id: this.selectedItem.DiaDiem_Id,
							SoPhieuXuat: crypto.randomUUID(),
							LoaiPhieuXuat: 'HUY',
							NgayXuat: dayjs(new Date()).format('YYYY-MM-DD'),
							MaNguoiXuat: vueData.user.UserID,
							GhiChu: this.GhiChu,
							JsonSoLuong: tempArraySoLuong.length > 0 ? JSON.stringify(tempArraySoLuong) : null,
							JsonCaBiet: tempArrayCaBiet.length > 0 ? JSON.stringify(tempArrayCaBiet) : null,
						}
						apiCall("work/HH_PhieuXuat_Insert", params, (res) => {
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