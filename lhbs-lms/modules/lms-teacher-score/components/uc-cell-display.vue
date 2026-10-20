<template>
	<!-- Keep the empty-state dash as the sibling v-else so graded cells only show their status. -->
	<!-- Native title avoids mounting a Vuetify tooltip for every question cell in the report grid. -->
	<span v-if="statusInfo" :title="statusInfo.title" class="d-inline-flex align-center">
		<v-icon v-if="statusInfo.icon" :color="statusInfo.color" size="small">{{ statusInfo.icon }}</v-icon>
		<span v-if="statusInfo.text" class="ml-1 font-weight-medium" :style="{ color: statusInfo.color }">
			{{ statusInfo.text }}
		</span>
	</span>
	<span v-else class="text-medium-emphasis">—</span>
</template>

<script>
	export default {
		props: {
		cellData: {
			type: String,
			default: ''
		}
	},
	computed: {
		statusInfo() {
			if (!this.cellData) return null;
			try {
				const data = JSON.parse(this.cellData);
				switch (data.status) {
					case 'CORRECT': return { icon: 'mdi-check', color: '#4CAF50', title: 'Đúng' };
					case 'INCORRECT': return { icon: 'mdi-close', color: '#F44336', title: 'Sai' };
					case 'GRADED': return { text: data.score.toFixed(2), color: '#2196F3', title: `Đã chấm: ${data.score}đ` };
					case 'PENDING': return { icon: 'mdi-pencil', color: '#FB8C00', title: 'Chờ chấm' };
					case 'NOT_ANSWERED': return { icon: 'mdi-minus', color: '#9E9E9E', title: 'Không trả lời' };
					default: return null;
				}
			} catch (e) {
				return null;
			}
		}
	}
	}
</script>