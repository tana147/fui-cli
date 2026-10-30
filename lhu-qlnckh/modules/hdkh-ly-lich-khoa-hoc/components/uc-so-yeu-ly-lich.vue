<template>
	<uc-llkh-muc title="I. Sơ lược lý lịch" nguon="HRM" anchor="coban-I"
		:actions="[{ label: 'Cập nhật', icon: 'mdi-pencil', disabled: true, tooltip: 'Do Phòng TCNS quản lý' }, { label: 'Lịch sử', icon: 'mdi-history', disabled: true, tooltip: 'Do Phòng TCNS quản lý' }]">
		<v-row>
			<v-col cols="12" sm="3" md="2" class="d-flex flex-column align-center">
				<v-avatar size="128" rounded="lg" color="grey-lighten-3">
					<v-img v-if="d.nt.ImgURL" :src="d.nt.ImgURL" cover>
						<template v-slot:error>
							<v-icon size="64" color="grey">mdi-account</v-icon>
						</template>
					</v-img>
				</v-avatar>
				<div class="text-caption text-medium-emphasis mt-1">Ảnh hồ sơ nhân sự</div>
			</v-col>
			<v-col cols="12" sm="9" md="10">
				<div class="text-subtitle-2 text-medium-emphasis mb-1">Nhân thân</div>
				<uc-llkh-info :items="nhanThan"></uc-llkh-info>
				<v-divider class="my-3"></v-divider>
				<div class="text-subtitle-2 text-medium-emphasis mb-1">Liên hệ, công tác</div>
				<uc-llkh-info :items="lienHe"></uc-llkh-info>
				<v-divider class="my-3"></v-divider>
				<div class="d-flex align-center justify-space-between mb-1">
					<div class="text-subtitle-2 text-medium-emphasis">Thông tin khoa học (theo STM)</div>
					<v-btn size="x-small" variant="text" prepend-icon="mdi-pencil" color="primary" @click="moSuaSTM">Cập nhật</v-btn>
				</div>
				<uc-llkh-info :items="khoaHoc"></uc-llkh-info>
			</v-col>
		</v-row>

		<!-- Dialog cập nhật thông tin khoa học (theo STM) -->
		<v-dialog v-model="dialogSTM" max-width="600px" persistent>
			<v-card>
				<v-card-title class="d-flex align-center text-subtitle-1 font-weight-bold">
					<v-icon color="primary" class="mr-2">mdi-school-outline</v-icon>
					Cập nhật thông tin khoa học (theo STM)
					<v-spacer></v-spacer>
					<v-btn icon="mdi-close" variant="text" size="small" @click="dialogSTM = false"></v-btn>
				</v-card-title>
				<v-divider></v-divider>
				<v-card-text class="pt-4">
					<v-row dense>
						<v-col cols="12">
							<v-textarea v-model="formSTM.TomTatKinhNghiem" label="Tóm tắt kinh nghiệm chuyên môn (tối đa 100 từ)"
								rows="3" auto-grow variant="outlined" density="compact" counter="1000" hide-details="auto"></v-textarea>
						</v-col>
						<v-col cols="12" sm="6">
							<v-text-field v-model="formSTM.ORCID" label="ORCID" placeholder="0000-0000-0000-0000"
								variant="outlined" density="compact" hide-details="auto"></v-text-field>
						</v-col>
						<v-col cols="12" sm="6">
							<v-text-field v-model="formSTM.MaSTI" label="Mã LLKH STI"
								variant="outlined" density="compact" hide-details="auto"></v-text-field>
						</v-col>
						<v-col cols="12">
							<v-text-field v-model="formSTM.GoogleScholar" label="Google Scholar" placeholder="Link hoặc ID hồ sơ Google Scholar"
								variant="outlined" density="compact" hide-details="auto"></v-text-field>
						</v-col>
						<v-col cols="12">
							<v-text-field v-model="formSTM.ResearchGate" label="ResearchGate" placeholder="Link hoặc tên tài khoản ResearchGate"
								variant="outlined" density="compact" hide-details="auto"></v-text-field>
						</v-col>
					</v-row>
				</v-card-text>
				<v-divider></v-divider>
				<v-card-actions class="px-4 py-2">
					<v-spacer></v-spacer>
					<v-btn variant="text" @click="dialogSTM = false">Đóng</v-btn>
					<v-btn color="primary" variant="flat" prepend-icon="mdi-content-save" :loading="savingSTM" @click="luuSTM">Lưu</v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>
	</uc-llkh-muc>
</template>

