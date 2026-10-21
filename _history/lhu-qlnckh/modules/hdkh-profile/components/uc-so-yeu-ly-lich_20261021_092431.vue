<template>
	<uc-llkh-muc title="I. Sơ lược lý lịch" nguon="HRM" anchor="coban-I"
		:actions="[{ label: 'Cập nhật', icon: 'mdi-pencil' }, { label: 'Lịch sử', icon: 'mdi-history' }]">
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
				<div class="text-subtitle-2 text-medium-emphasis mb-1">Thông tin khoa học (theo STM)</div>
				<uc-llkh-info :items="khoaHoc"></uc-llkh-info>
			</v-col>
		</v-row>
	</uc-llkh-muc>
</template>

<script>
	export default {
		props: {
			d: { type: Object, default: function () { return { nt: {}, daoTao: [], hocHam: [] } } }
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
					{ label: "Tình trạng sức khỏe", value: null, why: L.LY_DO.noStore },
					{ label: "Địa chỉ thường trú", value: nt.ThuongTru, cols: 6 },
					{ label: "Địa chỉ tạm trú", value: nt.TamTru, cols: 6 },
					{ label: "Giấy phép lao động (người nước ngoài)", value: nt.GiayPhepLaoDong ? nt.GiayPhepLaoDong + " (" + L.dmy(nt.NgayCapGPLD) + " – " + L.dmy(nt.NgayHetHanGPLD) + ")" : "Không áp dụng", cols: 6 }
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
					{ label: "Năm bắt đầu giảng dạy ĐH/ThS", value: null, why: L.LY_DO.hrmMigrating },
					{ label: "Học vị cao nhất (từ mục II)", value: L.F.hocVi.get(this.d), lock: "Lấy từ quá trình đào tạo" },
					{ label: "Học hàm, năm phong (từ mục II)", value: L.F.hocHam.get(this.d) || "Không có", lock: "Lấy từ quá trình đào tạo", cols: 4 }
				]
			},
			khoaHoc: function () {
				var why = window.LLKH.LY_DO.noStore
				return [
					{ label: "Tóm tắt kinh nghiệm chuyên môn (tối đa 100 từ)", value: null, why: why, cols: 12 },
					{ label: "ORCID", value: null, why: why, cols: 3 },
					{ label: "Google Scholar", value: null, why: why, cols: 3 },
					{ label: "ResearchGate", value: null, why: why, cols: 3 },
					{ label: "Mã LLKH STI", value: null, why: why, cols: 3 }
				]
			}
		}
	}
</script>