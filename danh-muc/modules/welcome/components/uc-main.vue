<template>
	<z-layout>
		<div style="height: calc(100vh - 48px); width: 100%">
			<v-empty-state image="/_cdn/danh-muc/logo-2025.png"
				title="HỆ THỐNG QUẢN LÝ DANH MỤC">
				<template v-slot:text>
					Chào mừng <b>{{vueData?.user?.FirstName}} {{vueData?.user?.LastName}}</b> bạn đã đến với hệ thống
				</template>
			</v-empty-state>
		</div>

	</z-layout>
</template>

<script>
	export default {
		props: [],
		data() {
			return {
				vueData
			}
		},
		mounted() { },
		computed: {},
		watch: {},
		methods: {},
	}
</script>