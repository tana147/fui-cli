<template>
	<div>
		<v-tabs v-model="TabModel" color="white" background-color="green">
			<v-tab key="Tab_LoaiLy">Loại ly</v-tab>
			<v-tab key="Tab_NhomLoaiLy">Nhóm loại ly</v-tab>
			<v-tab key="Tab_ThietLapDiem">Thiết lập điểm</v-tab>
		</v-tabs>
		<v-tabs-items v-model="TabModel">
			<v-tab-item key="Tab_LoaiLy">
				<uc-tab-loai-ly />
			</v-tab-item>
			<v-tab-item key="Tab_NhomLoaiLy">
				<uc-tab-nhom-loai-ly />
			</v-tab-item>
			<v-tab-item key="Tab_ThietLapDiem">
				<uc-tab-thiet-lap ref="ThietLapDiem" />
			</v-tab-item>
		</v-tabs-items>
	</div>
</template>

<script>
	export default {
		data() {
			return {
				TabModel: 0
			}
		},
		watch: {
			TabModel(newVal) {
				if (newVal === 2) {
					runAction(vueData.getLoaiLy);
				}
			},
		}
	}
</script>