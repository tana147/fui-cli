<template>
	<v-card outlined class="rounded-xs" :class="elevation">
		<v-card-title class="py-2 px-4 primary--text text-subtitle-1 font-weight-bold dashboard-word-break title-mobile">
			<span>{{ title }}</span>
			<v-chip v-if="detailTitle" small class="ml-2 white--text" color="primary">
				<span>{{ detailTitle }}</span>
			</v-chip>
			<div class="d-flex flex-column align-start">
				<div>
					<slot name="leftTitle"></slot>
				</div>
			</div>
			<v-spacer></v-spacer>
			<div class="d-flex flex-column align-end">
				<div class="reponsive-button-rightTitle-mobile">
					<slot name="rightTitle"></slot>
				</div>
				<div class="reponsive-checkbox-rightTitle-mobile">
					<slot name="checkboxShowNumber"></slot>
				</div>
			</div>
			<slot name="renderExcel"></slot>
		</v-card-title>
		<v-divider></v-divider>
		<v-card-text class="pa-3">
			<slot name="renderBody"></slot>
		</v-card-text>
	</v-card>
</template>

<script>
	export default {
		props: {
		title: {
			type: String,
			default: ""
		},
		detailTitle: String,
		elevation: String
	}
	}
</script>