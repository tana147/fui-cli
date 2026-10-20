<template>
	<v-menu
		v-model="menuOpen"
		:close-on-content-click="false"
		transition="scale-transition"
		location="bottom start"
		offset="8"
	>
		<template #activator="{ props: menuProps }">
			<v-btn
				v-bind="menuProps"
				variant="outlined"
				color="primary"
				prepend-icon="mdi-calendar-range"
				:append-icon="menuOpen ? 'mdi-chevron-up' : 'mdi-chevron-down'"
				style="min-width:240px; font-weight:500; font-size:13px"
			>
				<template v-if="picking.from && picking.to">
					{{ formatDisplay(picking.from) }}
					<v-icon size="14" class="mx-1" color="medium-emphasis">mdi-arrow-right</v-icon>
					{{ formatDisplay(picking.to) }}
				</template>
				<template v-else>
					<span class="text-medium-emphasis">Chọn khoảng thời gian</span>
				</template>
			</v-btn>
		</template>

		<v-card rounded="xl" elevation="8" border style="overflow:hidden">
			<div class="d-flex align-center justify-space-between px-4 pt-3 pb-2 ga-3">
				<span class="text-subtitle-2 font-weight-bold">Khoảng thời gian</span>
				<div class="d-flex ga-1 flex-wrap justify-end">
					<v-chip
						v-for="shortcut in shortcuts"
						:key="shortcut.label"
						size="x-small"
						variant="tonal"
						color="primary"
						label
						class="cursor-pointer"
						@click="applyShortcut(shortcut)"
					>
						{{ shortcut.label }}
					</v-chip>
				</div>
			</div>

			<v-divider />

			<!-- Hai picker dùng chung một model from/to để không thể chọn khoảng đảo chiều. -->
			<div class="d-flex">
				<div style="flex:1">
					<div class="d-flex align-center ga-1 px-4 pt-3 pb-1">
						<v-icon size="15" color="primary">mdi-calendar-start</v-icon>
						<span class="text-caption font-weight-bold text-primary text-uppercase" style="letter-spacing:.5px">Từ ngày</span>
						<v-chip v-if="picking.from" size="x-small" color="primary" variant="tonal" label class="ml-1">
							{{ formatDisplay(picking.from) }}
						</v-chip>
					</div>
					<v-date-picker
						:model-value="isoToDate(picking.from)"
						:max="isoToDate(picking.to)"
						hide-header
						show-adjacent-months
						color="primary"
						elevation="0"
						style="border-radius:0; box-shadow:none; width:100%"
						@update:model-value="onPickFrom"
					/>
				</div>

				<v-divider vertical />

				<div style="flex:1">
					<div class="d-flex align-center ga-1 px-4 pt-3 pb-1">
						<v-icon size="15" color="success">mdi-calendar-end</v-icon>
						<span class="text-caption font-weight-bold text-success text-uppercase" style="letter-spacing:.5px">Đến ngày</span>
						<v-chip v-if="picking.to" size="x-small" color="success" variant="tonal" label class="ml-1">
							{{ formatDisplay(picking.to) }}
						</v-chip>
					</div>
					<v-date-picker
						:model-value="isoToDate(picking.to)"
						:min="isoToDate(picking.from)"
						hide-header
						show-adjacent-months
						color="success"
						elevation="0"
						style="border-radius:0; box-shadow:none; width:100%"
						@update:model-value="onPickTo"
					/>
				</div>
			</div>

			<v-divider />

			<div class="d-flex align-center px-4 py-2 ga-3">
				<div class="d-flex align-center ga-2">
					<v-chip
						size="small"
						:color="picking.from ? 'primary' : 'default'"
						:variant="picking.from ? 'tonal' : 'outlined'"
						label
						prepend-icon="mdi-calendar-start"
					>
						{{ picking.from ? formatDisplay(picking.from) : 'Từ ngày' }}
					</v-chip>
					<v-icon size="16" color="medium-emphasis">mdi-arrow-right</v-icon>
					<v-chip
						size="small"
						:color="picking.to ? 'success' : 'default'"
						:variant="picking.to ? 'tonal' : 'outlined'"
						label
						prepend-icon="mdi-calendar-end"
					>
						{{ picking.to ? formatDisplay(picking.to) : 'Đến ngày' }}
					</v-chip>
				</div>

				<v-spacer />
				<v-btn variant="text" size="small" color="error" @click="onClear">
					<v-icon start size="14">mdi-close</v-icon>Xóa
				</v-btn>
				<v-btn
					variant="tonal"
					size="small"
					color="primary"
					:disabled="!picking.from || !picking.to"
					@click="onApply"
				>
					<v-icon start size="14">mdi-check</v-icon>Áp dụng
				</v-btn>
			</div>
		</v-card>
	</v-menu>
