<template>
	<v-card outlined class="rounded-xs">
		<v-card-title class="pa-3 d-flex align-center justify-space-between flex-wrap" style="gap: 8px;">
			<div class="d-flex align-center flex-wrap" style="gap: 8px;">
				<span class="text-subtitle-1 font-weight-bold primary--text">
					<v-icon color="primary" class="mr-1">mdi-account-group</v-icon>
					Danh sách thành viên nhận khen thưởng
				</span>
				<!-- Chip trạng thái tổng tỷ lệ Nhóm tác giả -->
				<v-chip x-small :color="authorTotalRate === 100 ? 'success' : 'error'" class="font-weight-medium" outlined>
					<v-icon left x-small>{{ authorTotalRate === 100 ? 'mdi-check' : 'mdi-alert' }}</v-icon>
					Tác giả: {{ authorTotalRate }}% / 100%
				</v-chip>
				<!-- Chip trạng thái tổng tỷ lệ Nhóm GVHD nếu có -->
				<v-chip x-small v-if="hasMentor" :color="mentorTotalRate === 100 ? 'success' : 'error'" class="font-weight-medium" outlined>
					<v-icon left x-small>{{ mentorTotalRate === 100 ? 'mdi-check' : 'mdi-alert' }}</v-icon>
					GVHD: {{ mentorTotalRate }}% / 100%
				</v-chip>
			</div>
			<div class="d-flex align-center flex-wrap" style="gap: 8px;">
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

				<!-- Option chia đều nhanh -->
				<v-btn color="indigo darken-1" small outlined elevation="0" class="text-capitalize"
					:disabled="membersList.length === 0" @click="chiaDeuTyLe">
					<v-icon left small>mdi-scale-balance</v-icon>Chia đều 100%
				</v-btn>
				<v-btn color="primary" small elevation="0" class="text-capitalize" @click="openDialog(null)">
					<v-icon left small>mdi-account-plus</v-icon>Thêm thành viên
				</v-btn>
			</div>
		</v-card-title>

		<!-- Banner thông báo khi ở chế độ ủy quyền -->
		<v-alert v-if="isDaiDienMode" type="info" text dense class="mx-3 my-2 rounded-xs font-weight-medium">
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

		<v-card-text class="pa-0">
			<v-data-table dense :headers="headers" :items="membersList" hide-default-footer
				class="nowrap-table" no-data-text="Chưa có thành viên nào trong danh sách">
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
					<div class="d-flex align-center justify-end" style="max-width: 100px;">
						<v-text-field v-model.number="item.TyLeDongGop" type="number" min="1" max="100" dense outlined
							hide-details suffix="%" class="text-right my-1" style="font-size: 13px;" />
					</div>
				</template>

				<template v-slot:item.Is_DaiDienNhanTien="{ item }">
					<div class="d-flex justify-center align-center">
						<v-checkbox v-model="item.Is_DaiDienNhanTien" dense hide-details class="mt-0 pt-0"
							@change="onToggleDaiDien(item)"></v-checkbox>
					</div>
				</template>

				<template v-slot:item.actions="{ item, index }">
					<div class="d-flex align-center justify-center">
						<v-icon small color="green darken-2" class="mr-2" @click="openDialog(item, index)">
							mdi-square-edit-outline
						</v-icon>
						<v-icon small color="red darken-3" @click="deleteMember(index)">
							mdi-trash-can-outline
						</v-icon>
					</div>
				</template>
			</v-data-table>
		</v-card-text>

		<!-- Dialog Thêm / Sửa thành viên -->
		<v-dialog v-model="isModalOpen" max-width="700px" persistent>
			<v-card class="rounded-xs">
				<v-card-title class="pa-3 d-flex align-center justify-space-between primary white--text">
					<span class="text-subtitle-1 font-weight-bold">
						{{ editIndex === -1 ? 'Thêm thành viên mới' : 'Chỉnh sửa thông tin thành viên' }}
					</span>
					<v-btn icon dark small @click="closeDialog">
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
									type="number" min="1" max="100" outlined dense
									hide-details="auto" :rules="[v => (v > 0 && v <= 100) || 'Tỷ lệ từ 1 đến 100%']"></v-text-field>
							</v-col>

							<!-- Thông tin tài khoản ngân hàng -->
							<v-col cols="12" sm="6" class="py-1">
								<v-text-field v-model="editItem.SoTaiKhoan" label="Số tài khoản ngân hàng"
									outlined dense hide-details="auto" :rules="[v => !!v || 'Bắt buộc nhập STK']"></v-text-field>
							</v-col>
							<v-col cols="12" sm="6" class="py-1">
								<v-autocomplete v-model="editItem.NganHang" :items="bankList" item-text="customText"
									item-value="shortName" label="Ngân hàng" outlined dense
									hide-details="auto" :rules="[v => !!v || 'Bắt buộc chọn ngân hàng']"></v-autocomplete>
							</v-col>
							<v-col cols="12" class="py-1">
								<v-text-field v-model="editItem.TenChuTaiKhoan" label="Tên chủ tài khoản"
									outlined dense hide-details="auto" :rules="[v => !!v || 'Bắt buộc nhập tên chủ tài khoản']"></v-text-field>
							</v-col>

							<v-col cols="12" class="py-1">
								<v-checkbox v-model="editItem.Is_DaiDienNhanTien"
									label="Là đại diện nhận toàn bộ tiền thưởng thay cho nhóm"
									dense hide-details class="mt-0"></v-checkbox>
							</v-col>
						</v-row>
					</v-form>
				</v-card-text>

				<v-card-actions class="pa-3">
					<v-spacer></v-spacer>
					<v-btn text @click="closeDialog">Hủy</v-btn>
					<v-btn color="primary" elevation="0" @click="saveMember">Lưu thành viên</v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>
	</v-card>
