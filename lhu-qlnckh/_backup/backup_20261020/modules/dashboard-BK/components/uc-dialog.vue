<template>
	<v-dialog v-model="value" max-width="1000px" persistent eager>
		<v-card :style="{'background-color': vueData.mode ? vueData.colorMode.dark.tertiary : 'white'}">
			<v-card-title :class="vueData.mode ? 'white--text' : 'primary--text'">
				{{ title}}
				<v-spacer></v-spacer>
				<v-icon :color="vueData.mode ? 'white' : 'black'" @click="$emit('input', false)">mdi-close</v-icon>
			</v-card-title>
			<v-card-text :class="vueData.mode ? 'white--text' : 'black--text'">
				<slot name="renderBody"></slot>
			</v-card-text>
			<v-card-actions>
				<v-spacer></v-spacer>
				<uc-excel-btn v-if="isExcel" @click="jsonToExcel({data: itemToExcel}) "></uc-excel-btn>
				<v-btn @click="$emit('input', false)">Đóng</v-btn>
			</v-card-actions>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
		props: {
			value: {
				type: Boolean,
			},
			isExcel: {
				type: Boolean,
				default: false,
			},
			dialog: {
				type: Boolean,
				default: false,
			},
			title: {
				type: String,
				default: ""
			},
			itemToExcel: null
		},
		data() {
			return {}
		},
		mounted() { },
		computed: {},
		watch: {},
		methods: {},
	}
</script>