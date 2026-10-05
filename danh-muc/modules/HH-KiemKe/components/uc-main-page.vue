<template>
	<z-layout>
		<v-app-bar density="compact" :elevation="0" class="border-b">
			<template v-slot:prepend>
				<v-icon class="ml-2">mdi-clipboard-check-outline</v-icon>
			</template>
			<v-app-bar-title>Kiểm kê hàng hoá</v-app-bar-title>
		</v-app-bar>

		<template v-if="isReady">
			<uc-table-kiem-ke v-model:DiaDiem_Id="DiaDiem_Id" :DSPhieuKiemKe="DSPhieuKiemKe"
				:DSDiaDiem="DSDiaDiem" :DSKhuVuc="DSKhuVuc" :DSDonViTinh="DSDonViTinh"
				@onReload="loadDSPhieuKiemKe" />
		</template>
		<div v-else class="d-flex justify-center align-center" style="height: calc(100vh - 48px)">
			<v-progress-circular indeterminate color="primary" size="48" />
		</div>
	</z-layout>
</template>

<script>
export default {
	data() {
		return {
			isReady: false,
			DSPhieuKiemKe: [],
			DSDiaDiem: [],
			DSKhuVuc: [],
			DSDonViTinh: [],

			DiaDiem_Id: 0,
			filter: {
				PageIndex: 1,
				PageSize: 50,
			},
		}
	},
	mounted() {
		this.loadData()
	},
	methods: {
		async loadData() {
			this.isReady = false
			await Promise.all([
				this.loadDSPhieuKiemKe(),
				this.loadDSDiaDiem(),
				this.loadDSKhuVuc(),
				this.loadDSDonViTinh()
			])
			this.isReady = true
		},

		async loadDSPhieuKiemKe() {
			const payload = {
				PageIndex: this.filter.PageIndex,
				PageSize: this.filter.PageSize,
				DiaDiem_Id: this.DiaDiem_Id ?? 0
			}
			const data = await apiCallPromise('work/HH_PhieuKiemKe_Select', payload)
			this.DSPhieuKiemKe = data[1]
		},

		async loadDSDiaDiem() {
			const data = await apiCallPromise('work/HH_DiaDiem_Select')
			this.DSDiaDiem = Object.freeze(data)
		},

		async loadDSKhuVuc() {
			const data = await apiCallPromise('work/HH_KhuVuc_Select')
			this.DSKhuVuc = Object.freeze(data)
		},

		async loadDSDonViTinh() {
			const data = await apiCallPromise('work/HH_DonViTinh_Select')
			this.DSDonViTinh = Object.freeze(data)
		},
	},
}
</script>