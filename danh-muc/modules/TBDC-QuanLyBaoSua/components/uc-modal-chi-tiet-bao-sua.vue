<template>
	<v-dialog v-model="isShow" max-width="600px" :scrollable="true" :fullscreen="isMobile">
		<v-card variant="text" class="bg-white">
			<v-toolbar max-height="40px" min-height="40px" density="compact">
				<v-toolbar-title class="text-subtitle-1">
					Chi tiết báo sửa #{{ selectedBaoSua.BaoSua_Id }}
					<v-chip v-if="selectedBaoSua.DoUuTien" size="small"
						:color="mapDoUuTien[selectedBaoSua.DoUuTien].color">
						{{ mapDoUuTien[selectedBaoSua.DoUuTien].text }}
					</v-chip>
				</v-toolbar-title>

				<v-btn variant="text" density="compact" class="mr-2" icon="mdi-close" @click="closeDialog"></v-btn>
			</v-toolbar>
			<v-card-text class="ma-0 pa-0" style="">
				<v-sheet :rounded="false" variant="text">
					<div class="pa-3">
						<v-row class="">
							<v-col cols="2" style="max-width: 30px">
								<uc-avatar :AnhDaiDien_Url="selectedBaoSua.AnhDaiDien_Url"
									:Ten="selectedBaoSua.HoTenNguoiBaoSua"></uc-avatar>
							</v-col>
							<v-col class="ml-1">
								<v-row>
									<v-col>
										<div class="d-flex align-center " style=" margin-top: -5px">
											<v-icon size="small" color="grey" class="mr-1">mdi-clock-outline</v-icon>
											<span>{{ selectedBaoSua.HoTenNguoiBaoSua }}</span>
										</div>
										<div class="d-flex align-center mt-0">
											<span style="margin-top: -3px; font-size: 11px;">{{
												selectedBaoSua.ThoiGianBaoSua
											}}</span>
										</div>
									</v-col>
								</v-row>
							</v-col>
						</v-row>

						<div class="d-flex align-center py-2">
							<v-icon class="mr-3" color="#1976D2">
								mdi-devices
							</v-icon>
							<span class="text-body-2">
								{{ selectedBaoSua?.TenHangHoa }}
							</span>
						</div>
						<v-divider></v-divider>
						<v-row class="py-1">
							<v-col cols="12">
								<v-icon class="mr-2" color="#E53935">mdi-map-marker-radius-outline</v-icon>
								<span class="text-body-2">{{ selectedBaoSua.TenDiaDiem }}</span>
							</v-col>
						</v-row>
						<v-divider></v-divider>
						<v-row class="py-1">
							<v-col cols="12">
								<v-icon class="mr-2" color="#9E9E9E">mdi-message-text-outline</v-icon>
								<span class="text-body-2 mr-2">{{ selectedBaoSua.GhiChu }}</span>
							</v-col>
						</v-row>
						<v-row v-if="selectedBaoSua.DSFiles?.length" class="mt-2" dense>
							<v-col v-for="(img, index) in selectedBaoSua.DSFiles" :key="index" cols="4">
								<v-card class="position-relative">
									<v-img :src="viewFile(img)" aspect-ratio="1" cover class="rounded"
										@click="previewImage(img)" />
								</v-card>
							</v-col>
						</v-row>
					</div>

					<v-expansion-panels variant="accordion" class="d-flex" v-model="panel" multiple>
						<!-- Tiếp nhận -->
						<v-expansion-panel value="TIEP_NHAN">
							<v-expansion-panel-title min-height="40px" class="py-0 bg-blue-grey-lighten-5">
								<v-icon color="warning">mdi-numeric-1-circle-outline</v-icon>
								<span class="mx-2 text-subtitle-1">Tiếp nhận</span>
								<template #actions>
									<v-icon :color="TinhTrangXuLy.TiepNhan ? 'success' : 'grey'"
										:icon="TinhTrangXuLy.TiepNhan ? 'mdi-check' : 'mdi-pencil'" />
								</template>
							</v-expansion-panel-title>
							<v-divider></v-divider>
							<v-expansion-panel-text>
								<div class="mt-1 text-body-2" v-if="TinhTrangXuLy.TiepNhan?.TenNhanVienXuLy">
									<v-row class="align-center">
										<v-col cols="auto">
											<uc-avatar :AnhDaiDien_Url="TinhTrangXuLy.TiepNhan?.AnhDaiDien_Url"
												:Ten="TinhTrangXuLy.TiepNhan?.TenNhanVienXuLy" />
										</v-col>
										<v-col class="pl-2">
											<div class="font-weight-medium">
												{{ TinhTrangXuLy.TiepNhan.TenNhanVienXuLy }}
											</div>

											<div class="text-grey text-caption">
												{{ TinhTrangXuLy.TiepNhan.ThoiGianXuLy }}
											</div>
										</v-col>
									</v-row>
									<div v-if="TinhTrangXuLy.TiepNhan?.GhiChuXyLy" class="mt-2">
										<div class="text-grey text-caption">Ghi chú tiếp nhận</div>
										<div class="text-body-2">
											{{ TinhTrangXuLy.TiepNhan.GhiChuXyLy }}
										</div>
									</div>
								</div>
							</v-expansion-panel-text>
						</v-expansion-panel>

						<!-- Kiểm tra -->
						<!-- Nếu chưa kiểm tra -> kiểm tra xem báo đúng hay sai -->
						<v-expansion-panel v-if="TinhTrangXuLy.BaoSai === null" value="KIEM_TRA">
							<v-expansion-panel-title min-height="40px" class="py-1 bg-blue-grey-lighten-5">
								<v-icon color="teal">mdi-numeric-2-circle-outline</v-icon>
								<span class="mx-2 text-subtitle-1">Kiểm tra</span>
								<template #actions>
									<v-icon :color="TinhTrangXuLy.KiemTra ? 'success' : 'grey'"
										:icon="TinhTrangXuLy.KiemTra ? 'mdi-check' : 'mdi-pencil'" />
								</template>
							</v-expansion-panel-title>
							<v-divider></v-divider>
							<v-expansion-panel-text class="text-body-2">
								<div class="mt-1 text-body-2" v-if="TinhTrangXuLy.KiemTra?.TenNhanVienXuLy">
									<v-row class="align-center">
										<v-col cols="auto">
											<uc-avatar :AnhDaiDien_Url="TinhTrangXuLy.KiemTra?.AnhDaiDien_Url"
												:Ten="TinhTrangXuLy.KiemTra?.TenNhanVienXuLy" />
										</v-col>
										<v-col class="pl-2">
											<div class="font-weight-medium">
												{{ TinhTrangXuLy.KiemTra.TenNhanVienXuLy }}
											</div>

											<div class="text-grey text-caption">
												{{ TinhTrangXuLy.KiemTra.ThoiGianXuLy }}
											</div>
										</v-col>
									</v-row>
									<div v-if="TinhTrangXuLy.KiemTra?.GhiChuXyLy" class="mt-2">
										<div class="text-grey text-caption">Ghi chú kiểm tra</div>
										<div class="text-body-2">
											{{ TinhTrangXuLy.KiemTra.GhiChuXyLy }}
										</div>
									</div>
								</div>
								<!-- Nếu chưa kiểm tra -->
								<v-row v-else style="margin-top: 0px">
									<v-col class="mt-0 text-grey-darken-1" cols="12"
										style="display: flex; align-items: center;">
										<span class="mr-2"><b>Xác nhận: </b></span>
										<v-chip-group class="mr-2" v-model="KiemTra.BaoSuaSai">
											<v-chip prepend-icon="mdi-check" size="small" value="DUNG" color="primary">
												Báo đúng
											</v-chip>
											<v-chip prepend-icon="mdi-close-box" size="small" value="SAI" color="error">
												Báo sai
											</v-chip>
										</v-chip-group>
									</v-col>
									<v-textarea rows="2" :clearable="false" class="" density="compact"
										v-model="KiemTra.GhiChu" label="Ghi chú kiểm tra">
									</v-textarea>
									<v-btn block color="primary" class="mr-3 mt-2 mb-1" variant="tonal"
										:disabled="KiemTra.BaoSuaSai == null || !KiemTra.GhiChu?.trim()"
										@click="updateKiemTraBaoSua()">Lưu
									</v-btn>
								</v-row>
							</v-expansion-panel-text>
						</v-expansion-panel>
						<!-- Nếu báo sai -->
						<v-expansion-panel v-else value="KIEM_TRA">
							<v-expansion-panel-title min-height="40px" class="py-1 bg-blue-grey-lighten-5">
								<v-icon color="teal">mdi-numeric-2-circle-outline</v-icon>
								<span class="mx-2 text-subtitle-1">Kiểm tra</span>
								<v-chip v-if="TinhTrangXuLy.BaoSai" size="small" color="error" variant="tonal">
									<v-icon start size="16">mdi-alert-circle</v-icon>
									Báo sai
								</v-chip>
								<template #actions>
									<v-icon :color="TinhTrangXuLy.BaoSai ? 'success' : 'grey'"
										:icon="TinhTrangXuLy.BaoSai ? 'mdi-check' : 'mdi-pencil'" />
								</template>
							</v-expansion-panel-title>
							<v-divider></v-divider>
							<v-expansion-panel-text class="text-body-2">
								<v-row v-if="TinhTrangXuLy.BaoSai?.TenNhanVienXuLy" class="d-flex align-center">
									<v-col cols="auto">
										<uc-avatar :AnhDaiDien_Url="TinhTrangXuLy.BaoSai?.AnhDaiDien_Url"
											:Ten="TinhTrangXuLy.BaoSai?.TenNhanVienXuLy" />
									</v-col>
									<v-col class="pl-2">
										<div class="font-weight-medium">
											{{ TinhTrangXuLy.BaoSai.TenNhanVienXuLy }}
										</div>

										<div class="text-grey text-caption">
											{{ TinhTrangXuLy.BaoSai.ThoiGianXuLy }}
										</div>
									</v-col>
								</v-row>
								<div v-if="TinhTrangXuLy.BaoSai?.GhiChuXyLy" class="mt-2">
									<div class="text-grey text-caption">Ghi chú báo sai</div>
									<div class="text-body-2">
										{{ TinhTrangXuLy.BaoSai.GhiChuXyLy }}
									</div>
								</div>
							</v-expansion-panel-text>
						</v-expansion-panel>
						<!-- Sửa chữa-->
						<v-expansion-panel v-if="TinhTrangXuLy.BaoSai === null && TinhTrangXuLy.KiemTra !== null"
							value="SUA_CHUA">
							<v-expansion-panel-title min-height="40px" class="bg-blue-grey-lighten-5 py-1">
								<v-icon color="success">mdi-numeric-3-circle-outline</v-icon>
								<span class="mx-2 text-subtitle-1 ">Sửa chữa</span>
								<v-chip v-if="TinhTrangXuLy.DaXong || TinhTrangXuLy.Hu" size="small"
									:color="TinhTrangXuLy.DaXong ? 'success' : 'orange'" variant="tonal">
									<v-icon start size="16">mdi-alert-circle</v-icon>
									{{ TinhTrangXuLy.DaXong ? 'Đã sửa' : 'Hư' }}
								</v-chip>
								<template v-slot:actions="{ expanded }">
									<v-icon v-if="isFinish" :color="isFinish ? 'warning' : '#9E9E9E'"
										:icon="isFinish ? 'mdi-cog-outline' : 'mdi-pencil'">
									</v-icon>
									<v-icon v-else :color="isFinish ? 'success' : '#9E9E9E'"
										:icon="isFinish ? 'mdi-check' : 'mdi-pencil'"></v-icon>
								</template>
							</v-expansion-panel-title>

							<v-divider></v-divider>

							<v-expansion-panel-text class="text-body-2">
								<div class="mt-1 text-body-2" v-if="TinhTrangXuLy.DangSua?.TenNhanVienXuLy">
									<v-row class="align-center ">
										<v-col cols="auto">
											<uc-avatar :AnhDaiDien_Url="TinhTrangXuLy.DangSua?.AnhDaiDien_Url"
												:Ten="TinhTrangXuLy.DangSua?.TenNhanVienXuLy" />
										</v-col>
										<v-col class="pl-2">
											<div class="font-weight-medium">
												{{ TinhTrangXuLy.DangSua.TenNhanVienXuLy }}
											</div>

											<div class="text-grey text-caption">
												{{ TinhTrangXuLy.DangSua.ThoiGianXuLy }}
											</div>
										</v-col>
									</v-row>
									<div v-if="TinhTrangXuLy.DangSua?.GhiChuXyLy"
										class="mt-y border-b border-opacity-25">
										<div class="text-grey text-caption">Ghi chú đang sửa</div>
										<div class="text-body-2">
											{{ TinhTrangXuLy.DangSua.GhiChuXyLy }}
										</div>
									</div>
								</div>
								<div class="mt-1 text-body-2" v-if="TinhTrangXuLy.DaXong?.TenNhanVienXuLy">
									<v-row class="align-center">
										<v-col cols="auto">
											<uc-avatar :AnhDaiDien_Url="TinhTrangXuLy.DaXong?.AnhDaiDien_Url"
												:Ten="TinhTrangXuLy.DaXong?.TenNhanVienXuLy" />
										</v-col>
										<v-col class="pl-2">
											<div class="font-weight-medium">
												{{ TinhTrangXuLy.DaXong.TenNhanVienXuLy }}
											</div>

											<div class="text-grey text-caption">
												{{ TinhTrangXuLy.DaXong.ThoiGianXuLy }}
											</div>
										</v-col>
									</v-row>
									<div v-if="TinhTrangXuLy.DaXong?.GhiChuXyLy" class="mt-2">
										<div class="text-grey text-caption">Ghi chú đã xong</div>
										<div class="text-body-2">
											{{ TinhTrangXuLy.DaXong.GhiChuXyLy }}
										</div>
									</div>
								</div>
								<div class="mt-1 text-body-2" v-if="TinhTrangXuLy.Hu?.TenNhanVienXuLy">
									<v-row class="align-center">
										<v-col cols="auto">
											<uc-avatar :AnhDaiDien_Url="TinhTrangXuLy.Hu?.AnhDaiDien_Url"
												:Ten="TinhTrangXuLy.Hu?.TenNhanVienXuLy" />
										</v-col>
										<v-col class="pl-2">
											<div class="font-weight-medium">
												{{ TinhTrangXuLy.Hu.TenNhanVienXuLy }}
											</div>

											<div class="text-grey text-caption">
												{{ TinhTrangXuLy.Hu.ThoiGianXuLy }}
											</div>
										</v-col>
									</v-row>
									<div v-if="TinhTrangXuLy.Hu?.GhiChuXyLy" class="mt-2">
										<div class="text-grey text-caption">Ghi chú hư</div>
										<div class="text-body-2">
											{{ TinhTrangXuLy.Hu.GhiChuXyLy }}
										</div>
									</div>
								</div>

								<v-form v-if="!isFinish" ref="formSua" class="bg-white">
									<v-row class="pb-0 mb-0">
										<v-col class="d-md-flex align-center pb-0">
											<div class="text-body-2 mr-2">Tình trạng sửa:</div>
											<v-chip-group required :rules="[v => !!v || 'Chọn tình trạng']"
												v-model="SuaChua.TinhTrangSua">
												<v-chip size="small" prepend-icon="mdi-cog-outline" color="warning"
													value="DANG_SUA" v-if="TinhTrangXuLy.DangSua === null">
													Đang sửa
												</v-chip>
												<v-chip size="small" prepend-icon="mdi-check" color="success"
													value="DA_XONG">
													Sửa xong
												</v-chip>
												<v-chip size="small" prepend-icon="mdi-cog-off" color="error"
													value="HU">Không sửa được</v-chip>
											</v-chip-group>
										</v-col>
									</v-row>

									<v-row class="mt-0">
										<v-col>
											<v-textarea :clearable="false" rows="4" required
												:rules="[v => !!v || 'Nhập ghi chú sửa']" class="" density="compact"
												v-model="SuaChua.GhiChu" label="Ghi chú sửa ">
											</v-textarea>
										</v-col>
									</v-row>

									<uc-input-price v-if="SuaChua.TinhTrangSua === 'DA_XONG'" class="mt-2"
										:rules="[v => !!v || 'Nhập chi phí']" label="Chi phí sửa"
										v-model="SuaChua.ChiPhi">
									</uc-input-price>

									<v-btn block color="primary" class="mr-3 mt-2" variant="tonal"
										:disabled="!['DANG_SUA', 'DA_XONG', 'HU'].includes(SuaChua.TinhTrangSua) || !SuaChua.GhiChu?.trim()"
										@click="onSubmitSuaChua">
										Lưu
									</v-btn>
								</v-form>
							</v-expansion-panel-text>
						</v-expansion-panel>
					</v-expansion-panels>
				</v-sheet>
			</v-card-text>
		</v-card>
	</v-dialog>

	<v-dialog v-model="showPreview" max-width="800">
		<v-card>
			<v-img :src="previewUrl" contain max-height="80vh" />
		</v-card>
	</v-dialog>

	<v-dialog v-model="isShowDialogTaiSanThayThe" max-width="500px">
		<v-card>
			<v-form ref="formThayTheTaiSan">
				<v-toolbar density="compact">
					<v-toolbar-title>Chọn tài sản thay thế, thêm mới</v-toolbar-title>

					<v-btn variant="text" icon="mdi-close" @click="isShowDialogTaiSanThayThe = false"></v-btn>
				</v-toolbar>

				<v-divider></v-divider>
				<v-card-text class="text-center">
					<v-autocomplete required :rules="[v => !!v || 'Vui lòng chọn tài sản']"
						:items="dsTaiSanTrongPhongBan" v-model="taiSanThayTheDangChon" item-value="MaCaBiet"
						item-title="TenTaiSan"></v-autocomplete>
				</v-card-text>
				<v-card-actions>
					<v-spacer></v-spacer>
					<v-btn color="primary" class="mr-3 my-2" variant="tonal"
						@click="validate('formThayTheTaiSan', insertTaiSanThayThe)">Thêm
					</v-btn>
				</v-card-actions>
			</v-form>
		</v-card>
	</v-dialog>
