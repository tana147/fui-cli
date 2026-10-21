<template>
	<div v-if="!isRedirecting">
		<v-toolbar color="info" dense dark>
			<h3>Luận văn của tôi</h3>
		</v-toolbar>
		<graduate-route :rootflow="rootflow" />
	</div>
	<div v-else class="d-flex align-center justify-center pa-8">
		<v-progress-circular indeterminate color="primary" class="mr-3" />
		<span>Đang chuyển hướng sang Luận án Tiến sĩ...</span>
	</div>
</template>

<script>
	export default {
		props: ["rootflow"],
		data() {
			const classId = window.vueData?.ClassID || window.vueData?.user?.ClassID;
			const isPhdClass = Boolean(classId && /^\d{2}N/i.test(String(classId).trim()));
			return {
				tab: null,
				isRedirecting: isPhdClass,
			}
		},
		computed: {},
		watch: {},
		mounted() {
			this.checkAndRedirectPhd();
		},
		methods: {
			async checkAndRedirectPhd(retryCount = 0) {
				try {
					const userID = window.vueData?.user?.UserID;
					if (!userID) {
						if (retryCount < 10) {
							setTimeout(() => this.checkAndRedirectPhd(retryCount + 1), 200);
						}
						return;
					}

					// 1. Kiểm tra nhanh qua mã lớp (ClassID / LopID) nếu có ký tự 'N' ở vị trí đào tạo Tiến sĩ
					const classId = window.vueData?.ClassID || window.vueData?.user?.ClassID;
					if (classId) {
						const str = String(classId).trim().toUpperCase();
						const match = str.match(/^\d{2}([A-Z])/);
						const typeChar = match ? match[1] : str.charAt(2);
						if (typeChar === 'N') {
							this.isRedirecting = true;
							window.location.href = '/ts-luan-an-cua-toi';
							return;
						}
					}

					// 2. Kiểm tra chính xác qua API thông tin học viên (HeDaoTao)
					const res = await ajaxCALLPromise("/StudentInfo_GetById", { Student_ID: userID });
					if (res && res.length > 0) {
						const info = res[0];
						if (info?.HeDaoTao && info.HeDaoTao.toLowerCase() === 'phd') {
							this.isRedirecting = true;
							window.location.href = '/ts-luan-an-cua-toi';
							return;
						}
					}
				} catch (err) {
					console.error("Lỗi kiểm tra hệ đào tạo NCS:", err);
				}
			}
		},
	}
</script>