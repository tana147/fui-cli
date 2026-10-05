<template>
	<v-card outlined class="rounded-xs">
		<v-card-title class="py-2 px-3 d-flex align-center justify-space-between">
			<div v-if="!isCustom" class="d-flex flex-column align-start flex-grow-1">
				<p class="mb-0 text-subtitle-2 black--text dashboard-word-break">
					{{ title ?? '' }}
				</p>
				<p class="mt-0 mb-0 font-weight-bold primary--text text-h6">
					{{ description ?? '' }}
				</p>
			</div>
			<div v-if="isCustom" class="d-flex flex-row align-center justify-space-between flex-grow-1 ga-2">
				<p class="mb-0 text-subtitle-2 black--text dashboard-word-break">
					{{ title ?? '' }}
				</p>
				<p class="mt-0 mb-0 font-weight-bold primary--text text-h6">
					{{ description ?? '' }}
				</p>
			</div>
			<v-avatar v-if="!isCustom" size="36" class="dashboard-stat-avatar--primary dashboard-cursor-default">
				<v-icon size="20" color="primary">{{ trailingIcon ?? 'mdi-chart-box-outline' }}</v-icon>
			</v-avatar>
		</v-card-title>
	</v-card>
</template>

<script>
	export default {
		props: ["title", "description", "trailingIcon", "styleDescription", "styleTitle", "styleCardTitle", "isCustom"]
	}
</script>