</template>

<script>
	export default {
		name: 'uc-table-tac-gia',
		props: {
			value: { type: Array, default: () => [] },
			khenThuongObj: { type: Object, default: () => ({}) },
			dsNganHang: { type: Array, default: () => [] },
		},
		emits: ['input', 'update:hinh-thuc-thanh-toan'],
		data() {
			return {
				isModalOpen: false,
				isFormValid: true,
				editIndex: -1,
				isLoadingSearch: false,
				searchKeyword: '',
				selectedNhanVien: null,
				nhanVienList: [],
				localHinhThucThanhToan: 1,
				editItem: {
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
					Is_DaiDienNhanTien: false,
				},
				localBankList: [
					{ shortName: 'SHB', name: 'NHTMCP Sài Gòn - Hà Nội' },
					{ shortName: 'VCB', name: 'NHTMCP Ngoại Thương Việt Nam' },
					{ shortName: 'CTG', name: 'NHTMCP Công Thương Việt Nam' },
					{ shortName: 'BIDV', name: 'NHTMCP Đầu Tư và Phát Triển VN' },
					{ shortName: 'MB', name: 'NHTMCP Quân Đội' },
					{ shortName: 'ACB', name: 'NHTMCP Á Châu' },
					{ shortName: 'TCB', name: 'NHTMCP Kỹ Thương Việt Nam' },
					{ shortName: 'TPB', name: 'NHTMCP Tiên Phong' },
					{ shortName: 'VPB', name: 'NHTMCP Việt Nam Thịnh Vượng' },
				],
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
			headers() {
				const base = [
					{ text: '#', value: 'STT', width: 50, align: 'center', sortable: false },
					{ text: 'Họ và tên', value: 'HoTen', width: 180 },
					{ text: 'Đối tượng', value: 'Is_SinhVien', width: 110, align: 'center' },
					{ text: 'Mã ĐD', value: 'MaDinhDanh', width: 100 },
					{ text: 'Vai trò', value: 'VaiTro', width: 160 },
					{ text: 'Khoa / Đơn vị', value: 'TenPhongBan', width: 150 },
					{ text: 'Số TK', value: 'SoTaiKhoan', width: 120 },
					{ text: 'Ngân hàng', value: 'NganHang', width: 130 },
					{ text: '% Đóng góp', value: 'TyLeDongGop', align: 'right', width: 100 },
				]
				if (this.isDaiDienMode) {
					base.push({ text: 'Đại diện', value: 'Is_DaiDienNhanTien', align: 'center', width: 90, sortable: false })
				}
				base.push({ text: 'Thao tác', value: 'actions', align: 'center', width: 80, sortable: false })
				return base
			},
			bankList() {
				const list = (this.dsNganHang && this.dsNganHang.length > 0) ? this.dsNganHang : this.localBankList
				return list.map(b => ({
					...b,
					customText: b.shortName ? `${b.shortName} - ${b.name}` : b.name,
				}))
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
		},
		watch: {
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
		methods: {
			chiaDeuTyLe() {
				if (this.membersList.length === 0) return

				// 1. Chia đều 100% cho Nhóm tác giả (VaiTro = 1 hoặc 2)
				const authors = this.authorMembers
				if (authors.length > 0) {
					const count = authors.length
					const baseRate = Math.floor(100 / count)
					const remainder = 100 - baseRate * count
					authors.forEach((m, idx) => {
						// Bù phần dư vào người đầu tiên để tổng luôn chính xác 100%
						m.TyLeDongGop = idx === 0 ? baseRate + remainder : baseRate
					})
				}

				// 2. Chia đều 100% cho Nhóm GVHD (VaiTro = 3) nếu có
				const mentors = this.mentorMembers
				if (mentors.length > 0) {
					const count = mentors.length
					const baseRate = Math.floor(100 / count)
					const remainder = 100 - baseRate * count
					mentors.forEach((m, idx) => {
						m.TyLeDongGop = idx === 0 ? baseRate + remainder : baseRate
					})
				}

				// 3. Nhóm Hỗ trợ SHTT (VaiTro = 4) nếu có
				const supporters = this.membersList.filter(m => m.VaiTro === 4)
				if (supporters.length > 0) {
					const count = supporters.length
					const baseRate = Math.floor(100 / count)
					const remainder = 100 - baseRate * count
					supporters.forEach((m, idx) => {
						m.TyLeDongGop = idx === 0 ? baseRate + remainder : baseRate
					})
				}

				this.$emit('input', [...this.membersList])
				Vue.$toast.success('Đã chia đều tỷ lệ 100% cho các nhóm thành viên', { position: 'top' })
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
			onTargetTypeChange(isSinhVien) {
				this.editItem.Is_NhanVien = !isSinhVien
				this.selectedNhanVien = null
				if (isSinhVien) {
					this.editItem.TenPhongBan = ''
				}
			},
			onRoleChange(newRole) {
				// RÀNG BUỘC GVHD: Chỉ cho phép chọn GVHD khi toàn bộ tác giả dự thi là Sinh viên
				if (newRole === 3) {
					const hasTeacherInAuthors = this.membersList.some(m => (m.VaiTro === 1 || m.VaiTro === 2) && !m.Is_SinhVien)
					if (hasTeacherInAuthors) {
						Vue.$toast.warning('Theo quy chế, chỉ nhóm tác giả 100% là Sinh viên mới được kê khai Giảng viên hướng dẫn!', { position: 'top' })
						this.editItem.VaiTro = 2
					}
				}
			},
			openDialog(item, index = -1) {
				this.editIndex = index
				if (item) {
					this.editItem = JSON.parse(JSON.stringify(item))
				} else {
					// Nếu là thành viên đầu tiên của nhóm thì mặc định 100%
					this.editItem = {
						VaiTro: this.membersList.length === 0 ? 1 : 2,
						Is_NhanVien: true,
						Is_SinhVien: false,
						MaDinhDanh: '',
						HoTen: '',
						Email: '',
						TenPhongBan: '',
						SoTaiKhoan: '',
						NganHang: '',
						TenChuTaiKhoan: '',
						TyLeDongGop: this.membersList.length === 0 ? 100 : 0,
						Is_DaiDienNhanTien: false,
					}
				}
				this.selectedNhanVien = null
				this.isModalOpen = true
			},
			closeDialog() {
				this.isModalOpen = false
			},
			saveMember() {
				if (!this.$refs.memberForm.validate()) return

				// Kiểm tra ràng buộc GVHD lần nữa
				if (this.editItem.VaiTro === 3) {
					const hasTeacher = this.membersList.some((m, idx) => idx !== this.editIndex && (m.VaiTro === 1 || m.VaiTro === 2) && !m.Is_SinhVien)
					if (hasTeacher) {
						Vue.$toast.error('Không thể thêm GVHD vì có Cán bộ/GV trong nhóm tác giả!', { position: 'top' })
						return
					}
				}

				if (this.editItem.Is_DaiDienNhanTien) {
					this.membersList.forEach((m, idx) => {
						if (idx !== this.editIndex) {
							m.Is_DaiDienNhanTien = false
						}
					})
				}

				if (this.editIndex === -1) {
					this.membersList.push({ ...this.editItem })
				} else {
					this.membersList.splice(this.editIndex, 1, { ...this.editItem })
				}

				this.closeDialog()
				this.$emit('input', [...this.membersList])
				Vue.$toast.success('Đã lưu thông tin thành viên', { position: 'top' })
			},
			deleteMember(index) {
				this.membersList.splice(index, 1)
				this.$emit('input', [...this.membersList])
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
			applyPaymentMode(mode, showToast = false) {
				if (mode === 2) {
					const hasRep = this.membersList.some(m => m.Is_DaiDienNhanTien)
					if (!hasRep && this.membersList.length > 0) {
						const mainAuthor = this.membersList.find(m => m.VaiTro === 1) || this.membersList.find(m => m.VaiTro === 2) || this.membersList[0]
						if (mainAuthor) {
							this.membersList.forEach(m => { m.Is_DaiDienNhanTien = false })
							mainAuthor.Is_DaiDienNhanTien = true
						}
					}
					if (showToast) {
						const rep = this.membersList.find(m => m.Is_DaiDienNhanTien)
						Vue.$toast.info(`Chế độ Ủy quyền: ${rep ? rep.HoTen + ' đại diện nhận tiền.' : 'Vui lòng chọn 1 người đại diện nhận tiền.'}`, { position: 'top' })
					}
				} else {
					this.membersList.forEach(m => {
						m.Is_DaiDienNhanTien = false
					})
					if (showToast) {
						Vue.$toast.info('Đã chuyển sang chế độ chuyển khoản từng cá nhân theo tỷ lệ %', { position: 'top' })
					}
				}
				this.$emit('input', [...this.membersList])
			},
			onToggleDaiDien(targetItem) {
				if (targetItem.Is_DaiDienNhanTien) {
					this.membersList.forEach(m => {
						if (m !== targetItem) {
							m.Is_DaiDienNhanTien = false
						}
					})
					Vue.$toast.info(`Đã chọn ${targetItem.HoTen} là người đại diện nhận thay cho nhóm`, { position: 'top' })
				} else {
					const hasOtherRep = this.membersList.some(m => m !== targetItem && m.Is_DaiDienNhanTien)
					if (!hasOtherRep) {
						targetItem.Is_DaiDienNhanTien = true
						Vue.$toast.warning('Ở chế độ ủy quyền nhận thay, bắt buộc phải có 1 người đại diện!', { position: 'top' })
						return
					}
				}
				this.$emit('input', [...this.membersList])
			},
			validate() {
				if (this.membersList.length === 0) {
					Vue.$toast.warning('Vui lòng thêm ít nhất 1 thành viên nhận khen thưởng!', { position: 'top' })
					return false
				}
				const hasMainAuthor = this.membersList.some(m => m.VaiTro === 1)
				if (!hasMainAuthor) {
					Vue.$toast.warning('Danh sách bắt buộc phải có 1 Tác giả chính / Trưởng nhóm!', { position: 'top' })
					return false
				}

				// 1. Giới hạn tổng tỷ lệ Nhóm tác giả phải là 100%
				if (this.authorMembers.length > 0) {
					const total = this.authorTotalRate
					if (Math.round(total) !== 100) {
						Vue.$toast.error(`Tổng tỷ lệ đóng góp của Nhóm tác giả phải bằng 100% (Hiện tại là ${total}%). Vui lòng điều chỉnh hoặc bấm nút "Chia đều 100%"!`, { position: 'top' })
						return false
					}
				}

				// 2. Giới hạn tổng tỷ lệ Nhóm GVHD (nếu có) phải là 100%
				if (this.mentorMembers.length > 0) {
					const total = this.mentorTotalRate
					if (Math.round(total) !== 100) {
						Vue.$toast.error(`Tổng tỷ lệ đóng góp của Nhóm GVHD phải bằng 100% (Hiện tại là ${total}%). Vui lòng điều chỉnh hoặc bấm nút "Chia đều 100%"!`, { position: 'top' })
						return false
					}
				}

				// 3. Nếu ở chế độ ủy quyền nhận thay, bắt buộc phải có 1 người đại diện
				if (this.isDaiDienMode) {
					const hasRep = this.membersList.some(m => m.Is_DaiDienNhanTien)
					if (!hasRep) {
						Vue.$toast.error('Ở chế độ ủy quyền nhận thay, vui lòng chọn 1 thành viên làm đại diện nhận tiền!', { position: 'top' })
						return false
					}
				}

				return true
			},
		},
	}
</script>