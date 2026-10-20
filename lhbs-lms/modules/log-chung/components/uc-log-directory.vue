<template>
	<div>
		<v-text-field
			v-model="keyword"
			class="mb-4"
			label="Tìm trang log"
			placeholder="Nhập tên trang hoặc nội dung cần tìm"
			prepend-inner-icon="mdi-magnify"
			variant="outlined"
			density="compact"
			clearable
			hide-details
		></v-text-field>

		<v-list lines="two" density="comfortable">
				<template v-for="(group, groupIndex) in groupedItems" :key="group.category">
					<v-list-subheader class="font-weight-bold">
						{{ group.category }}
					</v-list-subheader>

					<v-list-item
						v-for="item in group.items"
						:key="item.url"
						:title="item.title"
						:subtitle="item.description"
						class="px-4"
					>
						<template v-slot:prepend>
							<v-avatar color="primary" variant="tonal">
								<v-icon>{{ item.icon }}</v-icon>
							</v-avatar>
						</template>

						<template v-slot:append>
							<v-btn
								prepend-icon="mdi-open-in-new"
								color="primary"
								variant="text"
								@click="openLog(item)"
							>
								Mở
							</v-btn>
						</template>
					</v-list-item>

					<v-divider v-if="groupIndex < groupedItems.length - 1" class="mx-4"></v-divider>
				</template>
			</v-list>

		<v-alert v-if="!groupedItems.length" class="mt-4" type="info" variant="tonal">
			Không tìm thấy trang log phù hợp.
		</v-alert>
	</div>
</template>

<script>
	export default {
		inject: ['iframeRef'],
		data() {
			return {
				keyword: '',
				// Hub chỉ giữ metadata điều hướng; nội dung log vẫn ở module gốc và mở trong iframe của FUI.
				logItems: [
					{
						category: 'Thời khóa biểu',
						title: 'Log xem thời khóa biểu',
						description: 'Thống kê lượt xem thời khóa biểu theo thiết bị, lớp và niên khóa.',
						icon: 'mdi-monitor-eye',
						url: '/lms-teacher-log-shedule',
					},
					{
						category: 'Điểm số',
						title: 'Lịch sử nhập điểm',
						description: 'Tra cứu lịch sử nhập điểm theo niên khóa, cấp học, lớp, môn học và khoảng thời gian.',
						icon: 'mdi-history',
						url: '/log-diem-tong-hop',
					},
					{
						category: 'Sổ GVCN',
						title: 'Lịch sử chỉnh sửa Sổ GVCN',
						description: 'Tra cứu các lần chỉnh sửa nội dung và trạng thái trong Sổ GVCN.',
						icon: 'mdi-notebook-outline',
						url: '/so-gvcn-lich-su-chinh-sua',
					},
				],
			}
		},
		computed: {
			// Lọc theo cả nhóm, tên và mô tả để khi số lượng trang tăng vẫn tìm được nhanh.
			filteredItems() {
				const normalizedKeyword = this.keyword.trim().toLowerCase()
				if (!normalizedKeyword) return this.logItems

				return this.logItems.filter((item) => {
					return [item.category, item.title, item.description].some((value) => {
						return value.toLowerCase().includes(normalizedKeyword)
					})
				})
			},
			// Gom theo category để danh sách dài vẫn có điểm neo thị giác, không biến thành nhiều card rời.
			groupedItems() {
				const groups = []
				this.filteredItems.forEach((item) => {
					let group = groups.find((currentGroup) => currentGroup.category === item.category)
					if (!group) {
						group = { category: item.category, items: [] }
						groups.push(group)
					}
					group.items.push(item)
				})
				return groups
			},
		},
		methods: {
			// Giữ niên khóa trong URL để module con nhận được dù không còn thanh menu riêng.
			openLog(item) {
				const separator = item.url.includes('?') ? '&' : '?'
				const nienKhoa = encodeURIComponent(String(vueData.NienKhoa || ''))
				this.iframeRef.value.openWindow({
					title: item.title,
					url: `${item.url}${separator}NienKhoa=${nienKhoa}`,
				})
			},
		},
	}
</script>