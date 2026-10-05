<template>
	<div ref="tabulator" :style="{ height: height }"></div>
</template>

<script>
	export default {
		props: {
			items: {
				type: [Array, null],
				required: true,
				default: () => [],
			},
			headers: {
				type: [Array, null],
				required: true,
				default: () => [],
			},
			height: {
				type: String,
				default: "500px",
			},
			options: {
				type: Object,
				default: () => ({}),
			},
		},
		data() {
			return {
				table: null,
			}
		},
		mounted() {
			const $this = this
			$this.initTable()
		},
		watch: {},
		beforeUnmount() {
			this.table && this.table.destroy()
		},
		methods: {
			initTable() {
				//Tabulator 6.3: https://tabulator.info/docs/6.3
				const $this = this
				$this.table = new Tabulator($this.$refs.tabulator, {
					history: true,
					data: $this.items,
					columns: $this.headers,
					layout: "fitColumns",
					placeholder: "Không tìm thấy dữ liệu",
					headerSortElement: function (column, dir) {
						switch (dir) {
							case "asc":
								return "<i class='mdi mdi-sort-ascending'>"
							case "desc":
								return "<i class='mdi mdi-sort-descending'>"
							default:
								return "<i class='mdi mdi-sort'>"
						}
					},
					paginationSize: 100,
					//paginationSizeSelector: [50, 100, 200, 400],
					paginationCounter: "rows",
					locale: "vi",
					langs: {
						"vi": {
							"pagination": {
								"first": '<i class="mdi mdi-page-first"></i>',
								"first_title": "Trang đầu",
								"last": '<i class="mdi mdi-page-last"></i>',
								"last_title": "Trang cuối",
								"prev": '<i class="mdi mdi-chevron-left"></i>',
								"prev_title": "Trang trước",
								"next": '<i class="mdi mdi-chevron-right"></i>',
								"next_title": "Trang sau",
								"page_size": "Bản ghi",
								"counter": {
									"showing": "",
									"of": "trong",
									"rows": "",
									"pages": "trang"
								}
							}
						}
					},
					...$this.options,
				})
	
				//Event click row
				$this.table.on("rowClick", function (e, row) {
					$this.$emit("onRowClick", row.getData())
				})
	
				//Event edit cell
				$this.table.on("cellEdited", function (cell) {
					$this.$emit("onEdit", cell.getRow().getData())
				})
	
				//Event build table
				$this.table.on("tableBuilt", function (e, row) {
					$this.setupNavigation()
				})
	
				//Event move row
				$this.table.on("rowMoved", function (row) {
					$this.$emit("onMove", row)
				});
			},
			setupNavigation() {
				const $this = this
				const tableElem = $this.$refs.tabulator
				tableElem.addEventListener(
					"keydown",
					(e) => {
						const key = e.key
						const isNavigationKey = ["ArrowUp", "ArrowDown", "ArrowLeft", "ArrowRight", "Enter", "Tab"].includes(key)
						if (isNavigationKey) {
							const activeElement = document.activeElement
							const isInput = ["INPUT", "TEXTAREA", "SELECT"].includes(activeElement.tagName)
							if (isInput) {
								e.stopImmediatePropagation()
								if (key === "Enter" || key === "Tab") {
									e.preventDefault()
								}
								switch (key) {
									case "ArrowUp":
										$this.table.navigateUp()
										break
									case "ArrowDown":
									case "Enter":
										$this.table.navigateDown()
										break
									case "ArrowLeft":
										$this.table.navigateLeft()
										break
									case "ArrowRight":
									case "Tab":
										$this.table.navigateRight()
										break
								}
							}
						}
					},
					true,
				)
			},
			exportExcel(fileName) {
				this.table.download("xlsx", `${fileName}.xlsx`)
			},
		},
	}
</script>