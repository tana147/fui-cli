<template>
	<div class="my-4 text-center">
		<v-btn class="ma-2" color="primary" elevation="0"
			:href="'/hoa-don-tra-mon?chid='+ vueData.CuaHangID">
			<v-icon left>mdi-calendar-text</v-icon>Màn hình chờ
		</v-btn>
		<v-btn v-for="b in list" class="ma-2" color="primary" elevation="0" :href="'/bar-bep?chid='+ b.CuaHangID +'&bepid='+ b.KhuCheBienID">
			<v-icon left>mdi-bookmark-box-outline</v-icon>{{b.TenKhuCheBien}}
		</v-btn>
	</div>
</template>

<script>
	export default {
		props: ["list"],
		data() {
			return {}
		},
		mounted() { },
		computed: {},
		watch: {},
		methods: {},
	}
</script>