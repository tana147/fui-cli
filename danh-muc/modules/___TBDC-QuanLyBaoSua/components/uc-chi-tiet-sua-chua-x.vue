<template>
	<v-dialog v-model="isOpen" max-width="600px" :scrollable="true" :fullscreen="$vuetify.display.mobile">
		<v-card variant="text" class="bg-white">
			<v-toolbar max-height="40px" min-height="40px" density="compact">
				<v-toolbar-title class="text-subtitle-1">Chi tiết báo sửa
					#{{ MaBaoSua }}</v-toolbar-title>

				<v-btn variant="text" density="compact" class="mr-2" icon="mdi-close" @click="isOpen = false"></v-btn>
			</v-toolbar>
			<v-card-text class="ma-0 pa-0" style="">
				<v-sheet v-if="isLoading" :rounded="false" variant="text">
					<v-skeleton-loader :rounded="false" type="article"></v-skeleton-loader>
				</v-sheet>
				<v-sheet v-else :rounded="false" variant="text">
					<div class="pa-3">
						<v-row class="">
							<v-col cols="2" style="max-width: 30px">
								<v-avatar style="border: 1px solid #e0b44b " size="30" class="mr-2">
									<v-img
										:src="'https://file.lhbs.vn/me/avatarOrigin/' + thongTinBaoSua.NguoiBaoSua + '.jpg'">
									</v-img>
								</v-avatar>
							</v-col>
							<v-col class="ml-1">
								<v-row>
									<v-col>
										<div class="d-flex align-center " style=" margin-top: -5px">
											<!-- <v-icon size="small" color="grey" class="mr-1">mdi-clock-outline</v-icon> -->

											<span>{{ thongTinBaoSua.TenNguoiBaoSua }}</span>
										</div>
										<div class="d-flex align-center mt-0">
											<!-- <v-icon size="small" color="grey" class="mr-1">mdi-clock-outline</v-icon> -->

											<span style="margin-top: -3px; font-size: 11px;">{{
												thongTinBaoSua.NgayBaoSua
												}}</span>
										</div>
									</v-col>
									<v-col cols="5" class="d-flex justify-end">
										<v-chip
											:color="statusToColor(thongTinBaoSua.MaTinhTrang)">{{ thongTinBaoSua.TenTinhTrang }}
										</v-chip>
									</v-col>
								</v-row>
							</v-col>
						</v-row>


						<!-- <v-divider></v-divider> -->
						<v-row class="py-1 mt-0">
							<!-- <v-col cols="3">Tài sản: </v-col> -->
							<v-col cols="12" class="d-flex">
								<v-icon class="mr-3" color="#1976D2">mdi-devices</v-icon>
								<!-- <uc-asset-info :macabiet="thongTinBaoSua.MaCaBiet" :tentaisan="thongTinBaoSua.TenTaiSan"
									classforname="text-subtitle-2"></uc-asset-info> -->
							</v-col>
						</v-row>
						<v-divider></v-divider>
						<v-row class="py-1">
							<!-- <v-col cols="3">Vị trí: </v-col> -->
							<v-col cols="12">
								<v-icon class="mr-2" color="#E53935">mdi-map-marker-radius-outline</v-icon>
								<span class="text-body-2">{{ thongTinBaoSua.TenViTriPhong }}</span>
							</v-col>
						</v-row>
						<v-divider></v-divider>
						<v-row class="py-1">
							<!-- <v-col cols="3">Ghi chú: </v-col> -->
							<v-col cols="12">
								<v-icon class="mr-2" color="#9E9E9E">mdi-message-text-outline</v-icon>
								<span class="text-body-2 mr-2">{{ thongTinBaoSua.GhiChu }}</span>
								<v-btn density="compact" v-if="thongTinBaoSua.HinhAnh" @click="getHinhAnh()"
									variant="text" color="blue-darken-2" icon="mdi-image-outline"></v-btn>
							</v-col>
						</v-row>
					</div>


					<v-expansion-panels variant="accordion" class="d-flex" v-model="panel" multiple>

						<!-- Tiếp nhận -->
						<v-expansion-panel :value="1">
							<v-expansion-panel-title min-height="40px" class="py-0 bg-blue-grey-lighten-5">
								<v-icon color="warning">mdi-numeric-1-circle-outline</v-icon>
								<span class="mx-2 text-subtitle-1">Tiếp nhận</span>
								<template v-slot:actions="{ expanded }">
									<v-icon :color="thongTinBaoSua.MaTinhTrang >= 1 ? 'success' : '#9E9E9E'"
										:icon="thongTinBaoSua.MaTinhTrang >= 1 ? 'mdi-check' : 'mdi-pencil'"></v-icon>
								</template>
							</v-expansion-panel-title>
							<v-divider></v-divider>
							<v-expansion-panel-text>
								<div style="margin: 2px 0 0;" class="text-body-2">
									<v-row v-if="thongTinBaoSua.TiepNhan.CreateUser" class="d-flex align-center">
										<v-col cols="2" style="max-width: 30px">
											<v-avatar style="border: 1px solid #e0b44b " size="30" class="mr-2 ">
												<v-img
													:src="'https://file.lhbs.vn/me/avatarOrigin/' + thongTinBaoSua.TiepNhan.CreateUser + '.jpg'">
												</v-img>
											</v-avatar>
										</v-col>
										<v-col class="ml-1">
											<v-row>
												<v-col>
													<div class="d-flex align-center " style="">
														<span>{{ thongTinBaoSua.TiepNhan.TenNhanVienXuLy }}</span>
													</div>
													<div class="d-flex align-center mt-0">
														<span style="margin-top: -3px; font-size: 11px;">{{
															thongTinBaoSua.TiepNhan.CreateTime
														}}</span>
													</div>
												</v-col>
											</v-row>
										</v-col>
									</v-row>

									<v-row class="py-1 mt-0">
										<v-col>
											<v-textarea ref="txtGhiChuTiepNhan" :clearable="false" rows="2"
												dense="compact" v-model="ghiChuTiepNhan" label="Ghi chú tiếp nhận"
												@focus="scrollToField('txtGhiChuTiepNhan')">
											</v-textarea>
										</v-col>
									</v-row>
									<div v-if="editGhiChuTiepNhan || thongTinBaoSua.MaTinhTrang == 0" class="d-flex my-1">
										<v-btn block color="primary" variant="tonal" @click="tiepNhanBaoSua()">Tiếp
											nhận</v-btn>
									</div>
								</div>

							</v-expansion-panel-text>
						</v-expansion-panel>

						<!-- Kiểm tra -->
						<v-expansion-panel v-if="thongTinBaoSua.MaTinhTrang != 6" :value="2">
							<v-expansion-panel-title min-height="40px" class="py-1 bg-blue-grey-lighten-5">
								<v-icon color="teal">mdi-numeric-2-circle-outline</v-icon>
								<span class="mx-2 text-subtitle-1">Kiểm tra</span>
								<template v-slot:actions="{ expanded }">
									<v-icon :color="thongTinBaoSua.MaTinhTrang >= 2 ? 'success' : '#9E9E9E'"
										:icon="thongTinBaoSua.MaTinhTrang >= 2 ? 'mdi-check' : 'mdi-pencil'"></v-icon>
								</template>
							</v-expansion-panel-title>
							<v-divider></v-divider>
							<v-expansion-panel-text class="text-body-2">
								<v-row v-if="thongTinBaoSua.KiemTra.CreateUser" class="d-flex align-center">
									<v-col cols="2" style="max-width: 30px">
										<v-avatar style="border: 1px solid #e0b44b " size="30" class="mr-2 ">
											<v-img
												:src="'https://file.lhbs.vn/me/avatarOrigin/' + thongTinBaoSua.KiemTra.CreateUser + '.jpg'">
											</v-img>
										</v-avatar>
									</v-col>
									<v-col class="ml-1">
										<v-row>
											<v-col>
												<div class="d-flex align-center " style="">
													<span>{{ thongTinBaoSua.KiemTra.TenNhanVienXuLy }}</span>
												</div>
												<div class="d-flex align-center mt-0">
													<span style="margin-top: -3px; font-size: 11px;">{{
														thongTinBaoSua.KiemTra.CreateTime
													}}</span>
												</div>
											</v-col>
										</v-row>
									</v-col>
								</v-row>
								<v-row style="margin-top: 0px">
									<v-col class="mt-0 text-grey-darken-1" cols="12"
										style="display: flex; align-items: center;">
										<span class="mr-2"><b>Xác nhận: </b></span>
										<v-chip-group class="mr-2" v-model="baoSuaSai">
											<v-chip prepend-icon="mdi-check" size="small" :value="0" color="primary">Báo
												đúng</v-chip>
											<v-chip prepend-icon="mdi-close-box" size="small" :value="1"
												color="error">Báo
												sai</v-chip>
										</v-chip-group>
									</v-col>
								</v-row>

								<v-row class="pt-0">
									<v-col class="pt-0">
										<v-textarea rows="2" :clearable="false" v-else class="" density="compact"
											v-model="ghiChuKiemTra" label="Ghi chú kiểm tra" ref="txtGhiChuKiemTra"
											@focus="scrollToField('txtGhiChuKiemTra')">
										</v-textarea>
									</v-col>
								</v-row>

								<v-btn block color="primary" class="mr-3 mt-2 mb-1" variant="tonal"
									:disabled="baoSuaSai == null || !ghiChuKiemTra.trim()"
									@click="updateKiemTraBaoSua()">Lưu
								</v-btn>

							</v-expansion-panel-text>
						</v-expansion-panel>

						<v-expansion-panel v-else :value="2">
							<v-expansion-panel-title min-height="40px" class="py-1 bg-blue-grey-lighten-5">
								<v-icon color="teal">mdi-numeric-2-circle-outline</v-icon>
								<span class="mx-2 text-subtitle-1">Kiểm tra</span>
								<template v-slot:actions="{ expanded }">
									<v-icon :color="thongTinBaoSua.MaTinhTrang >= 2 ? 'success' : '#9E9E9E'"
										:icon="thongTinBaoSua.MaTinhTrang >= 2 ? 'mdi-check' : 'mdi-pencil'"></v-icon>
								</template>
							</v-expansion-panel-title>
							<v-divider></v-divider>
							<v-expansion-panel-text class="text-body-2">
								<v-row v-if="thongTinBaoSua.BaoSai.CreateUser" class="d-flex align-center">
									<v-col cols="2" style="max-width: 30px">
										<v-avatar style="border: 1px solid #e0b44b " size="30" class="mr-2 ">
											<v-img
												:src="'https://file.lhbs.vn/me/avatarOrigin/' + thongTinBaoSua.BaoSai.CreateUser + '.jpg'">
											</v-img>
										</v-avatar>
									</v-col>
									<v-col class="ml-1">
										<v-row>
											<v-col>
												<div class="d-flex align-center " style="">
													<span>{{ thongTinBaoSua.BaoSai.TenNhanVienXuLy }}</span>
												</div>
												<div class="d-flex align-center mt-0">
													<span style="margin-top: -3px; font-size: 11px;">{{
														thongTinBaoSua.BaoSai.CreateTime
													}}</span>
												</div>
											</v-col>
										</v-row>
									</v-col>
								</v-row>
								<v-row class="mt-0">
									<v-col class="text-grey-darken-1" cols="12"
										style="display: flex; align-items: center;">
										<span class="mr-2"><b>Xác nhận: </b></span>
										<v-chip-group class="mr-2" v-model="baoSuaSai">
											<v-chip prepend-icon="mdi-check" size="small" :value="0" color="primary">Báo
												đúng</v-chip>
											<v-chip prepend-icon="mdi-close-box" size="small" :value="1"
												color="error">Báo
												sai</v-chip>
										</v-chip-group>
									</v-col>
								</v-row>

								<v-row class="pt-0">
									<v-col class="pt-0">
										<v-textarea rows="2" :clearable="false" class="" density="compact"
											v-model="ghiChuKiemTra" label="Ghi chú kiểm tra" ref="txtGhiChuKiemTraSai"
											@focus="scrollToField('txtGhiChuKiemTraSai')">
										</v-textarea>
									</v-col>
								</v-row>

								<v-btn block color="primary" class="mr-3 mb-1 mt-2" variant="tonal"
									:disabled="baoSuaSai == null || !ghiChuKiemTra.trim()"
									@click="updateKiemTraBaoSua()">Lưu
								</v-btn>

							</v-expansion-panel-text>
						</v-expansion-panel>

						<!-- Sửa chữa-->
						<v-expansion-panel v-if="thongTinBaoSua.MaTinhTrang < 6" :value="3">
							<v-expansion-panel-title min-height="40px" class="bg-blue-grey-lighten-5 py-1">
								<v-icon color="success">mdi-numeric-3-circle-outline</v-icon>
								<span class="mx-2 text-subtitle-1 ">Sửa chữa</span>
								<template v-slot:actions="{ expanded }">
									<v-icon v-if="thongTinBaoSua.MaTinhTrang == 3"
										:color="thongTinBaoSua.MaTinhTrang == 3 ? 'warning' : '#9E9E9E'"
										:icon="thongTinBaoSua.MaTinhTrang == 3 ? 'mdi-cog-outline' : 'mdi-pencil'"></v-icon>
									<v-icon v-else :color="thongTinBaoSua.MaTinhTrang > 3 ? 'success' : '#9E9E9E'"
										:icon="thongTinBaoSua.MaTinhTrang > 3 ? 'mdi-check' : 'mdi-pencil'"></v-icon>
								</template>
							</v-expansion-panel-title>
							<v-divider></v-divider>
							<v-expansion-panel-text class="text-body-2">
								<v-row v-if="nguoiSua" class="d-flex align-center">
									<v-col cols="2" style="max-width: 30px">
										<v-avatar style="border: 1px solid #e0b44b " size="30" class="mr-2 ">
											<v-img :src="'https://file.lhbs.vn/me/avatarOrigin/' + nguoiSua + '.jpg'">
											</v-img>
										</v-avatar>
									</v-col>
									<v-col class="ml-1">
										<v-row>
											<v-col>
												<div class="d-flex align-center " style="">
													<span>{{ tenNguoiSua }}</span>
												</div>
												<div class="d-flex align-center mt-0">
													<span style="margin-top: -3px; font-size: 11px;">{{
														thoiGianSua
													}}</span>
												</div>
											</v-col>
										</v-row>
									</v-col>
								</v-row>
								<v-form ref="formSua">
									<v-row class="pb-0 mb-0">
										<v-col class="d-md-flex align-center pb-0">
											<div class="text-body-2 mr-2">Tình trạng sửa * :</div>
											<v-chip-group required :rules="[v => !!v || 'Chọn tình trạng']"
												v-model="tinhTrangSua">
												<v-chip size="small" prepend-icon="mdi-cog-outline" color="warning"
													:value="3">Đang
													sửa
												</v-chip>
												<v-chip size="small" prepend-icon="mdi-check" color="success"
													:value="4">Sửa
													xong</v-chip>
												<v-chip size="small" prepend-icon="mdi-cog-off" color="error"
													:value="5">Không
													sửa được</v-chip>
											</v-chip-group>
										</v-col>
									</v-row>

									<v-row class="mt-0">
										<v-col>
											<v-textarea :clearable="false" rows="2" required
												:rules="[v => !!v || 'Nhập ghi chú sửa']" class="" density="compact"
												v-model="ghiChuSua" label="Ghi chú sửa *" ref="txtGhiChuSua"
												@focus="scrollToField('txtGhiChuSua')">
											</v-textarea>
										</v-col>
									</v-row>
									<!-- <div v-if="tinhTrangSua == 4 || tinhTrangSua==3"> -->
									<div>
										<v-row class="py-1">

											<v-col>
												<!-- <v-text-field density="compact" v-model="formatNumber" :clearable="false"
																@keypress="onlyNumberInput" type="number" /> -->
												<uc-money ref="txtChiPhi" @focus="scrollToField('txtChiPhi')"
													label="Chi phí sửa" v-model="chiPhiSua">
													</v-money>
											</v-col>
										</v-row>

										<v-row class="mt-0">
											<v-col>
												<v-card>
													<v-row class="py-2 px-3">
														<v-col class="text-grey-darken-1" cols="8"
															style="display: flex; align-items: center;"><b>Tài
																sản thay thế, thêm mới: </b></v-col>
														<v-col>
															<v-col class="d-flex justify-end ma-0  pa-0">
																<v-btn class="mr-1" outlined density="compact"
																	color="primary" icon="mdi-plus" variant="tonal"
																	@click="isShowThemTaiSanThayThe = true">
																</v-btn>
															</v-col>
													</v-row>

													<v-data-table :items="thongTinBaoSua.TaiSanThayThe"
														item-value="MaCaBietMoi" :headers="headerTaiSanThayThe"
														hide-default-footer hide-default-header>
														<template v-slot:item.TenTaiSan="{ item }">
															<!-- <uc-asset-info class="my-2" :tentaisan="item.TenTaiSan"
																:macabiet="item.MaCaBietMoi"></uc-asset-info> -->
														</template>
														<template v-slot:item.Xoa="{ item }">
															<v-btn color="red" density="compact"
																@click="deleteTaiSanThayThe(item.ID)" icon
																variant="text">
																<v-icon>mdi-delete</v-icon>
															</v-btn>
														</template>
													</v-data-table>
												</v-card>
											</v-col>
										</v-row>
									</div>

									<v-btn block color="primary" class="mr-3 mt-2" variant="tonal"
										@click="validate('formSua', updateSuaChua)"
										:disabled="![3, 4, 5].includes(tinhTrangSua) || !ghiChuSua.trim()">
										Lưu</v-btn>

								</v-form>
							</v-expansion-panel-text>
						</v-expansion-panel>

					</v-expansion-panels>
				</v-sheet>
			</v-card-text>
		</v-card>



	</v-dialog>


	<v-dialog v-model="isShowHinhAnh" max-width="500px">
		<v-card>
			<v-toolbar density="compact">
				<v-toolbar-title>Hình ảnh</v-toolbar-title>

				<v-btn variant="text" icon="mdi-close" @click="isShowHinhAnh = false"></v-btn>
			</v-toolbar>

			<v-divider></v-divider>
			<v-card-text class="text-center">
				<v-img v-if="hinhDinhKem" :src="`data:image/png;base64,` + hinhDinhKem" contain></v-img>
				<div v-else class="text-grey">Không có hình ảnh</div>
			</v-card-text>

		</v-card>
	</v-dialog>

	<v-dialog v-model="isShowThemTaiSanThayThe" max-width="500px">
		<v-card>
			<v-form ref="formThayTheTaiSan">


				<v-toolbar density="compact">
					<v-toolbar-title>Chọn tài sản thay thế, thêm mới</v-toolbar-title>

					<v-btn variant="text" icon="mdi-close" @click="isShowThemTaiSanThayThe = false"></v-btn>
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

	<uc-confirm ref="confirm"></uc-confirm>
