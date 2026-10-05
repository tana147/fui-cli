<template>
	<div class="kham-pha-container pa-0">
		<!-- Header Toolbar Gradient Box (Tiểu học) -->
		<v-card class="pa-4 mb-3 rounded-xl elevation-2 text-white overflow-hidden position-relative" style="background: linear-gradient(135deg, #047857 0%, #10b981 100%);">
			<div class="d-flex align-center justify-space-between">
				<div class="d-flex align-center">
					<!-- Nút Quay lại Kho học liệu -->
					<!-- Học sinh/phụ huynh xem trong iframe của dashboard nên quay lại bằng menu dashboard, không đẩy ra trang kho giáo viên. -->
					<v-btn
						v-if="!isStudentView"
						icon
						variant="tonal"
						color="white"
						size="small"
						class="mr-3 elevation-1"
						@click="goBackToKhoHocLieu"
					>
						<v-icon size="medium">mdi-arrow-left</v-icon>
						<v-tooltip activator="parent" location="bottom">Quay lại Kho học liệu</v-tooltip>
					</v-btn>

					<v-avatar color="white" size="44" class="mr-3 elevation-1">
						<v-icon color="success" size="28">mdi-school</v-icon>
					</v-avatar>
					<div>
						<div class="d-flex align-center ga-2">
							<h2 class="text-h6 font-weight-bold text-white mb-0">Học Liệu Số - {{ TenCap }}</h2>
						</div>
						<p class="text-caption text-white opacity-90 mb-0">Danh sách sách giáo khoa và học liệu số dành cho cấp Tiểu học (Khối 1 - Khối 5)</p>
					</div>
				</div>
			</div>
		</v-card>

		<!-- Expansion Panels cho các Khối Tiểu học -->
		<v-expansion-panels v-model="panel" selected-class="bg-success text-white">
			<v-expansion-panel v-for="(khoi, index) in DSKhoi" :key="khoi.id" class="rounded-xl mb-2 elevation-1 overflow-hidden">
				<v-expansion-panel-title class="font-weight-bold">
					<div class="d-flex align-center">
						<v-icon :color="getIconColor(index)" class="mr-3" size="large">
							{{ getIcon(khoi.name, index) }}
						</v-icon>
						<span class="text-subtitle-1 font-weight-bold text-slate-800">{{ khoi.name }}</span>
					</div>
				</v-expansion-panel-title>
				<v-expansion-panel-text style="min-height: 300px; max-height: calc(100vh - 220px); overflow: auto !important">
					<v-card class="pa-2 border-0 shadow-none">
						<v-row dense>
							<v-col v-for="sach in DSHocLieu" :key="sach.HocLieuID" cols="6" sm="4" md="3" lg="2" xl="2" class="pa-2">
								<uc-sach-card :item="sach"></uc-sach-card>
							</v-col>
						</v-row>
					</v-card>
				</v-expansion-panel-text>
			</v-expansion-panel>
		</v-expansion-panels>
	</div>
</template>

<script>
	export default {
		props: [],
		data() {
			const urlParams = new URLSearchParams(window.location.search)
			const khoiIdFromStudentContext = urlParams.get('khoiid') || urlParams.get('KhoiID') || vueData.KhoiID || vueData.khoiid

			return {
				vueData,
				panel: undefined,
				isLoading: false,
				DSHocLieu: [],
				// Dùng khoiid làm dấu vết nguồn dashboard; không suy luận chỉ từ GroupID vì nhân viên/phụ huynh có thể dùng chung một tài khoản trung gian.
				isStudentView: Number(khoiIdFromStudentContext) > 0,
				canGoBack: false
			}
		},
		mounted() {
			this.canGoBack = window.history.length > 1
			//mở expand để gọi vô watch
			this.panel = [0]
		},
		computed: {
			DSKhoi() {
				// Nếu KhoiID null / undefined / 0 ⇒ lấy tất cả khối theo cấp
				if (!vueData.KhoiID) {
					return vueData.DSKhoi_Init.filter(x => x.CapID === vueData.CapID)
				}
	
				// Ngược lại ⇒ lọc theo CapID + KhoiID
				return vueData.DSKhoi_Init.filter(
					x => x.CapID === vueData.CapID && x.id === vueData.KhoiID
				)
			},
			TenCap: function () {
				let text = ''
				if (vueData.CapID === 1) text = 'Tiểu học'
				if (vueData.CapID === 2) text = 'Trung học cơ sở'
				if (vueData.CapID === 3) text = 'Trung học phổ thông'
				return text
			}
		},
		watch: {
			panel: function (panel) {
				if (panel === undefined) return
				this.isLoading = true
				const khoi = this.DSKhoi[panel]
				ajaxCALL('lms/FP_HocLieu_GetAll', {
					PageNumber: 1,
					PageSize: 100,
					KhoiID: khoi.id,
					MonHocID: 0,
					BoSachID: 0,
					Loai: 'HOC_LIEU',
				}, res => {
					this.DSHocLieu = res.data
					this.isLoading = false
				})
	
			}
		},
		methods: {
			goBackToKhoHocLieu() {
				// Nút này luôn quay về danh mục Kho học liệu; không dùng history.back() vì lịch sử trước đó có thể là trang chi tiết học liệu.
				redirect('/hoc-lieu-so');
			},
			goBack() {
				window.history.back()
			},
			getIcon(name, index) {
				// Icons dựa trên tên khối/môn
				const iconMap = {
					'Khối 1': 'mdi-numeric-1-circle',
					'Khối 2': 'mdi-numeric-2-circle',
					'Khối 3': 'mdi-numeric-3-circle',
					'Khối 4': 'mdi-numeric-4-circle',
					'Khối 5': 'mdi-numeric-5-circle',
					'Khối 6': 'mdi-numeric-6-circle',
					'Khối 7': 'mdi-numeric-7-circle',
					'Khối 8': 'mdi-numeric-8-circle',
					'Khối 9': 'mdi-numeric-9-circle',
					'Khối 10': 'mdi-alpha-x-circle',
					'Khối 11': 'mdi-alpha-x-circle',
					'Khối 12': 'mdi-alpha-x-circle',
					'AI': 'mdi-robot',
					'Âm nhạc': 'mdi-music',
					'Ngoại ngữ': 'mdi-translate',
					'Công nghệ': 'mdi-cog',
					'Công nghiệp': 'mdi-factory',
					'Địa': 'mdi-earth',
					'English Central': 'mdi-flag-variant',
					'EC1': 'mdi-school-outline',
					'GDCD': 'mdi-account-heart',
					'Nội dung giáo dục của địa phương': 'mdi-map-marker',
					'GDQP': 'mdi-shield-star',
					'Hoạt động trải nghiệm, hướng nghiệp': 'mdi-compass'
				}
	
				// Nếu có icon cụ thể thì dùng, không thì dùng icon dự phòng
				if (iconMap[name]) {
					return iconMap[name]
				}
	
				// Icons dự phòng
				const fallbacks = [
					'mdi-bookmark', 'mdi-star', 'mdi-heart', 'mdi-diamond', 'mdi-crown',
					'mdi-trophy', 'mdi-medal', 'mdi-award', 'mdi-flag', 'mdi-target'
				]
				return fallbacks[index % fallbacks.length]
			},
	
			getIconColor(index) {
				// Màu tương ứng với từng panel
				const colors = [
					'#10B981', '#0EA5E9', '#F59E0B', '#8B4513', '#A855F7',
					'#EC4899', '#6366F1', '#14B8A6', '#EF4444', '#22C55E'
				]
				return colors[index % colors.length]
			}
		}
	}
</script>