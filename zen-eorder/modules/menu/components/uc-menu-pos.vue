<template>
	<div style="height: calc(100vh); width: calc(-487px + 100vw); overflow: hidden;">
		<div ref="menuDiv" class="custom-img-menu" alt="Menu" style="width: 1282px; height: 1080px" :style="{
                backgroundImage: 'url(' + CTCuaHang.Menu_Url + ')',
                backgroundSize: '100% 100%'
            }">
			<div v-for="(box, index) in DSSanPham_Menu" :key="index" class="resizable-box" :style="{
                   left: box.ViTri_X * scaleFactor + 'px',
                    top: box.ViTri_Y * scaleFactor + 'px',
                    width: '95px',
                    height: '90px',
                }">
				<div class="d-flex" style="position: absolute; flex-direction: column; top: -20px; right: -25px">
					<template v-if="box.Is_HetMon === 1">
						<img src="/_cdn/zen-eorder/trang-thai-icon/ic-het-mon.png?v=1" width="50" height="50" />
					</template>
					<template v-else>
						<img v-if="box.Is_BestSeller === 1"
							src="/_cdn/zen-eorder/trang-thai-icon/ic-best-seller.png?v=1" width="45" height="40" />
						<img v-if="box.Is_Signature === 1" src="/_cdn/zen-eorder/trang-thai-icon/ic-signature.png?v=2"
							width="64.3" height="44.5" />
					</template>
				</div>
			</div>
		</div>
	</div>
</template>

<script>
	export default {
		props: ["ct_cuahang", "ds_menu"],
		data() {
			return {}
		},
		computed: {
			scaleFactor() {
				if (!this.$refs.menuDiv) return 1
				const rect = this.$refs.menuDiv.getBoundingClientRect()
				return rect.width / 1271.66 // 1271.66 là width gốc của background
			},
			CTCuaHang() {
				const $this = this
				return $this.ct_cuahang[0] ?? {}
			},
			DSSanPham_Menu() {
				const $this = this
				let menuMap = []
				if ($this.ds_menu.length > 0) {
					menuMap = $this.ds_menu.map((menu) => ({
						...menu,
						w: 80,
						h: 80,
					}))
				}
				return menuMap ?? []
			},
		},
		watch: {},
		mounted() { },
		methods: {},
	}
</script>