</template>

<script>
export default {
	props: {
		isShow: Boolean,
		selectedBaoSua: Object,
	},
	emits: ['load-detail', 'update:isShow', 'load-data'],
	data() {
		return {
			mapDoUuTien,

			isShowDialogTaiSanThayThe: false,

			panel: [],

			headerTaiSanThayThe: [
				{ title: "Tên tài sản", value: "TenTaiSan" },
				{ title: "Xóa", align: "end", value: "Xoa" },
			],


			showPreview: false,
			previewUrl: null,
			KiemTra: {
				BaoSuaSai: null,
				GhiChu: null,
			},
			SuaChua: {
				TinhTrangSua: null,
				GhiChu: null,
				ChiPhi: null,
			}
		}
	},
	mounted() {
	},

	computed: {
		isMobile() {
			return this.$vuetify.display.smAndDown
		},

		TinhTrangXuLy() {
			return this.selectedBaoSua?.TinhTrangXuLy ?? {}
		},
		isFinish() {
			return this.TinhTrangXuLy.DaXong || this.TinhTrangXuLy.Hu
		}
	},
	watch: {

	},
	methods: {
		closeDialog() {
			this.$emit('update:isShow', false)
			this.$emit('load-data')
			this.panel = []
		},

		viewFile(FileID) {
			const urlReadFile = 'https://file.zentea.vn/work/HH_FileData/'
			return `${urlReadFile}${FileID}`
		},

		previewImage(img) {
			this.previewUrl = this.viewFile(img)
			this.showPreview = true
		},

		async updateKiemTraBaoSua() {
			const params = {
				BaoSua_Id: this.selectedBaoSua.BaoSua_Id,
				TinhTrang: this.KiemTra.BaoSuaSai,
				GhiChu: this.KiemTra.GhiChu
			}
			const $this = this
			apiCall("work/TS_BaoSua_Update_KiemTra", params, (res) => {
				if (res) {
					showToast.success("Thành công");
					$this.$emit('load-detail')
				}
			})

		},
		async onSubmitSuaChua() {
			const { valid } = await this.$refs.formSua.validate()
			if (!valid) return showToast.info('Thông tin chưa hợp lệ, vui lòng kiểm tra lại')
			const params = {
				BaoSua_Id: this.selectedBaoSua.BaoSua_Id,
				TinhTrang: this.SuaChua.TinhTrangSua,
				GhiChu: this.SuaChua.GhiChu,
				ChiPhi: this.SuaChua.ChiPhi ?? 0
			}
			const $this = this
			apiCall("work/TS_BaoSua_Update_SuaChua", params, (res) => {
				if (res) {
					showToast.success("Thành công");
					$this.$emit('load-detail')
				}
			})
		},
	},
}

</script>