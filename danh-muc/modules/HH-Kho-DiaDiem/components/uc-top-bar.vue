<template>
	<div>
		<v-app-bar density="compact" :elevation="0" class="border-b">
			<v-app-bar-title>Quản lý kho - địa điểm</v-app-bar-title>
			<template v-slot:append>
				<v-badge :content="YeuCauChoDuyet" :model-value="YeuCauChoDuyet > 0" color="red" location="top end"
					offset-x="4" offset-y="4">
					<v-btn color="primary" :variant="isMobile ? 'text' : 'tonal'" rounded size="small"
						prepend-icon="mdi-clipboard-check" @click="onViewDanhSachYeuCau"
						:disabled="loading || !DiaDiem_Id">
						<span v-if="!isMobile">Chờ xác nhận</span>
					</v-btn>
				</v-badge>
			</template>
		</v-app-bar>
		<div class="pa-2 border-b" :style="isMobile ? { paddingTop: '52px !important' } : {}">
			<v-row dense align="center">
				<v-col cols="10" md="3">
					<v-autocomplete v-model="DiaDiem_Id" :items="DSDiaDiem" item-value="DiaDiem_Id"
						item-title="TenDiaDiem" label="Địa điểm" density="compact" variant="outlined" hide-details
						:disabled="loading" />
				</v-col>
				<v-col cols="auto">
					<v-btn color="primary" :variant="isMobile ? 'text' : 'tonal'" prepend-icon="mdi-reload"
						density="compact" size="small" @click="emitLoadData()">
						{{ isMobile ? '' : 'Làm mới' }}
					</v-btn>
				</v-col>
			</v-row>
		</div>
	</div>
</template>

<script>
	export default {
	    props: {
	        DSDiaDiem: Array,
	        YeuCauChoDuyet: Number,
	        loading: Boolean
	    },
	    emits: ['load-data', 'on-view-cho-duyet'],
	    data() {
	        return {
	            DiaDiem_Id: null
	        }
	    },
	    computed: {
	        isMobile() {
	            return this.$vuetify.display.smAndDown
	        }
	    },
	    watch: {
	        DiaDiem_Id: function () {
	            this.emitLoadData()
	        }
	    },
	    methods: {
	        emitLoadData() {
	            this.$emit('load-data', {
	                DiaDiem_Id: this.DiaDiem_Id
	            })
	        },
	        onViewDanhSachYeuCau() {
	            this.$emit('on-view-cho-duyet')
	        }
	    }
	}
</script>