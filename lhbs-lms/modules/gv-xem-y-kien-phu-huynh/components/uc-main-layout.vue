<template>
	<Global>
		<template #header>
			<v-card>
				<v-card-title class="d-flex align-center flex-wrap ga-2">
					<span>{{ TitlePage }}<span v-if="vueData.CapID"> • {{ TitleCap }}</span></span>
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
						<v-col cols="12" sm="4">
							<v-select
								:key="'lop_' + isEn"
								v-model="LopItem"
								:label="isEn ? 'Select class' : 'Chọn lớp'"
								:items="DSLop"
								:item-title="formatLopTitle"
								item-value="LopID"
								return-object
								:no-data-text="isEn ? 'No data available' : 'Chưa có dữ liệu'"
							>
								<template #selection="{ item }">
									<span>{{ formatLopTitle(item) }}</span>
								</template>
								<template #item="{ props, item }">
									<v-list-item v-bind="props" :title="formatLopTitle(item)"></v-list-item>
								</template>
							</v-select>
						</v-col>
						<v-col cols="12" sm="4">
							<v-select
								:key="'thang_' + isEn"
								v-model="ThangItem"
								:label="isEn ? 'Select month' : 'Chọn tháng'"
								:items="DSLop_NhanXetThang"
								:item-title="formatThangTitle"
								item-value="Lop_NhanXetThangID"
								return-object
								:disabled="!LopItem"
								:no-data-text="isEn ? 'No data available' : 'Chưa có dữ liệu'"
							>
								<template #selection="{ item }">
									<span>{{ formatThangTitle(item) }}</span>
								</template>
								<template #item="{ props, item }">
									<v-list-item v-bind="props" :title="formatThangTitle(item)"></v-list-item>
								</template>
							</v-select>
						</v-col>
						<v-col cols="12" sm="4" class="d-flex align-center ga-2 flex-wrap">
							<v-btn variant="outlined" color="primary" :loading="loading" @click="onRefresh">
								<v-icon start>mdi-reload</v-icon>{{ isEn ? 'Refresh' : 'Làm mới' }}
							</v-btn>
						</v-col>
					</v-row>
				</v-card-text>
			</v-card>
		</template>

		<v-divider />

		<GlobalDataTable :headers="headers" :items="items" item-value="HocSinhID" items-per-page="-1"
			hide-default-footer hover>
			<template #item.hocSinh="{ item }">
				<uc-info-student :item="item" />
			</template>
			<template #item.PHConfirm="{ item }">
				<v-chip v-if="item.PHConfirm !== null && item.PHConfirm !== undefined" size="x-small"
					:color="item.PHConfirm ? 'success' : 'default'" variant="tonal">
					{{ item.PHConfirm ? (isEn ? 'Confirmed' : 'Đã xác nhận') : (isEn ? 'Not confirmed' : 'Chưa xác nhận') }}
				</v-chip>
				<span v-else class="text-medium-emphasis text-body-2">—</span>
			</template>
			<template #item.PHConfirmTime="{ item }">
				<span class="text-body-2">{{ item.PHConfirmTime || '—' }}</span>
			</template>
			<template #item.LuotXem="{ item }">
				<span class="text-body-2 font-weight-medium">{{ item.LuotXem ?? 0 }}</span>
			</template>
			<template #item.YKienPhuHuynh="{ item }">
				<span class="text-body-2" style="white-space: pre-wrap;">{{ item.YKienPhuHuynh || '—' }}</span>
			</template>
			<template #no-data>
				<div class="d-flex flex-column align-center justify-center py-12 text-medium-emphasis">
					<v-icon size="48" class="mb-3 opacity-40">mdi-comment-question-outline</v-icon>
					<p class="text-body-2">
						{{ isEn ? 'Select class and month to view parent feedback' : 'Chọn lớp và tháng để xem ý kiến phụ huynh' }}
					</p>
				</div>
			</template>
		</GlobalDataTable>
	</Global>
</template>

