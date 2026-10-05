<template>
	<v-card class="mt-4">
		<v-card-text class="text-center py-8">
			<v-icon size="64" color="grey">mdi-table-off</v-icon>
			<p class="text-h6 mt-4">{{ text || (isEn ? 'No data available' : 'Chưa có dữ liệu') }}</p>
			<p class="text-grey">{{ subtext || (isEn ? 'Please select criteria to view data' : 'Vui lòng chọn các tiêu chí và nhấn Tìm kiếm') }}</p>
		</v-card-text>
	</v-card>
</template>

<script>
	export default {
		props: ['text', 'subtext'],
		data() {
			// IsLanguage được lưu dưới dạng JSON trong localStorage; fallback false để mặc định hiển thị tiếng Việt.
			const isEn = JSON.parse(localStorage.getItem('IsLanguage')) ?? false;
			return {
				isEn
			}
		},
		mounted() {
			window.addEventListener('storage', (e) => {
				if (e.key === 'IsLanguage') {
					this.isEn = JSON.parse(e.newValue) ?? false;
				}
			});
		},
		computed: {},
		watch: {},
		methods: {},
	}
</script>