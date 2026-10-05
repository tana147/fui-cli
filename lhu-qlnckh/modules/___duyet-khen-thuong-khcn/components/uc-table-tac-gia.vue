<template>
	<div>
		<!-- Khung chọn công thức khen thưởng & Ghi chú giải thích -->
		<div class="mb-3 pa-3 formula-select-card">
			<div class="mb-2 d-flex align-center justify-space-between">
				<label class="text-subtitle-2 font-weight-bold primary--text d-flex align-center">
					<v-icon small color="primary" class="mr-1">mdi-scale-balance</v-icon>
					Chọn công thức khen thưởng theo quy chế:
				</label>
				<span class="text-caption grey--text text--darken-1 font-weight-medium" v-if="currentCongThuc && currentCongThuc.DieuKhoanApDung">
					<v-icon x-small color="grey darken-1" class="mr-1">mdi-bookmark-outline</v-icon>
					{{ currentCongThuc.DieuKhoanApDung }}
				</span>
			</div>

			<v-row dense class="align-center">
				<v-col cols="12" md="8">
					<v-autocomplete v-model="selectedCongThucID"
						:items="dsCongThuc" item-text="TenCongThuc" item-value="CongThucID"
						label="Chọn khung khen thưởng áp dụng"
						placeholder="-- Gõ để tìm kiếm công thức theo số Điều hoặc tên giải --"
						outlined dense hide-details clearable
						@change="onSelectCongThuc"></v-autocomplete>
				</v-col>
				<v-col cols="12" md="4" class="d-flex align-center">
					<v-btn color="primary" elevation="0" block height="40" :disabled="!selectedCongThucID"
						:loading="isCalculating" @click="calculateReward">
						<v-icon left small>mdi-calculator</v-icon>Tính tiền thưởng tự động
					</v-btn>
				</v-col>
			</v-row>

			<!-- Mục ghi chú giải thích công thức -->
			<div v-if="currentCongThuc" class="mt-3 pa-2 formula-explain-box">
				<div class="d-flex align-start">
					<v-icon small color="primary" class="mr-2 mt-1">mdi-information-outline</v-icon>
					<div class="text-caption">
						<div class="font-weight-bold primary--text">
							Ghi chú giải thích công thức: {{ currentCongThuc.TenCongThuc }}
						</div>
						<div class="grey--text text--darken-3 mt-1" v-if="currentCongThuc.DieuKhoanApDung">
							<strong>Căn cứ quy chế:</strong> {{ currentCongThuc.DieuKhoanApDung }}
						</div>
						<div class="grey--text text--darken-3 mt-1" v-if="originalCongThuc">
							<strong>Đối chiếu mức gốc KH&CN:</strong> 
							Tác giả: {{ formatCurrency(originalCongThuc.MucThuong_NhomTacGia) }} &rarr; 2/3 là <strong>{{ formatCurrency(currentCongThuc.MucThuong_NhomTacGia) }}</strong>
							<span v-if="originalCongThuc.MucThuong_GVHD > 0">
								| GVHD: {{ formatCurrency(originalCongThuc.MucThuong_GVHD) }} &rarr; 2/3 là <strong>{{ formatCurrency(currentCongThuc.MucThuong_GVHD) }}</strong>
							</span>
						</div>
						<div class="grey--text text--darken-3 mt-1" v-if="currentCongThuc.GhiChu">
							<strong>Quy định phân bổ:</strong> {{ currentCongThuc.GhiChu }}
						</div>
					</div>
				</div>
			</div>
		</div>

		<!-- Thông tin mức thưởng theo khung đã chọn: Căn chỉnh đều, đẹp, cân đối -->
		<v-row dense class="mb-3" v-if="currentCongThuc">
			<v-col cols="12" sm="4">
				<v-card outlined class="rounded-xs pa-3 text-center fill-height d-flex flex-column justify-center reward-stat-card">
					<div class="text-caption grey--text text--darken-2 font-weight-medium">Khung nhóm tác giả</div>
					<div class="text-h6 font-weight-bold primary--text my-1">
						{{ formatCurrency(currentCongThuc.MucThuong_NhomTacGia) }}
					</div>
					<div class="text-caption grey--text text--darken-1 font-italic reward-stat-sub">
						<span v-if="originalCongThuc">(2/3 mức gốc: {{ formatCurrency(originalCongThuc.MucThuong_NhomTacGia) }})</span>
						<span v-else-if="currentCongThuc.DieuKhoanApDung">{{ currentCongThuc.DieuKhoanApDung }}</span>
					</div>
				</v-card>
			</v-col>
			<v-col cols="12" sm="4">
				<v-card outlined class="rounded-xs pa-3 text-center fill-height d-flex flex-column justify-center reward-stat-card">
					<div class="text-caption grey--text text--darken-2 font-weight-medium">Khung Giảng viên HD</div>
					<div class="text-h6 font-weight-bold primary--text my-1">
						{{ formatCurrency(currentCongThuc.MucThuong_GVHD) }}
					</div>
					<div class="text-caption grey--text text--darken-1 font-italic reward-stat-sub">
						<span v-if="originalCongThuc && originalCongThuc.MucThuong_GVHD > 0">(2/3 mức gốc: {{ formatCurrency(originalCongThuc.MucThuong_GVHD) }})</span>
						<span v-else-if="currentCongThuc.MucThuong_GVHD > 0">Thưởng GVHD theo quy chế</span>
						<span v-else>Không áp dụng GVHD</span>
					</div>
				</v-card>
			</v-col>
			<v-col cols="12" sm="4">
				<v-card outlined class="rounded-xs pa-3 text-center fill-height d-flex flex-column justify-center reward-stat-card">
					<div class="text-caption grey--text text--darken-2 font-weight-medium">Tổng tiền đề xuất</div>
					<div class="text-h6 font-weight-bold success--text my-1">
						{{ formatCurrency(computedTotalReward) }}
					</div>
					<div class="text-caption grey--text text--darken-1 font-italic reward-stat-sub">
						(Tổng tiền thực tế phân bổ)
					</div>
				</v-card>
			</v-col>
		</v-row>

		<!-- Thanh trạng thái tỷ lệ & nút chia đều, chuyển mode, thêm thành viên -->
		<div class="d-flex align-center justify-space-between flex-wrap mb-2 gap-2">
			<div class="d-flex align-center flex-wrap gap-2">
				<span class="text-subtitle-2 font-weight-bold primary--text">
					<v-icon small color="primary" class="mr-1">mdi-account-group</v-icon>
					Phân bổ tiền thưởng thành viên:
				</span>
				<v-chip x-small :color="authorTotalRate === 100 ? 'success' : 'error'" class="font-weight-medium" outlined>
					<v-icon left x-small>{{ authorTotalRate === 100 ? 'mdi-check' : 'mdi-alert' }}</v-icon>
					Tác giả: {{ authorTotalRate }}% / 100%
				</v-chip>
				<v-chip x-small v-if="hasMentor" :color="mentorTotalRate === 100 ? 'success' : 'error'" class="font-weight-medium" outlined>
					<v-icon left x-small>{{ mentorTotalRate === 100 ? 'mdi-check' : 'mdi-alert' }}</v-icon>
					GVHD: {{ mentorTotalRate }}% / 100%
				</v-chip>
			</div>
			<div class="d-flex align-center flex-wrap gap-2">
				<!-- Chuyển mode nhận tiền trực tiếp tại Tab 3 -->
				<div class="d-flex align-center grey lighten-4 px-2 py-1 rounded-sm border">
					<span class="text-caption font-weight-bold grey--text text--darken-2 mr-2">Hình thức:</span>
					<v-btn-toggle v-model="localHinhThucThanhToan" mandatory dense borderless color="primary" @change="onPaymentModeChange">
						<v-btn :value="1" x-small class="text-none font-weight-medium">
							<v-icon left x-small>mdi-account-multiple</v-icon>
							Từng cá nhân
						</v-btn>
						<v-btn :value="2" x-small class="text-none font-weight-medium">
							<v-icon left x-small>mdi-account-check</v-icon>
							Ủy quyền đại diện
						</v-btn>
					</v-btn-toggle>
				</div>

				<v-btn color="indigo darken-1" x-small outlined elevation="0" class="text-capitalize font-weight-medium"
					:disabled="membersList.length === 0" @click="chiaDeuTyLe">
					<v-icon left small>mdi-scale-balance</v-icon>Chia đều 100%
				</v-btn>
				<v-btn color="primary" x-small elevation="0" class="text-capitalize font-weight-medium"
					@click="openMemberDialog(null)">
					<v-icon left small>mdi-account-plus</v-icon>Thêm thành viên
				</v-btn>
			</div>
		</div>

		<!-- Banner thông báo khi ở chế độ ủy quyền -->
		<v-alert v-if="isDaiDienMode" type="info" text dense class="mb-2 rounded-xs font-weight-medium">
			<div class="d-flex align-center justify-space-between flex-wrap" style="gap: 8px;">
				<div>
					<v-icon left small color="info">mdi-information</v-icon>
					<strong>Chế độ ủy quyền nhận thay:</strong> Toàn bộ tiền thưởng của Nhóm tác giả sẽ được chuyển khoản cho <strong>{{ representativeName || 'người đại diện được chỉ định' }}</strong>.
				</div>
				<div class="caption font-italic grey--text text--darken-2">
					(Tích chọn ô "Đại diện" ở dòng thành viên tương ứng bên dưới để đổi người nhận)
				</div>
			</div>
		</v-alert>

		<!-- Bảng phân bổ thành viên -->
		<v-data-table dense :headers="headers" :items="membersList" hide-default-footer
			class="elevation-0 border rounded-xs" no-data-text="Không có thành viên nào trong danh sách">
			<template v-slot:item.STT="{ index }">
				{{ index + 1 }}
			</template>

			<template v-slot:item.Is_SinhVien="{ item }">
				<v-chip x-small :color="item.Is_SinhVien ? 'orange' : 'primary'" outlined>
					{{ item.Is_SinhVien ? 'Sinh viên' : 'Cán bộ / GV' }}
				</v-chip>
			</template>

			<template v-slot:item.VaiTro="{ item }">
				<span class="font-weight-medium">{{ getRoleName(item.VaiTro) }}</span>
			</template>

			<template v-slot:item.TyLeDongGop="{ item }">
				<v-text-field v-model.number="item.TyLeDongGop" type="number" min="0" max="100" dense outlined
					hide-details class="text-right" @change="onChangeTyLeDongGop"></v-text-field>
			</template>

			<template v-slot:item.SoTienThuong="{ item }">
				<uc-format-price-tac-gia v-model="item.SoTienThuong" :ct_khenthuongid="selectedCongThucID"
					readonly @input="recalculateTotals"></uc-format-price-tac-gia>
			</template>

			<template v-slot:item.Is_DaiDienNhanTien="{ item }">
				<div class="d-flex justify-center align-center">
					<v-checkbox v-model="item.Is_DaiDienNhanTien" dense hide-details class="mt-0 pt-0"
						@change="onToggleDaiDien(item)"></v-checkbox>
				</div>
			</template>

			<template v-slot:item.actions="{ item, index }">
				<div class="d-flex align-center justify-center">
					<v-btn icon x-small color="primary" class="mr-1" title="Chỉnh sửa thông tin thành viên"
						@click="openMemberDialog(item, index)">
						<v-icon small>mdi-pencil-outline</v-icon>
					</v-btn>
					<v-btn icon x-small color="error" title="Xóa thành viên"
						@click="deleteMember(index)">
						<v-icon small>mdi-trash-can-outline</v-icon>
					</v-btn>
				</div>
			</template>
		</v-data-table>

		<!-- Dialog Thêm / Sửa thành viên -->
		<v-dialog v-model="isModalOpen" max-width="700px" persistent>
			<v-card class="rounded-xs">
				<v-card-title class="pa-3 d-flex align-center justify-space-between primary white--text">
					<span class="text-subtitle-1 font-weight-bold">
						{{ editIndex === -1 ? 'Thêm thành viên nhận thưởng' : 'Chỉnh sửa thông tin thành viên' }}
					</span>
					<v-btn icon dark small @click="closeMemberDialog">
						<v-icon>mdi-close</v-icon>
					</v-btn>
				</v-card-title>

				<v-card-text class="pa-4">
					<v-form ref="memberForm" v-model="isFormValid" lazy-validation>
						<v-row dense class="compact-form-row">
							<!-- Chọn đối tượng -->
							<v-col cols="12" class="py-1 mb-1">
								<v-radio-group v-model="editItem.Is_SinhVien" row hide-details class="mt-0"
									@change="onTargetTypeChange">
									<v-radio label="Cán bộ / Giảng viên LHU" :value="false"></v-radio>
									<v-radio label="Sinh viên" :value="true"></v-radio>
								</v-radio-group>
							</v-col>

							<!-- Tìm kiếm CB/GV nếu là Nhân viên -->
							<v-col cols="12" class="py-1" v-if="!editItem.Is_SinhVien">
								<v-autocomplete v-model="selectedNhanVien" :items="nhanVienList"
									:item-text="formatNhanVienText" return-object label="Tìm kiếm cán bộ / giảng viên"
									placeholder="Nhập tên hoặc mã nhân viên..." dense hide-details
									:loading="isLoadingSearch" :search-input.sync="searchKeyword"
									prepend-inner-icon="mdi-account-search" @change="onSelectNhanVien"
									class="c-underline-search"></v-autocomplete>
							</v-col>

							<v-col cols="12" sm="4" class="py-1">
								<v-text-field v-model="editItem.MaDinhDanh"
									:label="editItem.Is_SinhVien ? 'Mã số sinh viên (MSSV)' : 'Mã nhân viên'"
									outlined dense hide-details="auto" :rules="[v => !!v || 'Bắt buộc nhập']"></v-text-field>
							</v-col>
							<v-col cols="12" sm="8" class="py-1">
								<v-text-field v-model="editItem.HoTen" label="Họ và tên" outlined dense
									hide-details="auto" :rules="[v => !!v || 'Bắt buộc nhập họ tên']"></v-text-field>
							</v-col>

							<v-col cols="12" sm="6" class="py-1">
								<v-text-field v-model="editItem.TenPhongBan"
									:label="editItem.Is_SinhVien ? 'Khoa / Lớp' : 'Đơn vị / Phòng ban'"
									outlined dense hide-details="auto"></v-text-field>
							</v-col>
							<v-col cols="12" sm="6" class="py-1">
								<v-text-field v-model="editItem.Email" label="Email" outlined dense hide-details="auto"></v-text-field>
							</v-col>

							<!-- Vai trò -->
							<v-col cols="12" sm="6" class="py-1">
								<v-select v-model="editItem.VaiTro" :items="roleList" item-text="text"
									item-value="value" label="Vai trò trong công trình" outlined dense
									hide-details="auto" :rules="[v => !!v || 'Bắt buộc chọn vai trò']"
									@change="onRoleChange"></v-select>
							</v-col>
							<v-col cols="12" sm="6" class="py-1">
								<v-text-field v-model.number="editItem.TyLeDongGop" label="Tỷ lệ đóng góp (%)"
									type="number" min="0" max="100" outlined dense
									hide-details="auto" :rules="[v => (v >= 0 && v <= 100) || 'Tỷ lệ từ 0 đến 100%']"></v-text-field>
							</v-col>

							<!-- Thông tin tài khoản ngân hàng -->
							<v-col cols="12" sm="6" class="py-1">
								<v-text-field v-model="editItem.SoTaiKhoan" label="Số tài khoản ngân hàng"
									outlined dense hide-details="auto"></v-text-field>
							</v-col>
							<v-col cols="12" sm="6" class="py-1">
								<v-autocomplete v-model="editItem.NganHang" :items="bankList" item-text="customText"
									item-value="shortName" label="Ngân hàng" outlined dense clearable
									hide-details="auto"></v-autocomplete>
							</v-col>
							<v-col cols="12" class="py-1">
								<v-text-field v-model="editItem.TenChuTaiKhoan" label="Tên chủ tài khoản"
									outlined dense hide-details="auto"></v-text-field>
							</v-col>

							<v-col cols="12" class="py-1" v-if="isDaiDienMode">
								<v-checkbox v-model="editItem.Is_DaiDienNhanTien"
									label="Là đại diện nhận toàn bộ tiền thưởng thay cho nhóm"
									dense hide-details class="mt-0"></v-checkbox>
							</v-col>
						</v-row>
					</v-form>
				</v-card-text>

				<v-card-actions class="pa-3">
					<v-spacer></v-spacer>
					<v-btn text small @click="closeMemberDialog">Hủy</v-btn>
					<v-btn color="primary" small elevation="0" @click="saveMember">Lưu thành viên</v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>
	</div>