<script>
	export default {
		inject: ['snackbarRef', 'iframeRef', 'confirmRef'],
		data() {
			return {
				vueData,
				isEn: JSON.parse(localStorage.getItem('IsLanguage')) ?? false,
				loading: false,
				DSLop: [],
				DSLop_NhanXetThang: [],
				LopItem: null,
				ThangItem: null,
				items: [],
			}
		},
		computed: {
			headers() {
				return [
					{ title: this.isEn ? 'Student' : 'Học sinh', key: 'hocSinh', align: 'center', sortable: false },
					{ title: this.isEn ? 'Parent Confirmation' : 'Phụ huynh xác nhận', key: 'PHConfirm', align: 'center' },
					{ title: this.isEn ? 'Confirmation Time' : 'Thời gian xác nhận', key: 'PHConfirmTime', align: 'center' },
					{ title: this.isEn ? 'Views' : 'Lượt xem', key: 'LuotXem', align: 'right' },
					{ title: this.isEn ? 'Parent Feedback' : 'Ý kiến phụ huynh', key: 'YKienPhuHuynh', sortable: false },
				]
			},
			TitleCap() {
				const capId = parseInt(vueData.CapID)
				if (Number.isNaN(capId)) return ''
				if (this.isEn) {
					if (capId === 1) return 'Primary'
					if (capId === 2) return 'Secondary'
					if (capId === 3) return 'High School'
					return 'Level ' + capId
				}
				return typeof renderText === 'function' ? renderText(capId) : ('Cấp ' + capId)
			},
			TitlePage() {
				if (this.isEn) {
					return 'Parent Feedback'
				}
				return typeof getTitlePageByURL === 'function'
					? getTitlePageByURL(window.location.pathname + window.location.search)
					: 'Xem ý kiến phụ huynh'
			},
		},
		watch: {
			'vueData.NienKhoa'() {
				this.LopItem = null
				this.ThangItem = null
				this.DSLop_NhanXetThang = []
				this.items = []
				this.getLop(true)
			},
			LopItem(v) {
				this.ThangItem = null
				this.DSLop_NhanXetThang = []
				this.items = []
				if (v) this.getNhanXetThang()
			},
			ThangItem(v) {
				this.items = []
				if (v) this.getYKien()
			},
		},
		mounted() {
			window.addEventListener('storage', this.handleStorageChange)
			this.getLop()
		},
		beforeUnmount() {
			window.removeEventListener('storage', this.handleStorageChange)
		},
		methods: {
			setLanguage(val) {
				this.isEn = val
				if (this.$i18n) this.$i18n.locale = val ? 'en' : 'vi'
				localStorage.setItem('IsLanguage', JSON.stringify(val))
			},
			handleStorageChange(event) {
				if (event.key === 'IsLanguage') {
					this.isEn = JSON.parse(event.newValue) ?? false
				}
			},
			formatLopTitle(item) {
				if (!item) return ''
				const raw = (item && item.raw) ? item.raw : item
				return raw.TenLop || ''
			},
			formatThangTitle(item) {
				if (!item) return ''
				const raw = (item && item.raw) ? item.raw : item
				const title = raw.Thang_HienThi || raw.TenThang || ''
				if (!this.isEn) return title
				return String(title)
					.replace(/Tháng\s*/gi, 'Month ')
					.replace(/Cuối\s*năm/gi, 'End of year')
					.replace(/Đầu\s*năm/gi, 'Beginning of year')
					.replace(/Giữa\s*năm/gi, 'Mid-year')
					.replace(/Học\s*kì\s*1|Học\s*kỳ\s*1/gi, 'Semester 1')
					.replace(/Học\s*kì\s*2|Học\s*kỳ\s*2/gi, 'Semester 2')
					.replace(/Cả\s*năm/gi, 'Full year')
			},
			async getLop(forceRefresh = false) {
				const res = await fetchPromise('lms/Lop_Get_By_CapID', {
					NienKhoa: vueData.NienKhoa,
					CapID: vueData.CapID,
				}, { forceRefresh })
				this.DSLop = res ?? []
			},
			async getNhanXetThang(forceRefresh = false) {
				if (!this.LopItem?.LopID) return
				const res = await fetchPromise('lms/NhanXetThang_Lop_Get', {
					NienKhoa: vueData.NienKhoa,
					LopID: this.LopItem.LopID,
				}, { forceRefresh })
				this.DSLop_NhanXetThang = res ?? []
			},
			async getYKien(forceRefresh = false) {
				if (!this.LopItem?.LopID || !this.ThangItem?.Lop_NhanXetThangID) return
				this.loading = true
				try {
					const res = await fetchPromise('lms/HocSinhYKienThang_Get_By_LopID_Lop_NhanXetThangID', {
						LopID: this.LopItem.LopID,
						Lop_NhanXetThangID: this.ThangItem.Lop_NhanXetThangID,
						NienKhoa: vueData.NienKhoa,
					}, { forceRefresh })
					this.items = res ?? []
				} finally {
					this.loading = false
				}
			},
			async onRefresh() {
				if (!this.LopItem) {
					await this.getLop(true)
					return
				}
				if (!this.ThangItem) {
					await this.getNhanXetThang(true)
					return
				}
				await this.getYKien(true)
			},
		},
	}
</script>