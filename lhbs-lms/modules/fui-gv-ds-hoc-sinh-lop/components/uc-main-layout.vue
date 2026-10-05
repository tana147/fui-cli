<template>
	<Global>
		<template #header>
			<v-card>
				<v-card-title class="d-flex align-center flex-wrap ga-2">
					<span>{{ TitlePage }} • {{ TitleCap }}</span>
					<v-spacer />
					<v-btn-toggle v-model="isEn" size="small" class="ml-auto">
						<v-btn :value="false" :disabled="!isEn" :color="!isEn ? 'green' : 'white'" @click="setLanguage(false)">
							<v-img src="/_cdn/lhbs-lms/img_page_ph/Viet.png" width="30" />
						</v-btn>
						<v-btn :value="true" :disabled="isEn" :color="isEn ? 'green' : 'white'" @click="setLanguage(true)">
							<v-img src="/_cdn/lhbs-lms/img_page_ph/Anh.png" width="30" />
						</v-btn>
					</v-btn-toggle>
				</v-card-title>
				<v-card-text>
					<v-row align="center">
						<v-col cols="12" sm="3">
							<v-select :key="'khoi_' + isEn" v-model="KhoiItem" :label="isEn ? 'Select grade' : 'Chọn khối'" :items="DSKhoi" :item-title="formatKhoiHienThi"
								item-value="KhoiID" return-object="" :no-data-text="isEn ? 'No data available' : 'Chưa có dữ liệu'">
								<template #selection="{ item }">
									<span>{{ formatKhoiHienThi(item) }}</span>
								</template>
								<template #item="{ props, item }">
									<v-list-item v-bind="props" :title="formatKhoiHienThi(item)"></v-list-item>
								</template>
							</v-select>
						</v-col>
						<v-col cols="12" sm="3">
							<v-select :key="'lop_' + isEn" v-model="LopItem" :label="isEn ? 'Select class' : 'Chọn lớp'" :items="DSLop" item-title="TenLop"
								item-value="LopID" :disabled="!KhoiItem" return-object="" :no-data-text="isEn ? 'No data available' : 'Chưa có dữ liệu'">
							</v-select>
						</v-col>
						<v-col class="d-flex align-center ga-2 flex-wrap">
							<v-btn @click="getHocSinh()" variant="outlined" color="primary" :disabled="!LopItem">
								<v-icon start="">mdi-reload</v-icon>{{ isEn ? 'Refresh' : 'Làm mới' }}
							</v-btn>
							<v-btn @click="insHocSinh()" color="teal" :disabled="DSHocSinhSelected.length === 0">
								<v-icon start="">mdi-sync</v-icon>
								{{ isEn ? 'Update student list' : 'Cập nhật DS học sinh' }}
								<v-badge v-if="DSHocSinhSelected.length > 0" :content="DSHocSinhSelected.length"
									color="white" text-color="teal" inline="">
								</v-badge>
							</v-btn>
						</v-col>
					</v-row>
				</v-card-text>
			</v-card>
		</template>

		<!-- Thay toàn bộ phần template v-data-table -->
		<v-data-table v-model="DSHocSinhSelected" :headers="headers" :items="items" :show-select="true" :items-per-page="-1"
			:loading="isLoadingHocSinh" :loading-text="isEn ? 'Loading student list...' : 'Đang tải danh sách học sinh...'"
			:items-per-page-text="isEn ? 'Items per page:' : 'Dữ liệu trên mỗi trang'"
			:no-data-text="isEn ? 'No data available' : 'Chưa có dữ liệu'"
			:item-value="(item) => item" hide-default-footer style="max-height: calc(100dvh - 77px); overflow-y: auto;">
			<!-- STT -->
			<template #item.STT="{ item }">
				<span class="text-caption text-medium-emphasis font-weight-medium">{{ item.STT }}</span>
			</template>

			<!-- Thông tin học sinh — gộp avatar + tên + ID + tên tiếng Anh vào 1 hàng ngang -->
			<template #item.ThongTinHocSinh="{ item }">
				<div class="d-flex align-center ga-3 py-2">
					<v-avatar :size="52" class="elevation-2 flex-shrink-0 cursor-pointer"
						v-on:click="openAvatarDialog(item)" v-tooltip="isEn ? 'View full photo' : 'Xem ảnh đầy đủ'">
						<v-img :src="vueData.v_Set.urlAvatarHocSinh + item.HocSinhID + '/' + Date.now()">
						</v-img>
					</v-avatar>
					<div class="d-flex flex-column ga-1">
						<span class="font-weight-bold text-body-2">{{ item.HoTen }}</span>
						<div class="d-flex align-center ga-2 flex-wrap">
							<v-chip size="x-small" variant="tonal" color="primary" label="">
								{{ item.HocSinhID }}
							</v-chip>
							<v-chip size="x-small" variant="tonal" color="secondary" label="">
								SDB: {{ item.SoDanhBo ?? '—' }}
							</v-chip>
						</div>
						<div class="d-flex align-center ga-1">
							<span class="text-caption text-success font-weight-medium">
								{{ item.EnglishName ?? '—' }}
							</span>
							<v-btn icon="mdi-square-edit-outline" color="success" variant="text" size="x-small"
								v-tooltip="isEn ? 'Update English name' : 'Cập nhật tên tiếng Anh'" @click="onOpenModalEditProfile(item)">
							</v-btn>
						</div>
					</div>
				</div>
			</template>

			<!-- Tình trạng KQHT -->
			<template #item.TinhTrangKQHT="{ item }">
				<v-chip v-if="item.isExistInKQHT" :color="renderColorTinhTrang(item.TinhTrangKQHT)" size="small"
					label="">
					<v-icon start="" size="13">mdi-school</v-icon>
					{{ formatTinhTrang(item.TenTinhTrangKQHT, item.TinhTrangKQHT) }}
				</v-chip>
				<v-chip v-else="" color="warning" variant="tonal" size="small" label="">
					<v-icon start="" size="13">mdi-alert-outline</v-icon>
					{{ isEn ? 'Not in Academic Results' : 'Chưa có trong KQHT' }}
				</v-chip>
			</template>

			<!-- Tình trạng QLHS -->
			<template #item.TinhTrangQLHS="{ item }">
				<v-chip :color="renderColorTinhTrang(item.TinhTrangQLHS)" size="small" label="">
					<v-icon start="" size="13">mdi-account-check</v-icon>
					{{ formatTinhTrang(item.TenTinhTrangQLHS, item.TinhTrangQLHS) }}
				</v-chip>
			</template>

			<!-- Nhận xét chuẩn bị niên khóa sau -->
			<template #item.NhanXet_ChuanBiNienKhoaSau="{ item }">
				<div v-if="item.NhanXet_ChuanBiNienKhoaSau" class="py-2 px-1" style="max-width: 360px;">
					<div class="text-body-2"
						style="display: -webkit-box; -webkit-line-clamp: 3; -webkit-box-orient: vertical; overflow: hidden; line-height: 1.4;">
						{{ item.NhanXet_ChuanBiNienKhoaSau }}
					</div>
				</div>
				<v-chip v-else size="x-small" variant="tonal" color="grey">
					{{ isEn ? 'No comments yet' : 'Chưa có nhận xét' }}
				</v-chip>
			</template>

			<!-- Xem chi tiết -->
			<template #item.XemChiTiet="{ item }">
				<v-btn @click="localStorageSetItem(item)" icon="mdi-eye-outline" variant="text" color="primary"
					size="small" v-tooltip="(isEn ? 'View details ' : 'Xem chi tiết ') + item.HoTen">
				</v-btn>
			</template>
		</v-data-table>

		<uc-modal-edit-profile-shared @refresh="getHocSinh(true)" />

		<v-dialog v-model="isOpenAvatarDialog" max-width="900">
			<div style="position: relative; display: block; line-height: 0; width: fit-content; margin: 0 auto;">
				<img :src="AvatarImageUrl" :alt="isEn ? 'Student photo' : 'Ảnh học sinh'"
					style="display: block; max-height: 90vh; width: auto; height: auto;" />
				<v-btn icon="mdi-close" variant="text" color="white"
					style="position: absolute; top: 8px; right: 8px; z-index: 1;"
					v-on:click="isOpenAvatarDialog = false" />
			</div>
		</v-dialog>
	</Global>
