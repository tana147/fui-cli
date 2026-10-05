<template>
	<div>
		<v-toolbar color="info" dense dark>
			<h3>Luận văn của tôi</h3>
		</v-toolbar>
		<graduate-route :rootflow="rootflow" />
	</div>
</template>

<script>
	export default {
		props: ["rootflow"],
		data() {
			return {
				tab: null
			}
		},
		computed: {},
		watch: {},
		methods: {},
	}
</script>