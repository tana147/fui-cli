<template>
	<v-container>
		<master-route :rootflow="rootflow" />
		<!-- <doctor-route v-else :fullflow="fullflow" :rootflow="rootflow" /> -->
	</v-container>
</template>

<script>
	export default {
		props: ["fullflow", "rootflow"],
		data() {
			return {
				files: [],
				isPassPermit: true, //duyet de tai sau khi dat du dieu kien
				state: 0,
				fileRules: [
					v => !!v || 'Không được để trống',
					v => (v && v.length > 3) || 'Phải nộp ít nhất 4 files',
					v => {
						const validTypes = ['application/pdf', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
							'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'];
						for (let i = 0; i < v.length; i++) { if (!validTypes.includes(v[i].type)) { return 'Loại tệp không hợp lệ'; } } return
						true;
					}, v => {
						// Kiểm tra kích thước tệp
						const maxSize = 5 * 1024 * 1024; // 5MB
						for (let i = 0; i < v.length; i++) {
							if (v[i].size > maxSize) {
								return 'Kích thước tệp quá lớn';
							}
						}
						return true;
					}
				],
			}
		},
		computed: {},
		watch: {},
		methods: {
			checkValidate() {
				let fileValid = true
				fileValid = this.fileRules.every(rule => rule(this.files) === true)
				return fileValid
			},
			deleteChip(index) {
				this.files.splice(index, 1);
			},
			submitBtn() {
				//
				this.isPassPermit = true
				Vue.$toast.success(`Yêu cầu xét duyệt thành công`, { position: 'bottom-right' })
			}
		},
	}
</script>