<template>
	<v-container class="my-thesis-module">
		<v-card class="mb-2 rounded-xs text-white py-1 px-3 banner-container" flat>
			<!-- Decorative background circles for depth -->
			<div class="banner-circle-top">
			</div>
			<div class="banner-circle-bottom">
			</div>

			<div class="d-flex align-center position-relative banner-content">
				<v-avatar size="32" class="mr-2 rounded-xs banner-icon-bg">
					<v-icon color="white" size="18">mdi-school-outline</v-icon>
				</v-avatar>
				<div>
					<h3 class="text-subtitle-1 font-weight-bold mb-0 banner-title">{{ bannerTitle }}</h3>
					<span class="text-caption banner-subtitle">{{ bannerDescription }}</span>
				</div>
			</div>
		</v-card>

		<uc-student-info v-if="detailInfo" :detailInfo="detailInfo" />

		<uc-main-view v-if="rootFlow && rootFlow.length > 0" :rootflow="rootFlow" :studentProcess="studentProcess"
			:studentId="studentId" :apiFile="apiFile" :urlReadFile="urlReadFile" @on-reload="initData" />
	</v-container>
</template>

<script>
	export default {
		name: "uc-main-page",
	data() {
		return {
			studentProcess: [],
			rootFlow: [],
			detailInfo: null,
			studentId: null,
			apiFile: '',
			urlReadFile: ''
		}
	},
		computed: {
			bannerTitle() {
				if (this.studentProcess && this.studentProcess.length > 0) {
					const pid = this.studentProcess[0].Process_ID;
					if (pid === 4) {
						return "Đề án thạc sĩ của tôi";
					}
				}
				return "Luận văn thạc sĩ của tôi";
			},
			bannerDescription() {
				if (this.studentProcess && this.studentProcess.length > 0) {
					const pid = this.studentProcess[0].Process_ID;
					if (pid === 4) {
						return "Quản lý tiến độ và nộp báo cáo đề án tốt nghiệp (Định hướng ứng dụng)";
					}
				}
				return "Quản lý tiến độ và nộp báo cáo luận văn tốt nghiệp (Định hướng nghiên cứu)";
			}
		},
		mounted() {
		this.apiFile = window.vueData?.v_Set?.apiFile || '';
		this.urlReadFile = window.vueData?.v_Set?.urlReadFile || '';
		this.initData();
	},
	methods: {
		async initData() {
			try {
				const userID = window.vueData?.user?.UserID;
				if (!userID) return;
				this.studentId = userID;

				// Lấy StudentProcess
				this.studentProcess = await ajaxCALLPromise("/Student_Process_Get", { Student_ID: userID, IsFull: 0 });
				const processStudentID = this.studentProcess.length > 0 ? this.studentProcess[0].Process_Student_ID : 0;

				// Lấy RootFlow
				this.rootFlow = await ajaxCALLPromise("/Get_RootFlow", {
					StudentID: userID,
					Process_Student_ID: processStudentID,
					Process_Tree: "1"
				});

				// Lấy StudentInfo
				const infoRes = await ajaxCALLPromise("/StudentInfo_GetById", { Student_ID: userID });
				if (infoRes && infoRes.length > 0) {
					const info = infoRes[0];
					if (window.vueData?.user) {
						info.HoSV = window.vueData.user.LastName || '';
						info.TenSV = window.vueData.user.FirstName || '';
					}
					this.detailInfo = info;
				}
			} catch (error) {
				console.error("Lỗi khi initData:", error);
			}
		}
	}
	}
</script>