<script>
	export default {
		props: {
			d: { type: Object, default: function () { return { nt: {}, daoTao: [], hocHam: [] } } }
		},
		data: function () {
			return {
				dialogSTM: false,
				savingSTM: false,
				formSTM: {
					TomTatKinhNghiem: "",
					ORCID: "",
					GoogleScholar: "",
					ResearchGate: "",
					MaSTI: ""
				}
			}
		},
		computed: {
			nhanThan: function () {
				var nt = this.d.nt, L = window.LLKH, khoa = "Do Phòng TCNS quản lý"
				return [
					{ label: "Họ và tên", value: nt.HoTen, lock: khoa },
					{ label: "Giới tính", value: nt.GioiTinh, lock: khoa, cols: 2 },
					{ label: "Ngày sinh", value: L.dmy(nt.NgaySinh), lock: khoa, cols: 2 },
					{ label: "Quốc tịch", value: nt.QuocTich, cols: 2 },
					{ label: "Dân tộc", value: nt.DanToc, cols: 2 },
					{ label: "Số CCCD", value: nt.CCCD },
					{ label: "Ngày cấp", value: L.dmy(nt.NgayCapCCCD), cols: 2 },
					{ label: "Nơi cấp", value: nt.NoiCapCCCD, cols: 2 },
					{ label: "Tôn giáo", value: nt.TonGiao, cols: 2 },
					{ label: "Tình trạng hôn nhân", value: nt.HonNhan, cols: 2 },
					{ label: "Nơi sinh", value: nt.NoiSinh },
					{ label: "Quê quán", value: nt.QueQuan },
					{ label: "Tình trạng sức khỏe", value: null, ns: true, why: L.LY_DO.noStore },
					{ label: "Địa chỉ thường trú", value: nt.ThuongTru, cols: 6 },
					{ label: "Địa chỉ tạm trú", value: nt.TamTru, cols: 6 },
					{ label: "Giấy phép lao động (người nước ngoài)", value: nt.GiayPhepLaoDong ? nt.GiayPhepLaoDong + " (" + L.dmy(nt.NgayCapGPLD) + " – " + L.dmy(nt.NgayHetHanGPLD) + ")" : (nt.QuocTich === "Việt Nam" ? "Không áp dụng" : null), cols: 6 }
				]
			},
			lienHe: function () {
				var nt = this.d.nt, L = window.LLKH, khoa = "Do Phòng TCNS quản lý"
				return [
					{ label: "Điện thoại di động", value: nt.DienThoai },
					{ label: "Email", value: nt.Email },
					{ label: "Điện thoại văn phòng (đơn vị)", value: nt.DienThoaiVP, lock: khoa },
					{ label: "Chức vụ, đơn vị công tác", value: nt.ChucVuPhongBan, lock: khoa, cols: 6 },
					{ label: "Ngày vào làm việc tại LHU", value: L.dmy(nt.NgayLamViec), lock: khoa },
					{ label: "Năm bắt đầu giảng dạy ĐH/ThS", value: null, ns: true, why: L.LY_DO.hrmMigrating },
					{ label: "Học vị cao nhất (từ mục II)", value: L.F.hocVi.get(this.d), lock: "Lấy từ quá trình đào tạo" },
					{ label: "Học hàm, năm phong (từ mục II)", value: L.F.hocHam.get(this.d) || "Không có trong HRM", lock: "Lấy từ quá trình đào tạo", cols: 4 }
				]
			},
			khoaHoc: function () {
				var s = (this.d && this.d.stm) || {}
				return [
					{ label: "Tóm tắt kinh nghiệm chuyên môn (tối đa 100 từ)", value: s.tomTatKinhNghiem, cols: 12 },
					{ label: "ORCID", value: s.orcid, cols: 3 },
					{ label: "Google Scholar", value: s.googleScholar, cols: 3 },
					{ label: "ResearchGate", value: s.researchGate, cols: 3 },
					{ label: "Mã LLKH STI", value: s.maSTI, cols: 3 }
				]
			}
		},
		methods: {
			moSuaSTM: function () {
				var s = (this.d && this.d.stm) || {}
				this.formSTM = {
					TomTatKinhNghiem: s.tomTatKinhNghiem || "",
					ORCID: s.orcid || "",
					GoogleScholar: s.googleScholar || "",
					ResearchGate: s.researchGate || "",
					MaSTI: s.maSTI || ""
				}
				this.dialogSTM = true
			},
			luuSTM: function () {
				var self = this
				self.savingSTM = true
				ajaxCALL("/HDKH_LLKH_STM_Save", self.formSTM, function (res) {
					self.savingSTM = false
					self.dialogSTM = false
					Vue.$toast.success((res.data && res.data[0] && res.data[0].Message) || "Đã lưu thông tin khoa học (STM)", { position: "top" })
					self.$emit("reload")
				}, function (xhr) {
					self.savingSTM = false
					showMessage({ title: "Không lưu được", message: xhr.responseJSON ? xhr.responseJSON.Message : "", type: "red" })
				})
			}
		}
	}
</script>