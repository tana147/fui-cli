<template>
	<v-autocomplete v-model="selected" :rules="[v=> !!v || 'Vui lòng nhập dữ liệu']" :items="users" :loading="loading"
		:no-filter="true" item-title="HoTen" item-value="MaNV" return-object :multiple="multiple" chips closable-chips
		density="compact" label="Người mượn" placeholder="Nhập tên hoặc mã" :search="search" @update:search="onSearch">

		<template v-slot:chip="{ props, item }">
			<v-chip v-bind="props" :prepend-avatar="'https://file.lhbs.vn/me/avatar/' + item.raw.MaNV + '.jpg'"
				:text="item.raw.HoTen" />
		</template>


		<template #item="{ props, item }">
			<v-list-item v-bind="props" :prepend-avatar="'https://file.lhbs.vn/me/avatar/' + item.raw.MaNV + '.jpg'">
				<v-list-item-subtitle>{{ item.raw.MaNV }} - {{ item.raw.TenPhongBan }} </v-list-item-subtitle>
			</v-list-item>
		</template>
	</v-autocomplete>
</template>

<script>
	export default {
	
		props: {
			modelValue: {
				type: [Array, Object, String, Number, null],
				default: null
			},
			multiple: {
				type: Boolean,
				default: false
			}
		},
		data() {
			return {
				selected: this.multiple
					? (Array.isArray(this.modelValue) ? [...this.modelValue] : [])
					: this.modelValue ?? null,
				search: '',
				users: [],
				loading: false
			}
		},
		watch: {
			modelValue(val) {
				this.selected = this.multiple
					? (Array.isArray(val) ? [...val] : [])
					: val ?? null
			},
			selected(val) {
				this.$emit('update:modelValue', val)
				console.log(val)
			},
			search(val){
				if(val == ''){
					this.users = [];
				}
			}
		},
		
		created() {
			this.debouncedFetch = _.debounce(this.fetchUsers, 300)
		},
		methods: {
			onSearch(val) {
				this.search = val
				if (!val || val.length < 2) {
					this.users = []
					return
				}
				this.debouncedFetch(val)
			},
			async fetchUsers(query) {
				if (query < 2) {
					this.users = [];
					return;
				}
				this.loading = true
				try {
					const res = await axios.post('TS_NhanVien_Select')
					this.users = res.data?.data ?? []
				} catch (err) {
					console.error('Lỗi API:', err)
					this.users = []
				} finally {
					this.loading = false
				}
			}
		}
	}
</script>