<template>
	<v-container fluid class="pa-0 ma-0">
		<!-- <v-row justify="center">
			<v-col cols="12" md="9">
				<uc-thong-ke :reload="reloadData"></uc-thong-ke>
			</v-col>
		</v-row> -->
		<v-row  class="" justify="center">
			<v-col cols="12">
				
					<uc-ds @refresh="refresh"></uc-ds>
			</v-col>
		</v-row>
	</v-container>
</template>

<script>
	export default {
		props: [],
		data() {
			return {}
		},
		mounted() {},
		computed: {},
		watch: {},
		methods: {},
	}
</script>