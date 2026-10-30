<template>
	<v-card>
		<v-card-title class="text-primary d-flex">
			Báo cáo chi tiết
			<v-chip v-if="BaoCaoSelected" class="ml-2" size="small">{{BaoCaoSelected?.TenBaoCao}}</v-chip>
			<v-spacer />
			<!-- Mỗi niên khóa cần bộ chi tiết riêng; thao tác này giữ nguyên các dòng lịch sử và dữ liệu đã chốt. -->
			<v-btn v-if="IsActionPermission && BaoCaoSelected && hasMissingCurrentYearRows" size="small" variant="outlined"
				:loading="isGeneratingRows" :disabled="isGeneratingRows" @click="ensureCurrentYearRows(true)">
				Tạo {{vueData.NienKhoa}}-{{Number(vueData.NienKhoa) + 1}}
			</v-btn>
			<!-- Dòng các niên khóa cũ được ẩn mặc định để bảng tập trung vào năm hiện tại, nhưng vẫn có thể mở khi cần tra cứu. -->
			<v-btn v-if="historicalBaoCaoChiTiets.length" size="small" variant="text"
				@click="showHistoricalRows = !showHistoricalRows">
				{{showHistoricalRows ? 'Ẩn lịch sử' : 'Xem lịch sử (' + historicalBaoCaoChiTiets.length + ')'}}
			</v-btn>
			<v-btn v-if="IsActionPermission" size="small" icon="mdi-plus" :disabled="isGeneratingRows" @click="onOpenDialog" />
		</v-card-title>
	</v-card>
	<!-- Chỉ hiện niên khóa hiện tại lúc đầu; các dòng cũ chỉ thêm vào bảng sau khi người dùng mở lịch sử. -->
	<v-data-table :headers="headerBaoCaoChiTiets" :items="visibleBaoCaoChiTiets" hide-default-footer :items-per-page="-1">
		<template #item.NienKhoa="{item}">
			<v-chip size="small" class="text-primary">{{renderNienKhoa(item.NienKhoa)}}</v-chip>
		</template>
		<template #item.NgayNguoiChot="{item}">
			<p v-if="item.NguoiChot" class="text-caption text-italic">Người chốt: {{item.NguoiChot}}</p>
			<p v-if="item.NgayChot" class="text-caption text-italic">Thời gian chốt: {{item.NgayChot}}</p>
		</template>
		<template #item.HocKi="{item}">
			<v-chip size="small" class="text-primary">{{renderHocKi(item)}}</v-chip>
		</template>
		<!-- URL cũ có thể chưa lưu niên khóa; hiển thị URL đã gắn niên khóa của chính dòng báo cáo. -->
		<template #item.Url_BaoCao="{item}">
			{{getUrlForRow(item)}}
		</template>
		<template #item.JSON_BaoCao="{item}">
			<v-chip color="blue" size="small" @click="onCopy(item)">
				<v-icon start>mdi-content-copy</v-icon>JSON
			</v-chip>
		</template>
		<template #item.actions="{item}">
			<v-menu>
				<template v-slot:activator="{ props }">
					<v-btn v-bind="props" color="primary" size="small" variant="text" icon="mdi-menu" />
				</template>
				<v-list>
					<v-list-item title="Xem" prepend-icon="mdi-eye-outline" @click="onRedirectPage(item)"></v-list-item>
					<v-list-item v-if="IsActionPermission" title="Cập nhật" prepend-icon="mdi-pencil-outline"
						@click="onOpenDialogUpdate(item)"></v-list-item>
					<v-list-item v-if="IsActionPermission" class="text-red" prepend-icon="mdi-trash-can-outline"
						title="Xóa" @click="onDelete(item)"></v-list-item>
				</v-list>
			</v-menu>
		</template>
	</v-data-table>

	<v-dialog v-model="isShowDialogAdd" max-width="500">
		<v-card title="Thêm mới chi tiết">
			<v-card-text>
				<v-form ref="formAdd">
					<v-row>
						<v-col cols="12">
							<v-text-field v-model="formAdd.TenBaoCao_ChiTiet" label="Tên báo cáo (Tùy chọn)" />
						</v-col>
						<v-col cols="12">
							<v-select v-model="formAdd.HocKi" label="Chọn học kì" :items="DSHocKi" item-title="title"
								item-value="textValue" :rules="rules" />
						</v-col>
						<v-col cols="12">
							<v-textarea v-model="formAdd.Url_BaoCao" label="Link" :rules="rules" />
						</v-col>
						<v-col cols="12">
							<v-textarea v-model="formAdd.JSON_BaoCao" label="JSON" />
						</v-col>
					</v-row>
				</v-form>
			</v-card-text>
			<v-card-actions>
				<v-spacer />
				<v-btn text="Đóng" @click="isShowDialogAdd = false" />
				<v-btn text="Thêm mới" color="elevated" @click="onAdd" />
			</v-card-actions>
		</v-card>
	</v-dialog>

	<v-dialog v-model="isShowDialogEdit" max-width="500">
		<v-card title="Sửa chi tiết">
			<v-card-text>
				<v-form ref="formEdit">
					<v-row>
						<v-col cols="12">
							<v-text-field v-model="formEdit.TenBaoCao_ChiTiet" label="Tên báo cáo (Tùy chọn)" />
						</v-col>
						<v-col cols="12">
							<v-select v-model="formEdit.HocKi" label="Chọn học kì" :items="DSHocKi" item-title="title"
								item-value="textValue" :rules="rules" />
						</v-col>
						<v-col cols="12">
							<v-textarea v-model="formEdit.Url_BaoCao" label="Link" :rules="rules" />
						</v-col>
						<v-col cols="12">
							<v-textarea v-model="formEdit.JSON_BaoCao" label="JSON" />
						</v-col>
					</v-row>
				</v-form>
			</v-card-text>
			<v-card-actions>
				<v-spacer />
				<v-btn text="Đóng" @click="isShowDialogEdit = false" />
				<v-btn text="Cập nhật" color="elevated" @click="onEdit" />
			</v-card-actions>
		</v-card>
	</v-dialog>

	<v-dialog v-model="isShowDialogNienKhoa" max-width="420">
		<v-card title="Chọn niên khóa">
			<v-card-text>
				<v-select v-model="NienKhoaSelected" label="Niên khóa" :items="DSNienKhoa" item-title="label"
					item-value="NienKhoa" return-object />
			</v-card-text>
			<v-card-actions>
				<v-spacer />
				<v-btn text="Đóng" @click="isShowDialogNienKhoa = false" />
				<v-btn text="Xem báo cáo" color="primary" variant="elevated" @click="onOpenReportWithNienKhoa" />
			</v-card-actions>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
		inject: ['iframeRef'],
		props: {
			CapID: Number,
			BaoCaoSelected: Object,
			headerBaoCaoChiTiets: Array,
			itemBaoCaoChiTiets: Array,
			onAddFinnish: Function,
			onEditFinnish: Function,
			onDeleteFinnish: Function,
			IsActionPermission: Boolean
		},
		emits: [
			"onAddFinnish",
			"onEditFinnish",
			"onDeleteFinnish"
		],
		data() {
			return {
				vueData,
				itemMonHocs: [],
				isShowDialogAdd: false,
				isShowDialogEdit: false,
				formAdd: {
					HocKi: null,
					Url_BaoCao: null,
					JSON_BaoCao: null,
					TenBaoCao_ChiTiet: null
				},
				formEdit: {
					HocKi: null,
					Url_BaoCao: null,
					JSON_BaoCao: null,
					TenBaoCao_ChiTiet: null
				},
				rules: [
					value => {
						if (value) return true
						return 'Bạn chưa nhập trường dữ liệu này.'
					}
				],
				DSHocKi: [],
				isShowDialogNienKhoa: false,
				DSNienKhoa: [],
				NienKhoaSelected: null,
				UrlBaoCaoDangMo: '',
				isGeneratingRows: false,
				pendingBaoCaoID: null,
				showHistoricalRows: false
			}
		},
		computed: {
			// Nút tạo chỉ hiện khi danh sách chưa có đủ các học kì của niên khóa đang dùng.
			hasMissingCurrentYearRows() {
				const nienKhoa = Number(this.vueData.NienKhoa)
				return Number.isInteger(nienKhoa) && this.getRowsToGenerate(this.itemBaoCaoChiTiets, nienKhoa).length > 0
			},
			// Tách năm hiện tại khỏi lịch sử để chế độ mặc định không trộn các báo cáo cũ vào bảng.
			historicalBaoCaoChiTiets() {
				const nienKhoa = Number(this.vueData.NienKhoa)
				return (this.itemBaoCaoChiTiets || []).filter(item => Number(item.NienKhoa) !== nienKhoa)
			},
			visibleBaoCaoChiTiets() {
				const rows = this.itemBaoCaoChiTiets || []
				// API trả theo thứ tự ID; sắp kỳ điểm theo trình tự học vụ trước rồi mới đến các kiểu kỳ khác.
				const periodOrder = ["GK_HK1", "CK_HK1", "GK_HK2", "CK_HK2", "HK1", "HK2", "CaNam"]
				const sortRows = source => [...source].sort((a, b) => {
					const yearDifference = Number(b.NienKhoa || 0) - Number(a.NienKhoa || 0)
					if (yearDifference) return yearDifference
					const periodIndex = value => {
						const index = periodOrder.indexOf(value)
						return index < 0 ? periodOrder.length : index
					}
					return periodIndex(a.HocKi) - periodIndex(b.HocKi)
						|| Number(a.BaoCao_ChiTietID || 0) - Number(b.BaoCao_ChiTietID || 0)
				})
				if (this.showHistoricalRows) {
					const nienKhoa = Number(this.vueData.NienKhoa)
					const currentRows = rows.filter(item => Number(item.NienKhoa) === nienKhoa)
					const historicalRows = rows.filter(item => Number(item.NienKhoa) !== nienKhoa)
					return sortRows(currentRows).concat(sortRows(historicalRows))
				}
				return sortRows(rows.filter(item => Number(item.NienKhoa) === Number(this.vueData.NienKhoa)))
			}
		},
		watch: {
			"BaoCaoSelected.BaoCaoID": function (bc) {
				this.showHistoricalRows = false
				this.onLoadHK()
				// Mỗi báo cáo được kiểm tra và tạo các học kì còn thiếu ngay khi chọn, để năm mới không chỉ hiện qua một nút thủ công.
				if (bc) this.ensureCurrentYearRows()
			}
		},
		methods: {
			onOpenDialog() {
				this.isShowDialogAdd = true
			},
			// Lấy các học kì từ niên khóa gần nhất; JSON và thông tin chốt không được sao chép sang năm mới.
			getRowsToGenerate(rows, nienKhoa) {
				const priorYears = (rows || []).map(item => Number(item.NienKhoa))
					.filter(year => Number.isInteger(year) && year < nienKhoa)
				if (!priorYears.length) return []

				const templateYear = Math.max(...priorYears)
				const templatesByHocKi = {}
				;(rows || []).forEach(item => {
					if (Number(item.NienKhoa) === templateYear && item.HocKi && !templatesByHocKi[item.HocKi]) {
						templatesByHocKi[item.HocKi] = item
					}
				})

				const existingHocKi = new Set((rows || [])
					.filter(item => Number(item.NienKhoa) === nienKhoa)
					.map(item => item.HocKi))
				return Object.keys(templatesByHocKi)
					.filter(hocKi => !existingHocKi.has(hocKi))
					.map(hocKi => templatesByHocKi[hocKi])
			},
			async ensureCurrentYearRows(isManualRetry) {
				const nienKhoa = Number(this.vueData.NienKhoa)
				const baoCaoID = this.BaoCaoSelected?.BaoCaoID
				if (!baoCaoID || !this.IsActionPermission) return

				// Nếu người dùng đổi báo cáo giữa lúc đang tạo, xếp lượt kiểm tra mới để báo cáo vừa chọn cũng được khởi tạo.
				if (this.isGeneratingRows) {
					this.pendingBaoCaoID = baoCaoID
					return
				}

				if (!Number.isInteger(nienKhoa) || nienKhoa <= 0) {
					if (isManualRetry) Vue.$toast.error('Không xác định được niên khóa hiện tại', { position: 'top' })
					return
				}

				this.isGeneratingRows = true
				try {
					// Đọc lại từ server trước khi ghi để lần tạo tự động có thể chạy lặp mà không nhân đôi học kì.
					const latestRows = await ajaxCALLPromise('lms/BaoCao_TongHop_Get_ByBaoCaoID', { BaoCaoID: baoCaoID })
					const latestRowsToGenerate = this.getRowsToGenerate(latestRows, nienKhoa)
					if (!latestRowsToGenerate.length) {
						if (isManualRetry) showMessage({ title: 'Thông báo', message: 'Các học kì của niên khóa này đã được tạo.' })
						return
					}

					// Chỉ sao chép mẫu học kì từ năm trước; JSON và thông tin chốt luôn để trống cho năm mới.
					for (const template of latestRowsToGenerate) {
						await ajaxCALLPromise('lms/BaoCao_TongHop_Ins_ByBaoCaoID', {
							BaoCaoID: baoCaoID,
							HocKi: template.HocKi,
							Url_BaoCao: this.buildUrlWithNienKhoa(template.Url_BaoCao, nienKhoa),
							JSON_BaoCao: null,
							TenBaoCao_ChiTiet: template.TenBaoCao_ChiTiet || '',
							NienKhoa: nienKhoa
						})
					}

					this.$emit('onAddFinnish')
					Vue.$toast.success('Đã tạo ' + latestRowsToGenerate.length + ' dòng cho niên khóa ' + nienKhoa + '-' + (nienKhoa + 1), { position: 'top' })
				} catch (error) {
					this.$emit('onAddFinnish')
					Vue.$toast.error('Không tạo hết được chi tiết báo cáo. Tải lại danh sách rồi thử lại để chỉ tạo phần còn thiếu.', { position: 'top' })
				} finally {
					this.isGeneratingRows = false
					const pendingBaoCaoID = this.pendingBaoCaoID
					this.pendingBaoCaoID = null
					if (pendingBaoCaoID && pendingBaoCaoID !== baoCaoID && this.BaoCaoSelected?.BaoCaoID === pendingBaoCaoID) {
						this.$nextTick(() => this.ensureCurrentYearRows())
					}
				}
			},
			onLoadHK() {
				let DSHocKi = []
				const hk_c1 = [
					{ title: "Giữa HK1", value: 1, textValue: "GK_HK1" },
					{ title: "Cuối HK1", value: 2, textValue: "CK_HK1" },
					{ title: "Giữa HK2", value: 3, textValue: "GK_HK2" },
					{ title: "Cuối HK2", value: 4, textValue: "CK_HK2" }
				]
				const hk_c2_c3 = [
					{ title: "Học kì 1", value: 1, textValue: "HK1" },
					{ title: "Học kì 2", value: 2, textValue: "HK2" },
				]
				const hk_ca_nam = [
					{ title: "Cả năm", value: 0, textValue: "CaNam" }
				]
				this.DSHocKi = [...hk_c1, ...hk_c2_c3, ...hk_ca_nam]
			},
			onAdd() {
				const form = this.$refs.formAdd
				if (form.validate()) {
					ajaxCALLPromise("lms/BaoCao_TongHop_Ins_ByBaoCaoID", {
						BaoCaoID: this.BaoCaoSelected.BaoCaoID,
						HocKi: this.formAdd.HocKi,
						Url_BaoCao: this.formAdd.Url_BaoCao,
						JSON_BaoCao: this.formAdd.JSON_BaoCao,
						TenBaoCao_ChiTiet: this.formAdd.TenBaoCao_ChiTiet,
						NienKhoa: vueData.NienKhoa
					}).then(() => {
						this.$emit("onAddFinnish")
						form.reset()
						this.isShowDialogAdd = false
					})
				}
			},
			onEdit() {
				const form = this.$refs.formEdit
				if (form.validate()) {
					ajaxCALLPromise("lms/BaoCao_TongHop_Upd_ByBaoCao_ChiTietID", {
						BaoCao_ChiTietID: this.formEdit.BaoCao_ChiTietID,
						HocKi: this.formEdit.HocKi,
						Url_BaoCao: this.formEdit.Url_BaoCao,
						JSON_BaoCao: this.formEdit.JSON_BaoCao,
						TenBaoCao_ChiTiet: this.formEdit.TenBaoCao_ChiTiet,
					}).then(() => {
						this.$emit("onEditFinnish")
						form.reset()
						this.isShowDialogEdit = false
					})
				}
			},
			renderHocKi(bc) {
				const hk = this.DSHocKi.find(x => x.textValue == bc.HocKi)
				return hk?.title ?? ''
			},
			renderNienKhoa(nienKhoa) {
				if (nienKhoa == null || nienKhoa === '') return ''
				const year = Number(nienKhoa)
				return Number.isInteger(year) ? year + ' - ' + (year + 1) : ''
			},
			onCopy(bc) {
				navigator.clipboard.writeText(bc.JSON_BaoCao)
				Vue.$toast.success("Sao chép JSON thành công", { position: "top" })
			},
			onRedirectPage(bc) {
				if (this.isThongKeChatLuongBoMonUrl(bc?.Url_BaoCao)) {
					const urlNienKhoa = this.getNienKhoaFromUrl(bc?.Url_BaoCao)
					if (urlNienKhoa) {
						// URL đã chốt niên khóa nên mở thẳng, tránh hỏi lại đúng giá trị đang có trong link.
						this.openByIframeRef(this.buildUrlWithNienKhoa(bc?.Url_BaoCao, urlNienKhoa))
						return
					}
					this.onOpenDialogNienKhoa(bc?.Url_BaoCao, this.getTargetNienKhoa(bc))
					return
				}
				const finalUrl = this.buildUrlWithNienKhoa(bc?.Url_BaoCao, this.getTargetNienKhoa(bc))
				this.openByIframeRef(finalUrl)
			},
			getNienKhoaFromUrl(url) {
				if (!url) return null

				try {
					const value = new URL(url, window.location.origin).searchParams.get('nienkhoa')
					const year = Number(value)
					return Number.isInteger(year) && year > 0 ? year : null
				} catch {
					const match = String(url).match(/(?:[?&])nienkhoa=(\d+)(?:[&#]|$)/i)
					return match ? Number(match[1]) : null
				}
			},
			getTargetNienKhoa(bc) {
				const rowNienKhoa = Number(bc?.NienKhoa)
				return Number.isInteger(rowNienKhoa) && rowNienKhoa > 0
					? rowNienKhoa
					: Number(vueData.NienKhoa)
			},
			getUrlForRow(bc) {
				return this.buildUrlWithNienKhoa(bc?.Url_BaoCao, this.getTargetNienKhoa(bc))
			},
			isThongKeChatLuongBoMonUrl(url) {
				return String(url || '').toLowerCase().includes('thong-ke-chat-luong-bo-mon')
			},
			onOpenDialogNienKhoa(url, preferredNienKhoa) {
				this.UrlBaoCaoDangMo = url || ''
				this.NienKhoaSelected = null
				this.onLoadNienKhoa(preferredNienKhoa).then(() => {
					this.isShowDialogNienKhoa = true
				})
			},
			onLoadNienKhoa(preferredNienKhoa) {
				if (this.DSNienKhoa.length) {
					this.setDefaultNienKhoa(preferredNienKhoa)
					return Promise.resolve()
				}

				return fetchPromise('lms/NienKhoa_Get', {}).then(res => {
					const unique = [...new Map((res ?? []).map(item => [item.NienKhoa, item])).values()]
					this.DSNienKhoa = unique.map(item => ({
						...item,
						label: item.NienKhoa + ' - ' + (Number(item.NienKhoa) + 1)
					}))
					this.setDefaultNienKhoa(preferredNienKhoa)
				})
			},
			setDefaultNienKhoa(preferredNienKhoa) {
				const preferred = Number(preferredNienKhoa)
				const preferredItem = Number.isInteger(preferred)
					? this.DSNienKhoa.find(item => Number(item.NienKhoa) === preferred)
					: null
				if (preferredItem) {
					this.NienKhoaSelected = preferredItem
					return
				}
				if (this.NienKhoaSelected) return

				const nienKhoaHienTai = Number(vueData.NienKhoa)
				this.NienKhoaSelected =
					this.DSNienKhoa.find(item => Number(item.NienKhoa) === nienKhoaHienTai) ??
					this.DSNienKhoa.find(item => item.IsActive) ??
					this.DSNienKhoa[0] ??
					null
			},
			onOpenReportWithNienKhoa() {
				if (!this.NienKhoaSelected) return

				const finalUrl = this.buildUrlWithNienKhoa(this.UrlBaoCaoDangMo, this.NienKhoaSelected.NienKhoa)
				this.isShowDialogNienKhoa = false
				this.openByIframeRef(finalUrl)
			},
			openByIframeRef(url) {
				const payload = {
					title: "Báo cáo chi tiết",
					url
				}

				if (this.iframeRef?.value?.openWindow) {
					this.iframeRef.value.openWindow(payload)
					return
				}

				if (window?.parent) {
					window.parent.postMessage({ type: 'iframeRef_openWindow', ...payload }, '*')
					return
				}

				openWindow(payload)
			},
			buildUrlWithNienKhoa(url, nienKhoa) {
				if (!url) return url

				try {
					const parsed = new URL(url, window.location.origin)
					parsed.searchParams.set('nienkhoa', nienKhoa)
					// Đồng bộ tham số nk cũ để một đường dẫn không trỏ tới hai niên khóa khác nhau.
					if (parsed.searchParams.has('nk')) parsed.searchParams.set('nk', nienKhoa)
					return parsed.pathname + parsed.search + parsed.hash
				} catch {
					const splitChar = url.includes('?') ? '&' : '?'
					return url + splitChar + 'nienkhoa=' + encodeURIComponent(nienKhoa)
				}
			},
			onOpenDialogUpdate(bc) {
				this.formEdit = Object.assign({}, bc)
				// this.formEdit.HocKi = parseInt(this.formEdit.HocKi)
				this.isShowDialogEdit = true
			},
			onDelete(bc) {
				const $this = this
				confirm({
					title: "Xác nhận báo cáo",
					action: function () {
						ajaxCALLPromise("lms/BaoCao_TongHop_Del_ByBaoCao_ChiTietID", {
							BaoCao_ChiTietID: bc.BaoCao_ChiTietID
						}).then(() => {
							$this.$emit("onDeleteFinnish")
							Vue.$toast.success("Xóa báo cáo chi tiết thành công", { position: "top" })
						})
					}
				})
			}
		},
	}
</script>