</template>

<script>
export default {
	props: {
		// MaBaoSua: {
		// 	type: String,
		// 	required: true,
		// 	default: ''
		// }
	},
	data() {
		return {
			MaBaoSua: null,
			isOpen: false,
			panel: [],
			currentStep: 0,
			hinhDinhKem: null,
			isShowHinhAnh: false,
			isShowThemTaiSanThayThe: false,
			isLoading: false,
			thongTinBaoSua: {},
			editGhiChuTiepNhan: false,
			editKiemTra: false,
			ghiChuTiepNhan: "",
			ghiChuKiemTra: "",
			ghiChuSua: "",
			chiPhiSua: null,
			displayValue: "",
			baoSuaSai: null,
			maTaiSanHu: null,
			tenTaiSanHu: null,
			thoiGianSua: "",
			nguoiSua: "",
			tenNguoiSua: "",
			tinhTrangSua: null,
			dsTaiSanTrongPhongBan: [],
			taiSanThayTheDangChon: null,
			headerTaiSanThayThe: [
				{ title: "Tên tài sản", value: "TenTaiSan" },
				{ title: "Xóa", align: "end", value: "Xoa" },
			]

		}
	},
	mounted() {
		// this.getBaoSua();
	},
	computed: {
		formatchiPhi: {
			get() {
				if (this.chiPhiSua === null || this.chiPhiSua === '') return '';
				const value = Number(this.chiPhiSua);
				if (isNaN(value)) return '';
				return value.toLocaleString('vi-VN') + ' đ';
			},
			set(newValue) {
				const cleanedValue = newValue.replace(/[^0-9]/g, '');
				this.chiPhiSua = cleanedValue ? Number(cleanedValue) : null;
			}
		}
	},
	watch: {
		isShowThemTaiSanThayThe() {
			if (this.isShowThemTaiSanThayThe) {
				this.getTaiSanTrongPhongBan()
			}
		}
	},
	methods: {
		open(MaBaoSua) {
			this.isOpen = true;
			this.MaBaoSua = MaBaoSua;
			this.getBaoSua();
		},
		close() {
			this.isOpen = false;
			this.$emit("close");
		},
		update() {
			this.$emit("update");
		},

		async getBaoSua() {
			try {
				if (!this.MaBaoSua) return;
				this.isLoading = true;
				this.panel = [];

				const res = await axios.post("obj/TS_BaoSua_SelectByMaBaoSua", {
					MaBaoSua: this.MaBaoSua
				});

				this.thongTinBaoSua = res.data.data;

				this.thongTinBaoSua.TiepNhan = this.thongTinBaoSua.TiepNhan?.trim()
					? JSON.parse(this.thongTinBaoSua.TiepNhan)[0]
					: {};
				this.thongTinBaoSua.KiemTra = this.thongTinBaoSua.KiemTra?.trim()
					? JSON.parse(this.thongTinBaoSua.KiemTra)[0]
					: {};
				this.thongTinBaoSua.DangSua = this.thongTinBaoSua.DangSua?.trim()
					? JSON.parse(this.thongTinBaoSua.DangSua)[0]
					: {};
				this.thongTinBaoSua.DaXong = this.thongTinBaoSua.DaXong?.trim()
					? JSON.parse(this.thongTinBaoSua.DaXong)[0]
					: {};
				this.thongTinBaoSua.Hu = this.thongTinBaoSua.Hu?.trim()
					? JSON.parse(this.thongTinBaoSua.Hu)[0]
					: {};

				this.thongTinBaoSua.BaoSai = this.thongTinBaoSua.BaoSai?.trim()
					? JSON.parse(this.thongTinBaoSua.BaoSai)[0]
					: {};

				this.thongTinBaoSua.TaiSanThayThe = this.thongTinBaoSua.TaiSanThayThe?.trim()
					? JSON.parse(this.thongTinBaoSua.TaiSanThayThe)
					: [];


				if (this.thongTinBaoSua.MaTinhTrang == 6) {
					this.baoSuaSai = 1;
					this.ghiChuKiemTra = this.thongTinBaoSua.BaoSai.GhiChu || "";
				} else {
					if (this.thongTinBaoSua.KiemTra.TenNhanVienXuLy) {
						this.baoSuaSai = 0;
						this.ghiChuKiemTra = this.thongTinBaoSua.KiemTra.GhiChu || "";
					}

				}

				this.ghiChuTiepNhan = this.thongTinBaoSua.TiepNhan?.GhiChu || "";

				if (this.thongTinBaoSua.MaTinhTrang > 2) {
					this.tinhTrangSua = this.thongTinBaoSua.MaTinhTrang

				}

				switch (this.thongTinBaoSua.MaTinhTrang) {
					case 3:
						this.tinhTrangSua = 3;
						this.ghiChuSua = this.thongTinBaoSua.DangSua.GhiChu || "";
						this.nguoiSua = this.thongTinBaoSua.DangSua.CreateUser;
						this.tenNguoiSua = this.thongTinBaoSua.DangSua.TenNhanVienXuLy;
						this.thoiGianSua = this.thongTinBaoSua.DangSua.CreateTime;
						break;
					case 4:
						this.tinhTrangSua = 4
						this.ghiChuSua = this.thongTinBaoSua.DaXong.GhiChu || "";
						this.nguoiSua = this.thongTinBaoSua.DaXong.CreateUser;
						this.tenNguoiSua = this.thongTinBaoSua.DaXong.TenNhanVienXuLy;
						this.thoiGianSua = this.thongTinBaoSua.DaXong.CreateTime;
						break;
					case 5:
						this.tinhTrangSua = 5
						this.ghiChuSua = this.thongTinBaoSua.Hu.GhiChu || "";
						this.nguoiSua = this.thongTinBaoSua.Hu.CreateUser;
						this.tenNguoiSua = this.thongTinBaoSua.Hu.TenNhanVienXuLy;
						this.thoiGianSua = this.thongTinBaoSua.Hu.CreateTime;
						break;
					default:
						break;
				}
				this.chiPhiSua = this.thongTinBaoSua.ChiPhi || 0;
				this.displayValue = this.chiPhiSua.toLocaleString('vi-VN');

				this.currentStep = this.thongTinBaoSua.MaTinhTrang + 1
				// this.panel.push(0);
				this.panel.push(this.currentStep);


			} catch (error) {

				const message = error?.response?.data?.Message || "Lỗi lấy thông tin báo sửa";
				showMessage({ type: "red", title: message });
			} finally {
				this.isLoading = false;
			}
		},

		async getHinhAnh() {
			try {

				const kq = await axios.post("obj/TS_BaoSua_SelectHinhAnh", {
					MaBaoSua: this.MaBaoSua
				});

				this.hinhDinhKem = kq.data.data.HinhAnh
				this.isShowHinhAnh = true;
			} catch (error) {
				showMessage({ type: "red", title: error.response?.data?.Message || "Lỗi khi tải hình ảnh" });
			}
		},

		async tiepNhanBaoSua() {
			try {
				const confirmed = await this.$refs.confirm.open(
					{
						title: 'Xác nhận',
						message: 'Bạn có muốn tiếp nhận?',
						okText: 'Tiếp nhận',
						cancelText: 'Hủy',
						okColor: 'primary',
						cancelColor: 'blue-grey'
					}
				);
				if (!confirmed) return;
				await axios.post("TS_BaoSua_TiepNhan", {
					MaBaoSua: this.MaBaoSua,
					GhiChu: String(this.ghiChuTiepNhan).trim(),

				});

				this.getBaoSua();
				this.currentStep = 2;
				this.panel = [];
				this.panel.push(this.currentStep);

				this.update();

			} catch (error) {
				showMessage({ type: "red", title: error.response?.data?.Message || "Lỗi xử lý tiếp nhận" });
			}
		},

		async updateKiemTraBaoSua() {
			try {
				const confirmed = await this.$refs.confirm.open(
					{
						title: 'Xác nhận',
						message: 'Bạn có muốn lưu thông tin kiểm tra?',
						okText: 'Lưu',
						cancelText: 'Hủy',
						okColor: 'primary',
						cancelColor: 'blue-grey'
					}
				);
				if (!confirmed) return;
				await axios.post("TS_BaoSua_KiemTra", {
					MaBaoSua: this.MaBaoSua,
					GhiChu: String(this.ghiChuKiemTra).trim(),
					BaoSuaSai: this.baoSuaSai
				});

				this.getBaoSua();
				this.currentStep = 3;
				this.panel = [];
				this.panel.push(this.currentStep);

				this.update();
			} catch (error) {
				showMessage({ type: "red", title: error.response?.data?.Message || "Lỗi xử lý kiểm tra" });
			}
		},

		async updateSuaChua() {
			try {
				await axios.post("TS_BaoSua_SuaChua", {
					MaBaoSua: this.MaBaoSua,
					GhiChu: String(this.ghiChuSua).trim(),
					TinhTrangSua: this.tinhTrangSua,
					ChiPhi: this.chiPhiSua
				});

				this.getBaoSua();
				this.panel = [];

				this.update();
			} catch (error) {
				showMessage({ type: "red", title: error.response?.data?.Message || "Lỗi cập nhật sửa tài sản" });
			}
		},

		async getTaiSanTrongPhongBan() {
			try {
				const resp = await axios.post('/TS_TaiSan_SelectByViTriPhong_MaCaBiet', {
					MaCaBietCha: this.thongTinBaoSua.MaCaBiet,
				})
				this.dsTaiSanTrongPhongBan = resp.data.data
			} catch (error) {
				showMessage({
					type: 'red',
					title: error.response?.data?.Message || 'Lỗi khi lấy danh sách tài sản',
				})
			}
		},

		async insertTaiSanThayThe() {
			try {

				await axios.post("TS_TaiSanThayThe_Insert", {
					MaBaoSua: this.MaBaoSua,
					MaCaBiet: this.thongTinBaoSua.MaCaBiet,
					MaCaBietMoi: this.taiSanThayTheDangChon,
				});
				CALL({ "MESS": "Cập nhật thành công" })
				this.getBaoSua();
				this.isShowThemTaiSanThayThe = false;

			} catch (error) {
				showMessage({ type: "red", title: error.response?.data?.Message || "Lỗi thêm tài sản thay thế" });
			}
		},

		async deleteTaiSanThayThe(ID) {
			try {
				const confirmed = await this.$refs.confirm.open(
					{
						title: 'Xác nhận',
						message: 'Bạn có muốn xóa?',
						okText: 'Xóa',
						cancelText: 'Hủy',
						okColor: 'red',
						cancelColor: 'blue-grey'
					}
				);
				if (!confirmed) return;
				await axios.post("TS_TaiSanThayThe_Delete", {
					ID: ID,
					MaCaBiet: this.thongTinBaoSua.MaCaBiet
				});
				CALL({ "MESS": "Cập nhật thành công" })
				this.getBaoSua();
				this.isShowThemTaiSanThayThe = false;

			} catch (error) {
				showMessage({ type: "red", title: error.response?.data?.Message || "Lỗi thêm tài sản thay thế" });
			}
		},

		async validate(refName, callback, confirmText = "Bạn có muốn lưu dữ liệu?", reset = true) {
			const form = this.$refs[refName];
			console.log(`có`)
			if (!form) {
				console.warn(`Form ref "${refName}" not found.`);
				return;
			}

			const { valid } = await form.validate();



			if (valid && typeof callback === "function") {
				console.log(`qua`)
				const confirmed = await this.$refs.confirm.open(confirmText);
				if (!confirmed) return;
				await callback();
				if (reset) form.reset();
			}
		},

		onlyNumberInput(e) {
			const charCode = e.key.charCodeAt(0);
			// Chỉ cho nhập 0-9
			if (charCode < 48 || charCode > 57) {
				e.preventDefault();
			}
		},
		scrollToField(refName) {
			// this.$nextTick(() => {
			// 	const el = this.$refs[refName]?.$el;
			// 	if (el) {
			// 		el.scrollIntoView({ behavior: 'smooth', block: 'center' });
			// 	}
			// });
			setTimeout(() => {
				const el = this.$refs[refName]?.$el || this.$refs[refName];
				if (el) {
					el.scrollIntoView({ behavior: 'smooth', block: 'center' });
				}
			}, 200);
		},

		statusToColor(id) {
			switch (id) {
				case 0:
					return 'error';
					break;
				case 1:
					return 'deep-orange';
					break;
				case 2:
					return 'primary';
					break;
				case 3:
					return 'warning';
					break;
				case 4:
					return 'success';
					break;
				case 5:
					return 'error';
					break;
				case 6:
					return 'error';
					break;

				default:
					return 'green';
					break;
			}
		}
	},
}

</script>