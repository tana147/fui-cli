<template>
	<iframe :src="src" class="uc-iframe" style="
		display: block;
		width: 100%;
		height: 100dvh;
		border: none;
	"></iframe>
</template>

<script>
	export default {
		props: {
			HocSinh: Object
		},
		computed: {
			src() {
				const capId = this.HocSinh?.CapID || '';
				const khoiId = this.HocSinh?.KhoiID || this.HocSinh?.MaKhoi || '';
				return `/kham-pha?capid=${capId}&khoiid=${khoiId}`;
			}
		}
	}
</script>