</template>

<script>
	export default {
		name: 'uc-table-tac-gia',
		props: {
			value: { type: Array, default: () => [] },
			congThucId: { type: Number, default: null },
			dsCongThuc: { type: Array, default: () => [] },
			tongTienThuong: { type: Number, default: 0 },
			khenThuongObj: { type: Object, default: () => ({}) },
			dsNganHang: { type: Array, default: () => [] },
		},
		emits: ['input', 'update:congThucId', 'update:tongTienThuong'],
		data() {
			return {
				selectedCongThucID: this.congThucId,
				isCalculating: false,
				isModalOpen: false,
				isFormValid: true,
				editIndex: -1,
				isLoadingSearch: false,
				searchKeyword: '',
				selectedNhanVien: null,
				nhanVienList: [],
				localBankList: [],
				localHinhThucThanhToan: 1,
				editItem: {
					ThanhVienID: null,
					VaiTro: 1,
					Is_NhanVien: true,
					Is_SinhVien: false,
					MaDinhDanh: '',
					HoTen: '',
					Email: '',
					TenPhongBan: '',
					SoTaiKhoan: '',
					NganHang: '',
					TenChuTaiKhoan: '',
					TyLeDongGop: 100,
					SoTienThuong: 0,
					Is_DaiDienNhanTien: false,
				},
				roleList: [
					{ text: 'Tác giả chính / Trưởng nhóm', value: 1 },
					{ text: 'Đồng tác giả / Thành viên', value: 2 },
					{ text: 'Giảng viên hướng dẫn (GVHD)', value: 3 },
					{ text: 'Cán bộ hỗ trợ SHTT', value: 4 },
				],
			}
		},
		computed: {
			membersList() {
				return this.value || []
			},
			isDaiDienMode() {
				return Number(this.localHinhThucThanhToan) === 2
			},
			representativeName() {
				const rep = this.membersList.find(m => m.Is_DaiDienNhanTien)
				return rep ? rep.HoTen : ''
			},
			bankList() {
				const source = (this.dsNganHang && this.dsNganHang.length > 0) ? this.dsNganHang : this.localBankList
				return (source || []).map(b => ({
					...b,
					customText: b.shortName ? `${b.shortName} - ${b.name}` : b.name,
				}))
			},
			headers() {
				const base = [
					{ text: '#', value: 'STT', width: 45, align: 'center', sortable: false },
					{ text: 'Họ và tên', value: 'HoTen', width: 170 },
					{ text: 'Đối tượng', value: 'Is_SinhVien', width: 100, align: 'center' },
					{ text: 'Mã ĐD', value: 'MaDinhDanh', width: 90 },
					{ text: 'Vai trò', value: 'VaiTro', width: 130 },
					{ text: 'Khoa / Đơn vị', value: 'TenPhongBan', width: 140 },
					{ text: 'Số TK', value: 'SoTaiKhoan', width: 110 },
					{ text: 'Ngân hàng', value: 'NganHang', width: 120 },
					{ text: '% Tỷ lệ', value: 'TyLeDongGop', width: 90, align: 'right' },
					{ text: 'Tiền thưởng (đ)', value: 'SoTienThuong', width: 140, align: 'right' },
				]
				if (this.isDaiDienMode) {
					base.push({ text: 'Đại diện', value: 'Is_DaiDienNhanTien', width: 85, align: 'center', sortable: false })
				}
				base.push({ text: 'Thao tác', value: 'actions', width: 90, align: 'center', sortable: false })
				return base
			},
			currentCongThuc() {
				return (this.dsCongThuc || []).find(c => c.CongThucID === this.selectedCongThucID) || null
			},
			computedTotalReward() {
				return (this.membersList || []).reduce((sum, item) => sum + Number(item.SoTienThuong || 0), 0)
			},
			authorMembers() {
				return this.membersList.filter(m => m.VaiTro === 1 || m.VaiTro === 2)
			},
			mentorMembers() {
				return this.membersList.filter(m => m.VaiTro === 3)
			},
			hasMentor() {
				return this.mentorMembers.length > 0
			},
			authorTotalRate() {
				const sum = this.authorMembers.reduce((sum, m) => sum + (Number(m.TyLeDongGop) || 0), 0)
				return Math.round(sum * 100) / 100
			},
			mentorTotalRate() {
				const sum = this.mentorMembers.reduce((sum, m) => sum + (Number(m.TyLeDongGop) || 0), 0)
				return Math.round(sum * 100) / 100
			},
			originalCongThuc() {
				if (!this.currentCongThuc || this.currentCongThuc.NhomKhenThuong !== 2) return null
				return (this.dsCongThuc || []).find(c =>
					c.NhomKhenThuong === 1 &&
					c.CapDo === this.currentCongThuc.CapDo &&
					c.GiaiThuong === this.currentCongThuc.GiaiThuong
				) || null
			},
		},
		watch: {
			congThucId(val) {
				this.selectedCongThucID = val
			},
			'khenThuongObj.HinhThucThanhToan': {
				immediate: true,
				handler(val) {
					if (val === undefined || val === null) return
					const mode = Number(val) || 1
					if (this.localHinhThucThanhToan !== mode) {
						this.localHinhThucThanhToan = mode
						this.applyPaymentMode(mode, false)
					}
				},
			},
			searchKeyword(val) {
				if (val && val.length >= 2) {
					this.searchNhanVien(val)
				}
			},
		},
		mounted() {
			this.loadBankList()
		},
		methods: {
			async loadBankList() {
				if (this.dsNganHang && this.dsNganHang.length > 0) return
				try {
					const resp = await fetch('https://api.vietqr.io/v2/banks')
					const res = await resp.json()
					if (res && res.code === '00' && Array.isArray(res.data)) {
						this.localBankList = res.data
					}
				} catch (e) {
					this.localBankList = [
						{ shortName: 'SHB', name: 'NHTMCP Sài Gòn - Hà Nội' },
						{ shortName: 'VCB', name: 'NHTMCP Ngoại Thương Việt Nam' },
						{ shortName: 'CTG', name: 'NHTMCP Công Thương Việt Nam' },
						{ shortName: 'BIDV', name: 'NHTMCP Đầu Tư và Phát Triển VN' },
						{ shortName: 'MB', name: 'NHTMCP Quân Đội' },
						{ shortName: 'ACB', name: 'NHTMCP Á Châu' },
						{ shortName: 'TCB', name: 'NHTMCP Kỹ Thương Việt Nam' },
						{ shortName: 'TPB', name: 'NHTMCP Tiên Phong' },
						{ shortName: 'VPB', name: 'NHTMCP Việt Nam Thịnh Vượng' },
					]
				}
			},
			async chiaDeuTyLe() {
				if (this.membersList.length === 0) return

				// 1. Chia đều 100% cho Nhóm tác giả
				const authors = this.authorMembers
				if (authors.length > 0) {
					const count = authors.length
					const baseRate = Math.floor(100 / count)
					const remainder = 100 - baseRate * count
					authors.forEach((m, idx) => {
						m.TyLeDongGop = idx === 0 ? baseRate + remainder : baseRate
					})
				}

				// 2. Chia đều 100% cho Nhóm GVHD nếu có
				const mentors = this.mentorMembers
				if (mentors.length > 0) {
					const count = mentors.length
					const baseRate = Math.floor(100 / count)
					const remainder = 100 - baseRate * count
					mentors.forEach((m, idx) => {
						m.TyLeDongGop = idx === 0 ? baseRate + remainder : baseRate
					})
				}

				// 3. Tự động tính lại tiền thưởng theo quy chế
				if (this.selectedCongThucID) {
					await this.calculateReward()
				} else {
					this.recalculateTotals()
					Vue.$toast.success('Đã chia đều tỷ lệ 100% cho các nhóm thành viên', { position: 'top' })
				}
			},
			getRoleName(role) {
				switch (role) {
					case 1: return 'Tác giả chính'
					case 2: return 'Đồng tác giả'
					case 3: return 'GVHD'
					case 4: return 'Hỗ trợ SHTT'
					default: return ''
				}
			},
			formatCurrency(val) {
				return Number(val || 0).toLocaleString('vi-VN') + ' đ'
			},
			formatNhanVienText(item) {
				const name = item.HoTen || `${item.HoNV || item.HoLot || ''} ${item.TenNV || ''}`.trim()
				const dept = item.TenPhongBan ? ` - ${item.TenPhongBan}` : ''
				return `${name} (${item.MaNV})${dept}`
			},
			async searchNhanVien(keyword) {
				if (!keyword || keyword.trim().length < 2) return
				this.isLoadingSearch = true
				try {
					let res = await ajaxCALLPromise('/TaiKhoan_Search', { Keyword: keyword })
					if (!res || !res.length) {
						res = await ajaxCALLPromise('/TaiKhoan_Seach', { Keyword: keyword })
					}
					this.nhanVienList = res || []
				} catch (e) {
					try {
						const fallback = await ajaxCALLPromise('/TaiKhoan_Seach', { Keyword: keyword })
						this.nhanVienList = fallback || []
					} catch (err) {
						this.nhanVienList = []
					}
				} finally {
					this.isLoadingSearch = false
				}
			},
			onSelectNhanVien(item) {
				if (!item) return
				this.editItem.MaDinhDanh = item.MaNV || ''
				this.editItem.HoTen = item.HoTen || `${item.HoNV || item.HoLot || ''} ${item.TenNV || ''}`.trim()
				this.editItem.TenPhongBan = item.TenPhongBan || ''
				this.editItem.Email = item.Email || ''
				this.editItem.SoTaiKhoan = item.SoTaiKhoan || item.TaiKhoan || this.editItem.SoTaiKhoan || ''
				this.editItem.NganHang = item.NganHang || item.BankNameVietQR || this.editItem.NganHang || ''
				this.editItem.TenChuTaiKhoan = item.TenChuTaiKhoan || item.TenThe || this.editItem.HoTen
			},
			onRoleChange(role) {
				if (role === 3) {
					// GVHD luôn là Cán bộ / Giảng viên
					this.editItem.Is_SinhVien = false
					this.editItem.Is_NhanVien = true
				}
			},
			onTargetTypeChange(isSinhVien) {
				this.editItem.Is_NhanVien = !isSinhVien
				this.selectedNhanVien = null
				if (isSinhVien) {
					this.editItem.TenPhongBan = ''
					if (this.editItem.VaiTro === 3) {
						this.editItem.VaiTro = 1
					}
				}
			},
			openMemberDialog(item, index = -1) {
				this.editIndex = index
				this.selectedNhanVien = null
				this.nhanVienList = []
				this.searchKeyword = ''
				if (item) {
					this.editItem = JSON.parse(JSON.stringify(item))
				} else {
					this.editItem = {
						ThanhVienID: null,
						VaiTro: 1,
						Is_NhanVien: false,
						Is_SinhVien: true,
						MaDinhDanh: '',
						HoTen: '',
						Email: '',
						TenPhongBan: '',
						SoTaiKhoan: '',
						NganHang: '',
						TenChuTaiKhoan: '',
						TyLeDongGop: 100,
						SoTienThuong: 0,
						Is_DaiDienNhanTien: false,
					}
				}
				this.isModalOpen = true
				this.$nextTick(() => {
					if (this.$refs.memberForm) {
						this.$refs.memberForm.resetValidation()
					}
				})
			},
			closeMemberDialog() {
				this.isModalOpen = false
				this.editIndex = -1
				this.selectedNhanVien = null
			},
			async saveMember() {
				if (this.$refs.memberForm && !this.$refs.memberForm.validate()) return

				if (!this.editItem.TenChuTaiKhoan && this.editItem.HoTen) {
					this.editItem.TenChuTaiKhoan = this.editItem.HoTen
				}

				if (this.editIndex === -1) {
					this.membersList.push({ ...this.editItem })
					Vue.$toast.success('Đã thêm thành viên mới!', { position: 'top' })
				} else {
					this.$set(this.membersList, this.editIndex, { ...this.editItem })
					Vue.$toast.success('Đã cập nhật thông tin thành viên!', { position: 'top' })
				}

				this.closeMemberDialog()

				if (this.selectedCongThucID) {
					await this.calculateReward()
				} else {
					this.recalculateTotals()
				}
			},
			deleteMember(index) {
				const item = this.membersList[index]
				if (!item) return
				confirm({
					title: `Xác nhận xóa thành viên "${item.HoTen || 'này'}" khỏi danh sách?`,
					action: async () => {
						this.membersList.splice(index, 1)
						Vue.$toast.success('Đã xóa thành viên khỏi danh sách', { position: 'top' })
						if (this.selectedCongThucID) {
							await this.calculateReward()
						} else {
							this.recalculateTotals()
						}
					},
				})
			},
			onSelectCongThuc(val) {
				this.selectedCongThucID = val
				this.$emit('update:congThucId', val)
				if (!val) {
					this.membersList.forEach(m => { m.SoTienThuong = 0 })
					this.recalculateTotals()
					return
				}
				this.calculateReward()
			},
			onPaymentModeChange(val) {
				const mode = Number(val) || 1
				this.localHinhThucThanhToan = mode
				if (this.khenThuongObj) {
					this.$set(this.khenThuongObj, 'HinhThucThanhToan', mode)
				}
				this.$emit('update:hinh-thuc-thanh-toan', mode)
				this.applyPaymentMode(mode, true)
			},
			async applyPaymentMode(mode, showToast = false) {
				if (mode === 2) {
					// 1. Chế độ Ủy quyền đại diện nhận thay
					const hasRep = this.membersList.some(m => m.Is_DaiDienNhanTien)
					if (!hasRep && this.membersList.length > 0) {
						// Tự động chọn Tác giả chính (VaiTro = 1) hoặc tác giả đầu tiên
						const mainAuthor = this.membersList.find(m => m.VaiTro === 1) || this.membersList.find(m => m.VaiTro === 2) || this.membersList[0]
						if (mainAuthor) {
							this.membersList.forEach(m => { m.Is_DaiDienNhanTien = false })
							mainAuthor.Is_DaiDienNhanTien = true
						}
					}
					if (this.selectedCongThucID) {
						await this.calculateReward()
					} else {
						this.recalculateTotals()
					}
					if (showToast) {
						const rep = this.membersList.find(m => m.Is_DaiDienNhanTien)
						Vue.$toast.info(`Chế độ Ủy quyền: ${rep ? rep.HoTen + ' đại diện nhận tiền.' : 'Vui lòng chọn 1 người đại diện nhận tiền.'}`, { position: 'top' })
					}
				} else {
					// 2. Chế độ Chuyển khoản từng cá nhân
					this.membersList.forEach(m => {
						m.Is_DaiDienNhanTien = false
					})
					if (this.selectedCongThucID) {
						await this.calculateReward()
					} else {
						this.recalculateTotals()
					}
					if (showToast) {
						Vue.$toast.info('Đã chuyển sang chế độ chuyển khoản từng cá nhân theo tỷ lệ %', { position: 'top' })
					}
				}
				this.$emit('input', [...this.membersList])
			},
			async onToggleDaiDien(targetItem) {
				if (targetItem.Is_DaiDienNhanTien) {
					// 1. Đảm bảo chỉ 1 người được làm đại diện duy nhất
					this.membersList.forEach(m => {
						if (m !== targetItem) {
							m.Is_DaiDienNhanTien = false
						}
					})
				} else {
					// Không cho bỏ tích đại diện nếu đang ở mode 2 (phải có ít nhất 1 người đại diện)
					const hasOtherRep = this.membersList.some(m => m !== targetItem && m.Is_DaiDienNhanTien)
					if (!hasOtherRep) {
						targetItem.Is_DaiDienNhanTien = true
						Vue.$toast.warning('Ở chế độ ủy quyền nhận thay, bắt buộc phải có 1 người đại diện!', { position: 'top' })
						return
					}
				}

				// 2. Tính toán và phân bổ tiền chính xác
				if (this.selectedCongThucID) {
					await this.calculateReward()
					if (targetItem.Is_DaiDienNhanTien) {
						Vue.$toast.info(`Đã gom toàn bộ tiền thưởng vào đại diện ${targetItem.HoTen}`, { position: 'top' })
					}
				} else {
					this.recalculateTotals()
				}
			},
			async onChangeTyLeDongGop() {
				if (this.selectedCongThucID) {
					await this.calculateReward()
				} else {
					this.recalculateTotals()
				}
			},
			updateMembersFromResult(calcRows) {
				if (!Array.isArray(calcRows) || calcRows.length === 0) return

				calcRows.forEach((row, idx) => {
					let m = null
					if (row.ThanhVienID) {
						m = this.membersList.find(x => x.ThanhVienID === row.ThanhVienID)
					}
					if (!m && this.membersList[idx]) {
						m = this.membersList[idx]
					}
					if (m) {
						m.SoTienThuong = Number(row.SoTienThuong || 0)
						m.Is_DaiDienNhanTien = Boolean(row.Is_DaiDienNhanTien)
						if (row.TyLeDongGop !== undefined && row.TyLeDongGop !== null) {
							m.TyLeDongGop = Number(row.TyLeDongGop)
						}
					}
				})
				this.recalculateTotals()
			},
			async calculateReward() {
				if (!this.selectedCongThucID) {
					Vue.$toast.warning('Vui lòng chọn công thức khen thưởng trước khi tính tiền!', { position: 'top' })
					return
				}

				this.isCalculating = true
				try {
					const hinhThuc = Number(this.localHinhThucThanhToan) || Number(this.khenThuongObj && this.khenThuongObj.HinhThucThanhToan) || 1
					const payload = {
						CongThucID: this.selectedCongThucID,
						MembersJson: JSON.stringify(this.membersList),
						HinhThucThanhToan: hinhThuc,
					}
					const res = await ajaxCALLPromise('/ThiKHCN_PhiKhenThuong_Cal', payload)
					if (Array.isArray(res)) {
						this.updateMembersFromResult(res)
						Vue.$toast.success('Tính tiền thưởng thành công!', { position: 'top' })
					} else {
						Vue.$toast.warning('Kết quả tính tiền không đúng định dạng', { position: 'top' })
					}
				} catch (err) {
					console.error('Lỗi tính tiền thưởng:', err)
					Vue.$toast.error('Có lỗi xảy ra khi tính tiền thưởng!', { position: 'top' })
				} finally {
					this.isCalculating = false
				}
			},
			recalculateTotals() {
				const total = this.computedTotalReward
				this.$emit('update:tongTienThuong', total)
				this.$emit('input', [...this.membersList])
			},
		},
	}
</script>