</template>

<script>
	export default {
		inject: ['snackbarRef', 'iframeRef'],
	
		data() {
			const isEn = JSON.parse(localStorage.getItem('IsLanguage')) ?? false;
			if (this.$i18n) {
				this.$i18n.locale = isEn ? 'en' : 'vi';
			}
			return {
				isEn,
				vueData,
				items: [],
				DSKhoi: [],
				DSLop: [],
				KhoiItem: null,
				LopItem: null,
				DSHocSinhSelected: [],
				// Giữ table ở trạng thái loading trong suốt thời gian tải dữ liệu theo lớp.
				isLoadingHocSinh: false,
				StudentProfile: null,
				isOpenModalEditProfile: false,
				isOpenAvatarDialog: false,
				AvatarStudent: null,
			}
		},
	
		computed: {
			headers() {
				return [
					{ title: "#", value: "STT", align: "center", width: 56 },
					{ title: this.isEn ? "Student" : "Học sinh", value: "ThongTinHocSinh", align: "start", minWidth: 280 },
					{ title: this.isEn ? "LMS Status" : "Trạng thái LMS", value: "TinhTrangKQHT", align: "center", width: 180 },
					{ title: this.isEn ? "SIS Status" : "Trạng thái QLHS", value: "TinhTrangQLHS", align: "center", width: 180 },
					{ title: this.isEn ? "Next school year prep notes" : "Nhận xét chuẩn bị niên khóa sau", value: "NhanXet_ChuanBiNienKhoaSau", align: "start", minWidth: 280 },
					{ title: "", value: "XemChiTiet", align: "center", width: 120, sortable: false },
				]
			},
			TitleCap() {
				const capId = parseInt(vueData.capid || vueData.CapID);
				if (this.isEn) {
					if (capId === 1) return 'Primary School';
					if (capId === 2) return 'Secondary School';
					if (capId === 3) return 'High School';
					return `Level ${capId}`;
				}
				return renderText(capId);
			},
			TitlePage() {
				if (this.isEn) {
					return 'Student List';
				}
				return getTitlePageByURL(window.location.pathname + window.location.search);
			},
			AvatarImageUrl() {
				return this.AvatarStudent?.HocSinhID ? vueData.v_Set?.urlAvatarHocSinh + this.AvatarStudent.HocSinhID + '/' + Date.now() : ''
			},
		},
	
		watch: {
			"vueData.NienKhoa": {
				immediate: true,
				handler(newVal) {
					if (!newVal) return
					this.DSKhoi = []
					this.KhoiItem = null
					this.LopItem = null
					this.items = []
					this.getKhoi(true)
				}
			},
			KhoiItem(val) {
				if (!val) return
				this.LopItem = null
				this.items = []
				this.getLop(true)
			},
			LopItem(val) {
				if (!val) return
				this.items = []
				this.getHocSinh(true)
			},
		},
	
		mounted() {
			window.addEventListener('storage', (e) => {
				if (e.key === 'IsLanguage') {
					const isEn = JSON.parse(e.newValue) ?? false;
					this.isEn = isEn;
					if (this.$i18n) this.$i18n.locale = isEn ? 'en' : 'vi';
				}
			});
		},

	
		methods: {
			formatKhoiHienThi(item) {
				if (!item) return '';
				const raw = (item && item.raw) ? item.raw : item;
				const name = typeof raw === 'object' ? (raw.TenKhoiHoc || raw.title) : raw;
				if (!name) return '';
				if (!this.isEn) return name;
				return String(name).replace(/Khối/gi, 'Grade');
			},

			setLanguage(val) {
				this.isEn = val;
				if (this.$i18n) this.$i18n.locale = val ? 'en' : 'vi';
				localStorage.setItem('IsLanguage', JSON.stringify(val));
			},

			openAvatarDialog(student) {
				this.AvatarStudent = student
				this.isOpenAvatarDialog = true
			},

			async getKhoi(forceRefresh = false) {
				this.DSKhoi = await fetchPromise("lms/KhoiHocByCapHoc_Get", { 
					CapID: vueData.CapID,
					HocKi: vueData.NienKhoaItem.HocKi,
					NienKhoa: vueData.NienKhoa,
					 }, { forceRefresh })
			},
	
			async getLop(forceRefresh = false) {
				const _dsLop = await fetchPromise("lms/Lop_Get_ByKhoiID", {
					NienKhoa: vueData.NienKhoa,
					HocKi: vueData.NienKhoaItem?.HocKi,
					KhoiID: this.KhoiItem.KhoiID,
				}, { forceRefresh })
				this.DSLop = _dsLop.filter(x => x.IsNhom === false)
			},
	
			async getHocSinh(forceRefresh = false) {
				this.isLoadingHocSinh = true
				this.DSHocSinhSelected = []
				try {
					const isLopToHop = Number(vueData.CapID) === 3
						&& (this.LopItem?.IsLopToHop === true || Number(this.LopItem?.IsLopToHop) === 1)
					const hocSinhLopSource = isLopToHop
						? { url: 'student/LMS_GetHocSinhLop', params: { LopID: this.LopItem?.LopID, NienKhoa: vueData.NienKhoa } }
						: { url: 'student/LMS_GetHocSinhLopChuNhiem', params: { NienKhoa: vueData.NienKhoa } }
					const [DSHocSinhLop, DSHocSinh_LMS, DSHocSinhLop_LMS, DSNhanXetChuanBiNienKhoaSau] = await fetchBatchPromise([
						{ url: 'lms/HocSinhLop_Get', params: { LopID: this.LopItem?.LopID, NienKhoa: vueData.NienKhoa } },
						{ url: 'student/LMS_GetHocSinh', params: { LopID: this.LopItem?.LopID, NienKhoa: vueData.NienKhoa } },
						hocSinhLopSource,
						{
							url: 'lms/NhanXet_HocSinh_NienKhoaSau_Get_ByLopID',
							params: { LopID: this.LopItem?.LopID, NienKhoa: vueData.NienKhoa },
							opts: { suppressError: true },
						},
					], { forceRefresh })
		
					this.items = this.renderDSHocSinh(DSHocSinhLop, DSHocSinh_LMS, DSHocSinhLop_LMS, DSNhanXetChuanBiNienKhoaSau)
				} finally {
					this.isLoadingHocSinh = false
				}
			},
	
			async insHocSinh() {
				const payload = this.DSHocSinhSelected.map(x => ({
					...x,
					TinhTrang: x.TinhTrangQLHS,
					TenTinhTrang: x.TenTinhTrangQLHS,
				}))
	
				const promise = Promise.all([
					fetchPromise("lms/IO_IN_HocSinh_Ins", { HocSinhObjArr: payload }, { cache: false, suppressError: true }),
					fetchPromise("lms/IO_IN_HocSinhLop_Ins", { HocSinhLopObjArr: payload }, { cache: false, suppressError: true }),
				])
	
				// Tách getHocSinh ra — không để nó kéo dài promise
				promise.then(() => this.getHocSinh(true))
	
				this.snackbarRef.value.showPromise(promise, {
					loadingText: this.isEn ? `Updating ${payload.length} students...` : `Đang cập nhật ${payload.length} học sinh...`,
					onSuccess: () => ({
						text: this.isEn ? `Updated ${payload.length} students successfully!` : `Cập nhật ${payload.length} học sinh thành công!`,
						color: 'success',
						prependIcon: 'mdi-check-circle-outline',
						timeout: 3000,
						timer: 'white',
					}),
					onError: (err) => ({
						text: this.isEn ? `Update failed: ${err?.message ?? 'Unknown error'}` : `Cập nhật thất bại: ${err?.message ?? 'Lỗi không xác định'}`,
						color: 'error',
						prependIcon: 'mdi-alert-circle-outline',
						timeout: 5000,
						timer: 'white',
						reverseTimer: true,
					}),
				})
			},
	
			onOpenModalEditProfile(item) {
				vueData.StudentProfile = { ...item }
				vueData.isOpenModalEditProfile = true
			},
	
			localStorageSetItem(item) {
				if (!localStorage.getItem('tabBottomNavigation')) localStorage.setItem('tabBottomNavigation', 0)
				if (!localStorage.getItem('Semester')) localStorage.setItem('Semester', 1)
				localStorage.setItem('IsPassRoleParent', true)
	
				this.iframeRef.value.openWindow({
					title: (this.isEn ? 'View details: ' : 'Xem chi tiết ') + item.HoTen,
					url: `/ph-report?HocSinhID=${item.HocSinhID}`
				})
			},
	
			formatTinhTrang(text, statusId) {
				if (!text) return this.isEn ? 'None' : 'Không có';
				if (!this.isEn) return text;
				let formatted = String(text);
				if (statusId === 0 || /đang học/i.test(formatted)) return 'Studying';
				if (statusId === 1 || /nghỉ học/i.test(formatted)) return 'Dropped out';
				if (statusId === 2 || /tốt nghiệp/i.test(formatted)) return 'Graduated';
				return formatted
					.replace(/Đang học/gi, 'Studying')
					.replace(/Nghỉ học/gi, 'Dropped out')
					.replace(/Tốt nghiệp/gi, 'Graduated')
					.replace(/Chuyển trường/gi, 'Transferred')
					.replace(/Bảo lưu/gi, 'Deferred')
					.replace(/Không có/gi, 'None');
			},

			renderColorTinhTrang(TinhTrang) {
				if (TinhTrang === 0) return 'green'
				if (TinhTrang === 1) return 'red'
				if (TinhTrang === 2) return 'success'
				return ''
			},
	
			renderDSHocSinh(DSHocSinhLop, DSHocSinh_LMS, DSHocSinhLop_LMS, DSNhanXetChuanBiNienKhoaSau = []) {
				const eduBotHocSinhLop = []
				const currentDSHocSinhLop_LMS = DSHocSinhLop_LMS.filter(x => x.LopID == this.LopItem.LopID)
				const mapNhanXetChuanBi = new Map((DSNhanXetChuanBiNienKhoaSau ?? []).map(x => [x.HocSinhID, x]))
	
				for (const hsl of currentDSHocSinhLop_LMS) {
					const hs = DSHocSinh_LMS.find(x => x.HocSinhID === hsl.HocSinhID)
					if (hs) eduBotHocSinhLop.push({ ...hsl, ...hs })
				}
	
				const uniqueHocSinhID = [...new Set(eduBotHocSinhLop.map(x => x.HocSinhID))]
	
				const items = uniqueHocSinhID.map(id => {
					const hocSinh = DSHocSinhLop.find(x => x.HocSinhID === id)
					const hocSinhLMS = eduBotHocSinhLop.find(x => x.HocSinhID === id)
					const nhanXetChuanBi = mapNhanXetChuanBi.get(id)
					let obj = { isExistInKQHT: !!hocSinh }
	
					if (hocSinh) {
						Object.assign(obj, {
							HSLopID: hocSinh.HSLopID,
							LopID: hocSinh.LopID,
							HocSinhID: hocSinh.HocSinhID,
							HoTen: hocSinh.Ho + ' ' + hocSinh.Ten,
							Ho: hocSinh.Ho,
							Ten: hocSinh.Ten,
							NgaySinh: hocSinh.NgaySinh,
							Nu: hocSinh.Nu,
							TinhTrangKQHT: hocSinh.TinhTrang,
							TenTinhTrangKQHT: hocSinh.TinhTrang === 2 ? (this.isEn ? 'Graduated' : 'Nghỉ học (Tốt nghiệp)') : hocSinh.TenTinhTrang,
							EnglishName: hocSinh.EnglishName,
						})
					}
	
					if (hocSinhLMS) {
						Object.assign(obj, {
							HSLopID: hocSinhLMS.HSLopID,
							LopID: hocSinhLMS.LopID,
							HocSinhID: hocSinhLMS.HocSinhID,
							HoTen: hocSinhLMS.Ho + ' ' + hocSinhLMS.Ten,
							Ho: hocSinhLMS.Ho,
							Ten: hocSinhLMS.Ten,
							NgaySinh: hocSinhLMS.NgaySinh,
							Nu: hocSinhLMS.Nu,
							TinhTrangQLHS: hocSinhLMS.TinhTrang,
							TenTinhTrangQLHS: hocSinhLMS.TinhTrang === 2 ? (this.isEn ? 'Graduated' : 'Nghỉ học (Tốt nghiệp)') : hocSinhLMS.TenTinhTrang,
							SoDanhBo: hocSinhLMS.SoDanhBo,
							CreateUser: hocSinhLMS.CreateUser,
							CreateTime: hocSinhLMS.CreateTime,
							UpdateUser: hocSinhLMS.UpdateUser,
							UpdateTime: hocSinhLMS.UpdateTime,
						})
					}
	
					obj.NhanXet_ChuanBiNienKhoaSau = nhanXetChuanBi?.NhanXet_ChuanBiNienKhoaSau ?? ''
	
					return obj
				})
	
				return items
					.sort((a, b) => {
						const soA = isNaN(a.SoDanhBo) ? a.SoDanhBo : parseInt(a.SoDanhBo)
						const soB = isNaN(b.SoDanhBo) ? b.SoDanhBo : parseInt(b.SoDanhBo)
						if (soA !== soB) return soA < soB ? -1 : 1
						return (a.Ten?.toLowerCase() || '').localeCompare(b.Ten?.toLowerCase() || '')
					})
					.map((x, i) => ({ ...x, STT: i + 1, HoTen: x.Ho + ' ' + x.Ten }))
			},
		},
	}
</script>