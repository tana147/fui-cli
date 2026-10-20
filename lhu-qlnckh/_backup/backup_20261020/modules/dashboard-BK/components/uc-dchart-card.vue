<template>
	<v-card :style="{'background-color': vueData.mode ? vueData.colorMode.dark.tertiary : 'white'}" :class="elevation">
		<v-card-title :class="vueData.mode ? 'white--text' : 'primary--text'"
			style="font-size:18px;word-break: break-word;" class="title-mobile">{{title}}
			<v-chip v-if="detailTitle" class="ml-3" :color=" vueData.mode ? 'white' : 'primary'"
				:style="{color: vueData.mode ? 'black' : 'white'}"> <span>{{detailTitle}}</span></v-chip>
			<div class="d-flex flex-column align-start ">
				<div>
					<slot name="leftTitle"> </slot>
				</div>
			</div>
			<v-spacer></v-spacer>
			<div class="d-flex flex-column align-end ">
				<div class="reponsive-button-rightTitle-mobile">
					<slot name="rightTitle"> </slot>
				</div>
				<div class="reponsive-checkbox-rightTitle-mobile">
					<slot name="checkboxShowNumber"> </slot>
				</div>
			</div>
			<slot name="renderExcel"></slot>

		</v-card-title>

		<v-card-text class="mt-5">
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
		},
		data() {
			return {
				search: ""
			}
		},
		mounted() { },
		computed: {},
		watch: {},
		methods: {},
	}
</script>