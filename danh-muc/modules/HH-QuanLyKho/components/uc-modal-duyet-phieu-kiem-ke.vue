<template>
	<v-dialog v-model="isShow" :width="isMobile ? undefined : 1300" :fullscreen="isMobile">
		<v-card>
			<v-toolbar density="compact" elevation="0" class="sticky-toolbar">
				<v-toolbar-title>
					Xem chi tiết • {{ selectedItem.TenPhieu }}
				</v-toolbar-title>
				<v-spacer />
				<v-btn size="small" variant="text" icon="mdi-close" @click="closeDialog" />
			</v-toolbar>
			<v-divider></v-divider>
			<v-card-text class="pt-1">
				<v-form ref="form">
					<v-data-table :items="selectedItem?.arrayKiemKe" :headers="headerHangHoa"
						v-model:expanded="selectedItem.expanded" hide-default-footer height="600" show-expand
						density="compact" :disable-sort="true" items-per-page-text="Bản ghi"
						:items-per-page-options="[50, 100, 200]" fixed-header item-value="HangHoa_Id">

						<template v-slot:item.data-table-expand="{ internalItem, isExpanded, toggleExpand }">
							<div class="d-flex justify-center align-center">
								<v-btn :icon="isExpanded(internalItem) ? 'mdi-chevron-up' : 'mdi-chevron-down'"
									size="small" @click="toggleExpand(internalItem)" variant="text"></v-btn>
							</div>
						</template>

						<template v-slot:expanded-row="{ columns, item }">
							<tr v-if="item.DSCaBiet?.length > 0">
								<td :colspan="columns.length" class="pa-0">
									<v-table density="compact">
										<tbody class="bg-surface-light">
											<tr>
												<th class="text-center" style="width:100px">Mã vạch</th>
												<th class="text-start" style="width:350px"> Số Serial</th>
												<th class="text-center">
													Địa điểm / Khu vực / Tình trạng hiện tại
												</th>
												<th class="text-center" style="min-width:200px">
													Địa điểm / Khu vực / Tình trạng thực tế
												</th>
												<th class="text-center" style="width:200px">Ghi chú</th>
												<th class="text-center" style="width:250px">Dự kiến duyệt</th>
											</tr>
										</tbody>

										<tbody>
											<tr v-for="(CaBiet, index) in item.DSCaBiet" :key="index">
												<td class="text-center">
													{{ CaBiet.MaVach === '' ? 'Chưa có' : CaBiet.MaVach
													}}
												</td>
												<td class="text-start">
													{{ CaBiet.SoSeries }}
												</td>
												<td class="text-center">
													{{ getTenDiaDiem(CaBiet.DiaDiemHienTai_Id) + ' / ' +
													getTenKhuVuc(CaBiet.KhuVucHienTai_Id) + ' / ' }}
													<v-chip
														:color="mapTinhTrangHangHoaCaBiet[CaBiet.TinhTrangHienTai]?.color ?? ''"
														size="small">
														{{
														mapTinhTrangHangHoaCaBiet[CaBiet.TinhTrangHienTai]?.text ??
														"Chưa rõ"
														}}
													</v-chip>
												</td>
												<td class="text-center">
													{{ getTenDiaDiem(CaBiet.DiaDiemThucTe_Id) + ' / ' +
													getTenKhuVuc(CaBiet.KhuVucThucTe_Id) + ' / ' }}
													<v-chip
														:color="mapTinhTrangHangHoaCaBiet[CaBiet.TinhTrangThucTe]?.color ?? ''"
														size="small">
														{{ mapTinhTrangHangHoaCaBiet[CaBiet.TinhTrangThucTe]?.text ??
														"Chưa rõ" }}
													</v-chip>
												</td>
												<td class="text-center">
													{{ CaBiet.GhiChu }}

												</td>
												<td class="text-center">
													<!-- <v-select class="mt-2" v-model="CaBiet.Duyet_DiaDiemThucTe_Id"
														:items="DSDiaDiem" item-value="DiaDiem_Id"
														item-title="TenDiaDiem" label="Địa điểm" color="primary"
														density="compact">
													</v-select>
													<v-select class="mt-2" v-model="CaBiet.Duyet_KhuVucThucTe_Id"
														:items="DSKhuVucKho" clearable item-value="KhuVuc_Id"
														item-title="TenKhuVuc" label="Khu vực" color="primary"
														density="compact">
													</v-select>
													<v-select class="mt-2" v-model="CaBiet.Duyet_TinhTrangThucTe"
														:items="DSTinhTrangCaBiet" item-value="value" item-title="title"
														label="Tình trạng" color="primary" density="compact">
													</v-select> -->
													{{ getTenDiaDiem(CaBiet.Duyet_DiaDiemThucTe_Id) + ' / ' +
													getTenKhuVuc(CaBiet.Duyet_KhuVucThucTe_Id) + ' / ' }}
													<v-chip
														:color="mapTinhTrangHangHoaCaBiet[CaBiet.Duyet_TinhTrangThucTe]?.color ?? ''"
														size="small">
														{{ mapTinhTrangHangHoaCaBiet[CaBiet.Duyet_TinhTrangThucTe]?.text
														??
														"Chưa rõ" }}
													</v-chip>
												</td>
											</tr>
										</tbody>
									</v-table>
								</td>
							</tr>

							<tr v-if="item.DSSoLuong?.length > 0">
								<td :colspan="columns.length" class="pa-0">
									<v-sheet rounded="lg" border>
										<v-table density="compact">
											<tbody class="bg-surface-light">
												<tr>
													<th class="text-start">Tên khu vực</th>
													<th class="text-start" style="width:150px">Đơn vị</th>
													<th class="text-right">Thực tế</th>
													<th class="text-right">Hệ thống</th>
													<th class="text-center" style="width:200px">Ghi chú</th>
													<th class="text-right" style="width:250px">Dự kiến duyệt</th>
												</tr>
											</tbody>

											<tbody>
												<tr v-for="(HangHoa, index) in item.DSSoLuong" :key="index">
													<td class="text-start">
														{{ HangHoa.TenKhuVuc }}
													</td>
													<td>
														{{ getTenDonViTinh(HangHoa.DonViKiemKe_Id) }}
													</td>
													<td class="text-right"
														:class="{ 'diff-changed': HangHoa.SoLuongThucTe !== HangHoa.TongSauQuyDoi }">
														{{ HangHoa.SoLuongThucTe }}
													</td>
													<td class="text-right">
														{{ HangHoa.TongSauQuyDoi }}
													</td>
													<td class="text-center">
														{{ HangHoa.GhiChu }}
													</td>
													<td class="text-right">

														{{ HangHoa.SoLuongDuyet }}
													</td>
												</tr>
											</tbody>
										</v-table>
									</v-sheet>
								</td>
							</tr>
						</template>

						<template #no-data>
							<uc-empty text="Chưa có hàng hoá để hiển thị" />
						</template>
					</v-data-table>
				</v-form>
			</v-card-text>
			<v-card-actions>
				<v-spacer></v-spacer>
				<v-btn color="primary" variant="tonal" @click="onSubmit">Duyệt</v-btn>
			</v-card-actions>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
		props: {
			isShow: Boolean,
			selectedItem: Object,
			DSDiaDiem: Array,
			DSKhuVuc: Array,
			DSDonViTinh: Array,
		},
	
		emits: ['update:isShow', 'onReload'],
	
		data() {
			return {
				mapTinhTrangHangHoaCaBiet,
				DSTinhTrangCaBiet,
				rules: {
					required: v => !!v || 'Trường này không được để trống',
					greaterThanZero: v => v >= 0 || 'Giá trị phải lớn hơn 0',
					noSpecialChar: v =>
						/^[a-zA-Z0-9\s]+$/.test(v) || 'Không được chứa ký tự đặc biệt',
				},
				headerHangHoa: [
					{ title: "", key: 'data-table-expand', align: 'start', width: '100' },
					{ title: "Tên hàng hoá", key: "TenHangHoa", align: 'start' },
				],
				expanded: null,
			}
		},
		computed: {
			isMobile() {
				return this.$vuetify.display.xs
			},
			DSKhuVucKho() {
				return [
					{ KhuVuc_Id: 0, TenKhuVuc: 'Kho' },
					...this.DSKhuVuc
				]
			},
		},
		watch: {},
		methods: {
			closeDialog() {
				this.$refs.form?.reset()
				this.$refs.form?.resetValidation()
				this.$emit('update:isShow', false)
			},
	
			getTenDiaDiem(DiaDiem_Id) {
				const DiaDiem = this.DSDiaDiem.find((x) => x.DiaDiem_Id === DiaDiem_Id)
				return DiaDiem?.TenDiaDiem ?? "Chưa rõ"
			},
	
			getTenKhuVuc(KhuVuc_Id) {
				const KhuVuc = this.DSKhuVucKho.find((x) => x.KhuVuc_Id === KhuVuc_Id)
				return KhuVuc?.TenKhuVuc ?? "Chưa rõ"
			},
	
			getTenDonViTinh(DonViTinh_Id) {
				const DonViTinh = this.DSDonViTinh?.find((x) => x.DonViTinh_Id === DonViTinh_Id)
				return DonViTinh?.TenDonVi ?? ""
			},
	
			format2(v) {
				const n = parseFloat(v)
				if (isNaN(n)) return ''
				return (Math.round(n * 100) / 100).toFixed(2)
			},
	
			async onSubmit() {
				const { valid } = await this.$refs.form.validate();
				if (!valid) {
					showToast.info('Vui lòng nhập đầy đủ thông tin cần thiết')
					return
				}
				let arraySoLuong = []
				let arrayCaBiet = []
				this.selectedItem.arrayKiemKe.forEach((HangHoa) => {
					if (HangHoa.Is_CaBiet) {
						const DSCaBiet = HangHoa.DSCaBiet
						DSCaBiet.forEach((CaBiet) => {
							const tempCaBiet = {
								PhieuKiemKe_ChiTiet_CaBiet_Id: CaBiet.PhieuKiemKe_ChiTiet_CaBiet_Id,
								CaBiet_Id: CaBiet.CaBiet_Id,
								TinhTrangThucTe: CaBiet.TinhTrangThucTe ?? null,
								DiaDiemThucTe_Id: CaBiet.DiaDiemThucTe_Id ?? null,
								KhuVucThucTe_Id: CaBiet.KhuVucThucTe_Id ?? null,
								// duyệt
								Duyet_TinhTrangThucTe: CaBiet.Duyet_TinhTrangThucTe ?? null,
								Duyet_DiaDiemThucTe_Id: CaBiet.Duyet_DiaDiemThucTe_Id ?? null,
								Duyet_KhuVucThucTe_Id: CaBiet.Duyet_KhuVucThucTe_Id ?? null,
								GhiChu: CaBiet.GhiChu ?? null,
								TinhTrangKiemKe: CaBiet.TinhTrangKiemKe ?? null,
							}
							arrayCaBiet.push(tempCaBiet)
						})
					} else {
						const DSSoLuong = HangHoa.DSSoLuong
						DSSoLuong.forEach((ItemHangHoa) => {
							const tempSoLuong = {
								PhieuKiemKe_ChiTiet_Id: ItemHangHoa.PhieuKiemKe_ChiTiet_Id,
								HangHoa_Id: ItemHangHoa.HangHoa_Id,
								KhuVuc_Id: ItemHangHoa.KhuVuc_Id,
								DonViKiemKe_Id: ItemHangHoa.DonViKiemKe_Id ?? null,
								SoLuongKho: ItemHangHoa.TongSauQuyDoi ?? null,
								SoLuongThucTe: ItemHangHoa.SoLuongThucTe === '' ? null : Number(ItemHangHoa.SoLuongThucTe),
								SoLuongDuyet: ItemHangHoa.SoLuongDuyet,
								GhiChu: ItemHangHoa.GhiChu ?? null,
								TinhTrangKiemKe: ItemHangHoa.TinhTrangKiemKe
							}
							arraySoLuong.push(tempSoLuong)
						})
	
					}
				})
	
				const params = {
					PhieuKiemKe_Id: this.selectedItem.Id,
					TinhTrang: 'HOAN_THANH',
					JsonSoLuong: arraySoLuong.length > 0 ? JSON.stringify(arraySoLuong) : null,
					JsonCaBiet: arrayCaBiet.length > 0 ? JSON.stringify(arrayCaBiet) : null,
				}
				apiCall("work/HH_PhieuKiemKe_Update", params, (res) => {
					if (res) showToast.success("Thành công");
					this.$emit('onReload', { Id: this.selectedItem.Id })
					this.closeDialog()
				})
			}
		},
	}
</script>