</template>

<script>
	export default {
		name: 'UcDateRangePicker',
		props: {
			// modelValue dùng chuỗi YYYY-MM-DD để truyền thẳng sang API/SP.
			modelValue: {
				type: Object,
				default: () => ({ from: null, to: null })
			},
			NienKhoa: { default: null }
		},
		emits: ['update:modelValue'],
		data() {
			return {
				menuOpen: false,
				picking: {
					from: this.modelValue?.from ?? null,
					to: this.modelValue?.to ?? null
				},
				shortcuts: [
					{ label: 'Hôm nay', fn: () => { const t = this.today(); return { from: t, to: t } } },
					{ label: 'Tuần này', fn: () => this.currentWeek() },
					{ label: 'Tháng này', fn: () => this.currentMonth() },
					{ label: 'Tháng trước', fn: () => this.lastMonth() },
					{ label: 'Học kỳ 1', fn: () => this.hocKy(1) },
					{ label: 'Học kỳ 2', fn: () => this.hocKy(2) }
				]
			}
		},
		watch: {
			modelValue(value) {
				this.picking = { from: value?.from ?? null, to: value?.to ?? null }
			},
			menuOpen(open) {
				if (open) this.picking = { from: this.modelValue?.from ?? null, to: this.modelValue?.to ?? null }
			}
		},
		methods: {
			isoToDate(iso) {
				if (!iso) return null
				const [year, month, day] = iso.split('-').map(Number)
				return new Date(year, month - 1, day)
			},
			dateToISO(date) {
				if (!date) return null
				const year = date.getFullYear()
				const month = String(date.getMonth() + 1).padStart(2, '0')
				const day = String(date.getDate()).padStart(2, '0')
				return `${year}-${month}-${day}`
			},
			onPickFrom(dateValue) {
				const iso = this.dateToISO(dateValue)
				this.picking.from = iso
				// Nếu chọn lại ngày bắt đầu lớn hơn ngày kết thúc thì yêu cầu chọn lại ngày kết thúc.
				if (this.picking.to && iso > this.picking.to) this.picking.to = null
			},
			onPickTo(dateValue) {
				this.picking.to = this.dateToISO(dateValue)
			},
			onApply() {
				this.$emit('update:modelValue', { ...this.picking })
				this.menuOpen = false
			},
			onClear() {
				this.picking = { from: null, to: null }
				this.$emit('update:modelValue', { from: null, to: null })
				this.menuOpen = false
			},
			applyShortcut(shortcut) {
				const range = shortcut.fn()
				this.picking = range
				this.$emit('update:modelValue', { ...range })
				this.menuOpen = false
			},
			formatDisplay(iso) {
				if (!iso) return ''
				const [year, month, day] = iso.split('-')
				return `${day}/${month}/${year}`
			},
			today() {
				return this.dateToISO(new Date())
			},
			currentWeek() {
				const now = new Date()
				const day = now.getDay() || 7
				const from = new Date(now); from.setDate(now.getDate() - day + 1)
				const to = new Date(now); to.setDate(now.getDate() - day + 7)
				return { from: this.dateToISO(from), to: this.dateToISO(to) }
			},
			currentMonth() {
				const now = new Date()
				return {
					from: this.dateToISO(new Date(now.getFullYear(), now.getMonth(), 1)),
					to: this.dateToISO(new Date(now.getFullYear(), now.getMonth() + 1, 0))
				}
			},
			lastMonth() {
				const now = new Date()
				return {
					from: this.dateToISO(new Date(now.getFullYear(), now.getMonth() - 1, 1)),
					to: this.dateToISO(new Date(now.getFullYear(), now.getMonth(), 0))
				}
			},
			hocKy(semester) {
				const now = new Date()
				const currentYear = now.getFullYear()
				const month = now.getMonth() + 1
				const schoolYear = Number(this.NienKhoa) || (month >= 8 ? currentYear : currentYear - 1)
				return semester === 1
					? { from: `${schoolYear}-08-01`, to: `${schoolYear}-12-31` }
					: { from: `${schoolYear + 1}-01-01`, to: `${schoolYear + 1}-05-31` }
			}
		}
	}
</script>